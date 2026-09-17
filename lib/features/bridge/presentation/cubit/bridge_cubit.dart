import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bridge/bridge_event.dart';
import '../../../../core/bridge/bridge_service.dart';
import '../../../../core/connectivity/connectivity_service.dart';
import 'bridge_state.dart';

/// Drives the Bridge POC demo screen: forwards `BridgeService.logStream`
/// into UI state, and exposes one method per demo control button (each
/// exercising a specific test scenario from the POC's test matrix).
class BridgeCubit extends Cubit<BridgeState> {
  final BridgeService bridgeService;
  final ConnectivityService connectivityService;

  StreamSubscription? _logSub;
  BridgeEvent? _lastSent;

  BridgeCubit({required this.bridgeService, required this.connectivityService})
      : super(const BridgeState()) {
    _logSub = bridgeService.logStream.listen((entry) => emit(state.upsert(entry)));
  }

  /// The exact example from the requirements: ORDER_UPDATE / ORD1001 /
  /// COMPLETED / 1250.50.
  Future<void> sendOrderUpdateDemo() => _send(BridgeEvent.outbound(
        eventType: BridgeEventType.orderUpdate,
        payload: const {
          'orderId': 'ORD1001',
          'status': 'COMPLETED',
          'price': 1250.50,
        },
      ));

  /// Scenario 3: app sends multiple events quickly.
  Future<void> sendRapidFire({int count = 5}) async {
    for (var i = 1; i <= count; i++) {
      await _send(BridgeEvent.outbound(
        eventType: BridgeEventType.userAction,
        payload: {'sequence': i, 'action': 'RAPID_FIRE_DEMO'},
      ));
    }
  }

  /// Scenario 5: resends the exact same event (same `eventId`) — proves
  /// `sendEvent` never mutates/regenerates ids, and that the receiver (the
  /// React app) is responsible for recognizing and dropping the duplicate.
  Future<void> resendLastEvent() async {
    final event = _lastSent;
    if (event == null) return;
    await bridgeService.sendEvent(event);
  }

  /// Scenario 6: fires after a delay so it can be paired with the "Web
  /// hidden" toggle to prove queued delivery on visibility return.
  Future<void> sendDelayed({Duration delay = const Duration(seconds: 5)}) async {
    await Future<void>.delayed(delay);
    await _send(BridgeEvent.outbound(
      eventType: BridgeEventType.backgroundResult,
      payload: {'note': 'Delivered after a $delay delay'},
    ));
  }

  /// Scenario 7: bypasses normal validation entirely — feeds a broken
  /// payload straight into the inbound pipeline to prove malformed input
  /// is logged, not crashed on.
  Future<void> sendMalformedRaw() =>
      bridgeService.debugSimulateInboundRaw(const {'eventType': 'ORDER_UPDATE'});

  /// Scenario 8: large/complex nested payload.
  Future<void> sendLargePayload() => _send(BridgeEvent.outbound(
        eventType: BridgeEventType.apiResponse,
        payload: {
          'orders': List.generate(
            50,
            (i) => {
              'orderId': 'ORD${2000 + i}',
              'status': i.isEven ? 'COMPLETED' : 'PENDING',
              'price': 100.0 + i,
              'items': List.generate(
                5,
                (j) => {
                  'sku': 'SKU-$i-$j',
                  'qty': j + 1,
                  'meta': {'warehouse': 'WH-${j % 3}', 'fragile': j.isOdd},
                },
              ),
            },
          ),
        },
      ));

  void simulateOffline() => connectivityService.debugOverrideOnline(false);

  void simulateOnline() => connectivityService.debugOverrideOnline(true);

  void clearLog() => emit(state.clear());

  Future<void> _send(BridgeEvent event) async {
    _lastSent = event;
    await bridgeService.sendEvent(event);
  }

  @override
  Future<void> close() {
    _logSub?.cancel();
    return super.close();
  }
}
