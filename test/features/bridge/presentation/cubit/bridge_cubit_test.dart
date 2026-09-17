import 'dart:async';

import 'package:byepo_stock_market/core/bridge/bridge_event.dart';
import 'package:byepo_stock_market/core/bridge/bridge_log_entry.dart';
import 'package:byepo_stock_market/core/bridge/bridge_service.dart';
import 'package:byepo_stock_market/core/connectivity/connectivity_service.dart';
import 'package:byepo_stock_market/features/bridge/presentation/cubit/bridge_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockBridgeService extends Mock implements BridgeService {}

class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  late MockBridgeService bridgeService;
  late MockConnectivityService connectivityService;
  late StreamController<BridgeLogEntry> logController;
  late BridgeCubit cubit;

  setUpAll(() {
    registerFallbackValue(BridgeEvent.outbound(eventType: BridgeEventType.orderUpdate));
  });

  setUp(() {
    bridgeService = MockBridgeService();
    connectivityService = MockConnectivityService();
    logController = StreamController<BridgeLogEntry>.broadcast();
    when(() => bridgeService.logStream).thenAnswer((_) => logController.stream);
    when(() => bridgeService.sendEvent(any())).thenAnswer((_) async {});
    when(() => bridgeService.debugSimulateInboundRaw(any())).thenAnswer((_) async {});

    cubit = BridgeCubit(bridgeService: bridgeService, connectivityService: connectivityService);
  });

  tearDown(() async {
    await cubit.close();
    await logController.close();
  });

  test('sendOrderUpdateDemo sends the exact ORD1001 example', () async {
    await cubit.sendOrderUpdateDemo();

    final sent = verify(() => bridgeService.sendEvent(captureAny())).captured.single
        as BridgeEvent;
    expect(sent.eventType, BridgeEventType.orderUpdate);
    expect(sent.payload, {
      'orderId': 'ORD1001',
      'status': 'COMPLETED',
      'price': 1250.50,
    });
  });

  test('sendRapidFire sends `count` distinct events', () async {
    await cubit.sendRapidFire(count: 3);

    final sent = verify(() => bridgeService.sendEvent(captureAny())).captured;
    expect(sent, hasLength(3));
    expect(sent.map((e) => (e as BridgeEvent).eventId).toSet(), hasLength(3));
  });

  test('resendLastEvent re-sends the exact same event (same eventId)', () async {
    await cubit.sendOrderUpdateDemo();
    final first = verify(() => bridgeService.sendEvent(captureAny())).captured.single
        as BridgeEvent;

    await cubit.resendLastEvent();
    final second = verify(() => bridgeService.sendEvent(captureAny())).captured.single
        as BridgeEvent;

    expect(second.eventId, first.eventId);
  });

  test('resendLastEvent is a no-op when nothing has been sent yet', () async {
    await cubit.resendLastEvent();
    verifyNever(() => bridgeService.sendEvent(any()));
  });

  test('sendMalformedRaw feeds the debug seam, not sendEvent', () async {
    await cubit.sendMalformedRaw();

    verify(() => bridgeService.debugSimulateInboundRaw(any())).called(1);
    verifyNever(() => bridgeService.sendEvent(any()));
  });

  test('logStream entries flow into BridgeState.log', () {
    final entry = BridgeLogEntry(
      id: 'EVT-1',
      direction: BridgeDirection.appToWeb,
      status: BridgeDeliveryStatus.queued,
    );

    logController.add(entry);

    expect(cubit.state.log, [entry]);
  });

  test('simulateOffline/simulateOnline drive the connectivity override', () {
    cubit.simulateOffline();
    verify(() => connectivityService.debugOverrideOnline(false)).called(1);

    cubit.simulateOnline();
    verify(() => connectivityService.debugOverrideOnline(true)).called(1);
  });
}
