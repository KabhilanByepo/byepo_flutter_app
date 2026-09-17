import 'package:equatable/equatable.dart';

import 'bridge_event.dart';

enum BridgeDirection { appToWeb, webToApp }

enum BridgeDeliveryStatus {
  // Outbound (App→Web) lifecycle.
  queued,
  sending,
  sent,
  awaitingAck,
  acked,
  retrying,
  failed,
  // Inbound (Web→App) lifecycle.
  received,
  duplicate,
  malformed,
}

/// One row in the demo page's event log — the UI-facing projection of every
/// status transition `BridgeService` reports, on both directions.
class BridgeLogEntry extends Equatable {
  /// Equal to `event.eventId` for parseable entries; a synthetic id for
  /// [BridgeDeliveryStatus.malformed] entries, since no event could be
  /// constructed from the raw input.
  final String id;
  final BridgeDirection direction;
  final BridgeEvent? event;
  final BridgeDeliveryStatus status;
  final String? errorMessage;
  final int attempt;
  final DateTime? sentAt;
  final DateTime? ackedAt;
  final DateTime? receivedAt;

  const BridgeLogEntry({
    required this.id,
    required this.direction,
    required this.status,
    this.event,
    this.errorMessage,
    this.attempt = 0,
    this.sentAt,
    this.ackedAt,
    this.receivedAt,
  });

  /// Round-trip latency once acked (outbound) — null until then.
  int? get latencyMs {
    if (sentAt == null || ackedAt == null) return null;
    return ackedAt!.difference(sentAt!).inMilliseconds;
  }

  BridgeLogEntry copyWith({
    BridgeDeliveryStatus? status,
    String? errorMessage,
    int? attempt,
    DateTime? sentAt,
    DateTime? ackedAt,
    DateTime? receivedAt,
  }) {
    return BridgeLogEntry(
      id: id,
      direction: direction,
      event: event,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      attempt: attempt ?? this.attempt,
      sentAt: sentAt ?? this.sentAt,
      ackedAt: ackedAt ?? this.ackedAt,
      receivedAt: receivedAt ?? this.receivedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        direction,
        event,
        status,
        errorMessage,
        attempt,
        sentAt,
        ackedAt,
        receivedAt,
      ];
}
