import 'package:equatable/equatable.dart';

import '../../../../core/bridge/bridge_log_entry.dart';

/// A continuously-updating event log, not a single async fetch's lifecycle —
/// deliberately a single concrete class rather than the sealed
/// `Initial/Loading/Loaded/Error` shape used elsewhere in this app (e.g.
/// `WatchlistState`). There's no "loading" phase here; errors (malformed/
/// failed deliveries) are just rows in the log, not a distinct app state.
class BridgeState extends Equatable {
  /// Newest-first.
  final List<BridgeLogEntry> log;

  const BridgeState({this.log = const []});

  /// Replaces the existing row with the same `id` (a status transition on
  /// an event already in the log — e.g. sending → awaitingAck → acked), or
  /// prepends a new row if none exists yet.
  BridgeState upsert(BridgeLogEntry entry) {
    final index = log.indexWhere((e) => e.id == entry.id);
    if (index == -1) {
      return BridgeState(log: [entry, ...log]);
    }
    final updated = List<BridgeLogEntry>.from(log);
    updated[index] = entry;
    return BridgeState(log: updated);
  }

  BridgeState clear() => const BridgeState();

  @override
  List<Object?> get props => [log];
}
