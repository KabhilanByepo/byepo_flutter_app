import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

/// The one event type every App↔Web message uses, mobile or web originated.
///
/// ```json
/// {
///   "eventId": "EVT-9c1f2e40-...",
///   "eventType": "ORDER_UPDATE",
///   "timestamp": "2026-09-15T12:30:05.123Z",
///   "source": "mobile",
///   "version": 1,
///   "ackRequired": true,
///   "retryCount": 0,
///   "payload": { "orderId": "ORD1001", "status": "COMPLETED", "price": 1250.50 }
/// }
/// ```
///
/// Control frames reuse this same envelope: [BridgeEventType.bridgeReady]
/// (empty payload, sent once by the web app when its listener is mounted)
/// and [BridgeEventType.ack] (`payload: {'ackForEventId': <id>}`).
class BridgeEvent extends Equatable {
  final String eventId;
  final String eventType;
  final DateTime timestamp; // always UTC
  final String source; // BridgeSource.mobile | BridgeSource.web
  final int version;
  final Map<String, dynamic> payload;
  final bool ackRequired;
  final int retryCount;

  const BridgeEvent({
    required this.eventId,
    required this.eventType,
    required this.timestamp,
    required this.source,
    this.version = 1,
    this.payload = const {},
    this.ackRequired = false,
    this.retryCount = 0,
  });

  /// App-originated convenience constructor — fills [eventId], [timestamp]
  /// and [source] automatically so call sites only supply what's specific
  /// to the event being sent.
  factory BridgeEvent.outbound({
    required String eventType,
    Map<String, dynamic> payload = const {},
    bool ackRequired = true,
  }) {
    return BridgeEvent(
      eventId: 'EVT-${const Uuid().v4()}',
      eventType: eventType,
      timestamp: DateTime.now().toUtc(),
      source: BridgeSource.mobile,
      payload: payload,
      ackRequired: ackRequired,
    );
  }

  /// Throws [FormatException] on missing/wrong-typed required fields —
  /// never returns a partially-valid event. Callers (`BridgeService`) catch
  /// this and log the input as malformed rather than letting it propagate.
  factory BridgeEvent.fromJson(Map<String, dynamic> json) {
    final eventId = json['eventId'];
    final eventType = json['eventType'];
    final timestamp = json['timestamp'];
    final source = json['source'];

    if (eventId is! String || eventId.isEmpty) {
      throw const FormatException('Missing or invalid "eventId"');
    }
    if (eventType is! String || eventType.isEmpty) {
      throw const FormatException('Missing or invalid "eventType"');
    }
    if (source != BridgeSource.mobile && source != BridgeSource.web) {
      throw const FormatException('Missing or invalid "source"');
    }
    DateTime parsedTimestamp;
    try {
      parsedTimestamp = DateTime.parse(timestamp as String).toUtc();
    } on Object {
      throw const FormatException('Missing or invalid "timestamp"');
    }

    final payload = json['payload'];
    final version = json['version'];
    final ackRequired = json['ackRequired'];
    final retryCount = json['retryCount'];

    return BridgeEvent(
      eventId: eventId,
      eventType: eventType,
      timestamp: parsedTimestamp,
      source: source,
      version: version is int ? version : 1,
      payload: payload is Map ? Map<String, dynamic>.from(payload) : const {},
      ackRequired: ackRequired is bool ? ackRequired : false,
      retryCount: retryCount is int ? retryCount : 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'eventType': eventType,
        'timestamp': timestamp.toIso8601String(),
        'source': source,
        'version': version,
        'payload': payload,
        'ackRequired': ackRequired,
        'retryCount': retryCount,
      };

  BridgeEvent copyWith({int? retryCount}) => BridgeEvent(
        eventId: eventId,
        eventType: eventType,
        timestamp: timestamp,
        source: source,
        version: version,
        payload: payload,
        ackRequired: ackRequired,
        retryCount: retryCount ?? this.retryCount,
      );

  bool get isControl =>
      eventType == BridgeEventType.bridgeReady || eventType == BridgeEventType.ack;

  @override
  List<Object?> get props =>
      [eventId, eventType, timestamp, source, version, payload, ackRequired, retryCount];
}

/// Extensible event-type constants. New app-level event types are added
/// here, not by branching communication logic elsewhere — `BridgeService`
/// treats every non-control `eventType` identically.
class BridgeEventType {
  const BridgeEventType._();

  static const orderUpdate = 'ORDER_UPDATE';
  static const pushNotification = 'PUSH_NOTIFICATION';
  static const userAction = 'USER_ACTION';
  static const apiResponse = 'API_RESPONSE';
  static const backgroundResult = 'BACKGROUND_RESULT';
  static const nativeEvent = 'NATIVE_EVENT';
  static const backendEvent = 'BACKEND_EVENT';

  /// Control: sent once by the web app when its bridge listener is mounted
  /// and ready to receive dispatches. Triggers `BridgeService`'s queue flush.
  static const bridgeReady = 'BRIDGE_READY';

  /// Control: acknowledges receipt of a specific `eventId`
  /// (`payload: {'ackForEventId': <id>}`).
  static const ack = 'ACK';
}

class BridgeSource {
  const BridgeSource._();

  static const mobile = 'mobile';
  static const web = 'web';
}
