import 'dart:async';

import 'package:byepo_stock_market/core/bridge/bridge_event.dart';
import 'package:byepo_stock_market/core/bridge/bridge_log_entry.dart';
import 'package:byepo_stock_market/core/bridge/bridge_service.dart';
import 'package:byepo_stock_market/core/connectivity/connectivity_service.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockInAppWebViewController extends Mock implements InAppWebViewController {}

void main() {
  late MockConnectivityService connectivityService;
  late StreamController<bool> statusController;
  late SharedPreferences prefs;
  late BridgeService service;

  setUp(() async {
    connectivityService = MockConnectivityService();
    statusController = StreamController<bool>.broadcast();
    when(() => connectivityService.onStatusChanged)
        .thenAnswer((_) => statusController.stream);
    when(() => connectivityService.isOnline).thenReturn(true);

    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();

    service = BridgeService(connectivityService: connectivityService, prefs: prefs);
    await service.initialize();
  });

  tearDown(() async {
    service.dispose();
    await statusController.close();
  });

  test('sendEvent queues and persists before a controller is attached', () async {
    final entries = <BridgeLogEntry>[];
    service.logStream.listen(entries.add);

    final event = BridgeEvent.outbound(eventType: BridgeEventType.orderUpdate);
    await service.sendEvent(event);
    await Future<void>.delayed(Duration.zero);

    expect(entries, hasLength(1));
    expect(entries.single.status, BridgeDeliveryStatus.queued);

    final persisted = prefs.getString('bridge_outbound_queue_v1');
    expect(persisted, contains(event.eventId));
  });

  test('initialize() reloads a persisted queue from a previous run', () async {
    // Seed `prefs` via a first service instance's own persistence (round-
    // tripping through the real serializer, rather than hand-encoding
    // JSON here), then simulate the app restarting with a second instance
    // reading that same storage.
    final event = BridgeEvent.outbound(eventType: BridgeEventType.orderUpdate);
    final seeding = BridgeService(connectivityService: connectivityService, prefs: prefs);
    await seeding.sendEvent(event);
    seeding.dispose();

    final reloaded = BridgeService(connectivityService: connectivityService, prefs: prefs);
    await reloaded.initialize();

    final entries = <BridgeLogEntry>[];
    reloaded.logStream.listen(entries.add);
    final controller = MockInAppWebViewController();
    when(() => controller.addJavaScriptHandler(
          handlerName: any(named: 'handlerName'),
          callback: any(named: 'callback'),
        )).thenReturn(null);
    when(() => controller.evaluateJavascript(source: any(named: 'source')))
        .thenAnswer((_) async => null);
    reloaded.attachController(controller);
    await reloaded.debugSimulateInboundRaw(
      BridgeEvent.outbound(eventType: BridgeEventType.bridgeReady, ackRequired: false).toJson(),
    );
    await Future<void>.delayed(Duration.zero);

    verify(() => controller.evaluateJavascript(
          source: any(named: 'source', that: contains(event.eventId)),
        )).called(1);

    reloaded.dispose();
  });

  test('malformed inbound payload is logged, not thrown', () async {
    final entries = <BridgeLogEntry>[];
    service.logStream.listen(entries.add);

    await service.debugSimulateInboundRaw({'oops': 'no eventId'});
    await Future<void>.delayed(Duration.zero);

    expect(entries, hasLength(1));
    expect(entries.single.status, BridgeDeliveryStatus.malformed);
  });

  test('debugSimulateInboundRaw with a non-Map payload logs malformed', () async {
    final entries = <BridgeLogEntry>[];
    service.logStream.listen(entries.add);

    await service.debugSimulateInboundRaw('just a string');
    await Future<void>.delayed(Duration.zero);

    expect(entries.single.status, BridgeDeliveryStatus.malformed);
  });

  test('a valid inbound event is received and emitted once', () async {
    final logEntries = <BridgeLogEntry>[];
    final inbound = <BridgeEvent>[];
    service.logStream.listen(logEntries.add);
    service.inboundEvents.listen(inbound.add);

    final event = BridgeEvent(
      eventId: 'EVT-web-1',
      eventType: BridgeEventType.userAction,
      timestamp: DateTime.now().toUtc(),
      source: BridgeSource.web,
      ackRequired: false,
    );
    await service.debugSimulateInboundRaw(event.toJson());
    await Future<void>.delayed(Duration.zero);

    expect(logEntries.single.status, BridgeDeliveryStatus.received);
    expect(inbound.single.eventId, 'EVT-web-1');
  });

  test('a repeated inbound eventId is flagged as duplicate and not re-emitted', () async {
    final logEntries = <BridgeLogEntry>[];
    final inbound = <BridgeEvent>[];
    service.logStream.listen(logEntries.add);
    service.inboundEvents.listen(inbound.add);

    final event = BridgeEvent(
      eventId: 'EVT-web-dup',
      eventType: BridgeEventType.userAction,
      timestamp: DateTime.now().toUtc(),
      source: BridgeSource.web,
      ackRequired: false,
    );
    await service.debugSimulateInboundRaw(event.toJson());
    await service.debugSimulateInboundRaw(event.toJson());
    await Future<void>.delayed(Duration.zero);

    expect(logEntries.map((e) => e.status),
        [BridgeDeliveryStatus.received, BridgeDeliveryStatus.duplicate]);
    expect(inbound, hasLength(1));
  });

  test('BRIDGE_READY marks the service ready and flushes the queue', () async {
    final controller = MockInAppWebViewController();
    when(() => controller.addJavaScriptHandler(
          handlerName: any(named: 'handlerName'),
          callback: any(named: 'callback'),
        )).thenReturn(null);
    when(() => controller.evaluateJavascript(source: any(named: 'source')))
        .thenAnswer((_) async => null);
    service.attachController(controller);

    final readyStates = <bool>[];
    service.readyStream.listen(readyStates.add);

    final event =
        BridgeEvent.outbound(eventType: BridgeEventType.orderUpdate, ackRequired: false);
    await service.sendEvent(event);
    expect(service.isReady, isFalse);
    verifyNever(() => controller.evaluateJavascript(source: any(named: 'source')));

    await service.debugSimulateInboundRaw(
      BridgeEvent.outbound(eventType: BridgeEventType.bridgeReady, ackRequired: false).toJson(),
    );
    await Future<void>.delayed(Duration.zero);

    expect(service.isReady, isTrue);
    expect(readyStates, contains(true));
    verify(() => controller.evaluateJavascript(
          source: any(named: 'source', that: contains(event.eventId)),
        )).called(1);
  });

  test('an ACK correlates back to the original outbound entry with latency', () async {
    final controller = MockInAppWebViewController();
    when(() => controller.addJavaScriptHandler(
          handlerName: any(named: 'handlerName'),
          callback: any(named: 'callback'),
        )).thenReturn(null);
    when(() => controller.evaluateJavascript(source: any(named: 'source')))
        .thenAnswer((_) async => null);
    service.attachController(controller);

    await service.debugSimulateInboundRaw(
      BridgeEvent.outbound(eventType: BridgeEventType.bridgeReady, ackRequired: false).toJson(),
    );
    await Future<void>.delayed(Duration.zero);

    final entries = <BridgeLogEntry>[];
    service.logStream.listen(entries.add);

    final event = BridgeEvent.outbound(eventType: BridgeEventType.orderUpdate);
    await service.sendEvent(event);
    await Future<void>.delayed(Duration.zero);

    expect(entries.last.status, BridgeDeliveryStatus.awaitingAck);

    await service.debugSimulateInboundRaw(
      BridgeEvent.outbound(
        eventType: BridgeEventType.ack,
        payload: {'ackForEventId': event.eventId},
        ackRequired: false,
      ).toJson(),
    );
    await Future<void>.delayed(Duration.zero);

    expect(entries.last.id, event.eventId);
    expect(entries.last.status, BridgeDeliveryStatus.acked);
    expect(entries.last.latencyMs, isNotNull);
  });
}
