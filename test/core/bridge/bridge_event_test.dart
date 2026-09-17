import 'package:byepo_stock_market/core/bridge/bridge_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('outbound() fills eventId/timestamp/source automatically', () {
    final event = BridgeEvent.outbound(
      eventType: BridgeEventType.orderUpdate,
      payload: const {'orderId': 'ORD1001'},
    );

    expect(event.eventId, startsWith('EVT-'));
    expect(event.source, BridgeSource.mobile);
    expect(event.eventType, BridgeEventType.orderUpdate);
    expect(event.ackRequired, isTrue);
  });

  test('toJson/fromJson round-trips exactly', () {
    final original = BridgeEvent(
      eventId: 'EVT-1',
      eventType: BridgeEventType.orderUpdate,
      timestamp: DateTime.utc(2026, 9, 15, 12, 30, 5),
      source: BridgeSource.mobile,
      payload: const {'orderId': 'ORD1001', 'status': 'COMPLETED', 'price': 1250.50},
      ackRequired: true,
      retryCount: 2,
    );

    final decoded = BridgeEvent.fromJson(original.toJson());

    expect(decoded, original);
  });

  test('fromJson throws FormatException when eventId is missing', () {
    expect(
      () => BridgeEvent.fromJson(const {
        'eventType': 'ORDER_UPDATE',
        'timestamp': '2026-09-15T12:30:05.000Z',
        'source': 'mobile',
      }),
      throwsFormatException,
    );
  });

  test('fromJson throws FormatException when source is not mobile/web', () {
    expect(
      () => BridgeEvent.fromJson(const {
        'eventId': 'EVT-1',
        'eventType': 'ORDER_UPDATE',
        'timestamp': '2026-09-15T12:30:05.000Z',
        'source': 'server',
      }),
      throwsFormatException,
    );
  });

  test('fromJson throws FormatException on an unparseable timestamp', () {
    expect(
      () => BridgeEvent.fromJson(const {
        'eventId': 'EVT-1',
        'eventType': 'ORDER_UPDATE',
        'timestamp': 'not-a-date',
        'source': 'mobile',
      }),
      throwsFormatException,
    );
  });

  test('fromJson defaults version/payload/ackRequired/retryCount when absent', () {
    final event = BridgeEvent.fromJson(const {
      'eventId': 'EVT-1',
      'eventType': 'BRIDGE_READY',
      'timestamp': '2026-09-15T12:30:05.000Z',
      'source': 'web',
    });

    expect(event.version, 1);
    expect(event.payload, <String, dynamic>{});
    expect(event.ackRequired, isFalse);
    expect(event.retryCount, 0);
  });

  test('isControl is true only for BRIDGE_READY and ACK', () {
    expect(
      BridgeEvent.outbound(eventType: BridgeEventType.bridgeReady).isControl,
      isTrue,
    );
    expect(
      BridgeEvent.outbound(eventType: BridgeEventType.ack).isControl,
      isTrue,
    );
    expect(
      BridgeEvent.outbound(eventType: BridgeEventType.orderUpdate).isControl,
      isFalse,
    );
  });
}
