import 'dart:async';
import 'dart:convert';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../connectivity/connectivity_service.dart';
import 'bridge_event.dart';
import 'bridge_log_entry.dart';

/// Owns the single [InAppWebViewController] for the bridge POC and every
/// piece of delivery bookkeeping around it: an outbound queue (persisted, so
/// nothing is lost across app restarts), inbound duplicate detection, and an
/// ACK/retry protocol for outbound events that request one.
///
/// Wire protocol (must match `web_poc/src/bridge.js`):
/// - App→Web: `controller.evaluateJavascript(source:
///   "window.__nativeBridge.dispatch(eventJson)")`. The React app defines
///   `window.__nativeBridge.dispatch(eventObject)`.
/// - Web→App: JS calls
///   `window.flutter_inappwebview.callHandler('nativeBridgeHandler', eventObject)`,
///   which arrives here as `arguments.first`, already JSON-decoded.
///
/// Registered once as a `get_it` singleton (mirrors [ConnectivityService]);
/// the demo page attaches/detaches its controller as it's created/disposed.
class BridgeService {
  final ConnectivityService connectivityService;
  final SharedPreferences prefs;

  static const handlerName = 'nativeBridgeHandler';
  static const _queuePrefsKey = 'bridge_outbound_queue_v1';
  static const _maxDedupEntries = 200;
  static const _dedupTtl = Duration(minutes: 10);
  static const _ackTimeout = Duration(seconds: 4);
  static const _maxRetryAttempts = 3;
  static const _retryBackoff = [
    Duration(seconds: 2),
    Duration(seconds: 5),
    Duration(seconds: 10),
  ];

  InAppWebViewController? _controller;
  bool _isReady = false;
  bool _flushing = false;

  final List<BridgeEvent> _queue = [];
  final Map<String, BridgeLogEntry> _pendingAcks = {};
  final Map<String, Timer> _ackTimers = {};
  final Map<String, DateTime> _dedupSeen = {};

  final _readyController = StreamController<bool>.broadcast();
  final _inboundController = StreamController<BridgeEvent>.broadcast();
  final _logController = StreamController<BridgeLogEntry>.broadcast();

  StreamSubscription<bool>? _connectivitySub;

  BridgeService({required this.connectivityService, required this.prefs}) {
    _connectivitySub = connectivityService.onStatusChanged.listen((online) {
      if (online) unawaited(_maybeFlush());
    });
  }

  bool get isReady => _isReady;
  Stream<bool> get readyStream => _readyController.stream;

  /// Validated, deduped, non-control Web→App events.
  Stream<BridgeEvent> get inboundEvents => _inboundController.stream;

  /// Unified log for the demo UI — every outbound status transition and
  /// every inbound receive/duplicate/malformed entry.
  Stream<BridgeLogEntry> get logStream => _logController.stream;

  /// Loads any outbound events persisted from a previous run (app was
  /// killed mid-delivery) so they flush again once the WebView is ready.
  Future<void> initialize() async {
    final raw = prefs.getString(_queuePrefsKey);
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw) as List;
      _queue.addAll(
        decoded
            .whereType<Map>()
            .map((e) => BridgeEvent.fromJson(Map<String, dynamic>.from(e))),
      );
    } catch (_) {
      // Corrupt persisted queue — start clean rather than crash startup.
      await prefs.remove(_queuePrefsKey);
    }
  }

  void attachController(InAppWebViewController controller) {
    _controller = controller;
    controller.addJavaScriptHandler(
      handlerName: handlerName,
      callback: _onJsMessage,
    );
  }

  /// Called when the demo page is disposed. Outstanding sends will fail and
  /// retry/expire normally; re-attaching (page reopened) lets a still-queued
  /// event resume once `BRIDGE_READY` re-fires.
  void detachController() {
    _controller = null;
    _isReady = false;
    _readyController.add(false);
  }

  /// App→Web. Queues (and persists) the event, then attempts delivery
  /// immediately if the web app is ready and the device is online.
  Future<void> sendEvent(BridgeEvent event) async {
    _queue.add(event);
    await _persistQueue();
    _emitLog(BridgeLogEntry(
      id: event.eventId,
      direction: BridgeDirection.appToWeb,
      event: event,
      status: BridgeDeliveryStatus.queued,
    ));
    unawaited(_maybeFlush());
  }

  /// Test/demo seam: feeds [rawPayload] through the exact same inbound
  /// validation/dedup/ack pipeline as a real `callHandler` message, without
  /// needing the React app's cooperation. Used by the "malformed event"
  /// demo control (an intentionally broken payload).
  Future<void> debugSimulateInboundRaw(Object? rawPayload) =>
      _processInboundRaw(rawPayload);

  void dispose() {
    _connectivitySub?.cancel();
    for (final timer in _ackTimers.values) {
      timer.cancel();
    }
    _readyController.close();
    _inboundController.close();
    _logController.close();
  }

  // --- outbound ---

  Future<void> _maybeFlush() async {
    if (_flushing) return;
    _flushing = true;
    try {
      while (_queue.isNotEmpty && isReady && connectivityService.isOnline) {
        final event = _queue.removeAt(0);
        await _persistQueue();
        await _dispatch(event);
      }
    } finally {
      _flushing = false;
    }
  }

  Future<void> _dispatch(BridgeEvent event) async {
    final entry = BridgeLogEntry(
      id: event.eventId,
      direction: BridgeDirection.appToWeb,
      event: event,
      status: BridgeDeliveryStatus.sending,
      attempt: event.retryCount,
      sentAt: DateTime.now(),
    );
    _emitLog(entry);

    // Registered *before* the JS call, not after awaiting it: the WebView
    // can call back into Dart via addJavaScriptHandler synchronously while
    // evaluateJavascript's own Future is still pending (the dispatched JS
    // runs and can call `callHandler` before the outer platform-channel
    // call returns). If a same-tick ACK arrived and this map entry didn't
    // exist yet, `_handleAck` would silently find nothing to clear, and the
    // event would time out and retry despite having already been acked.
    if (event.ackRequired) {
      _pendingAcks[event.eventId] =
          entry.copyWith(status: BridgeDeliveryStatus.awaitingAck);
    }

    final controller = _controller;
    try {
      if (controller == null) {
        throw StateError('No WebView attached');
      }
      await controller.evaluateJavascript(
        source:
            'window.__nativeBridge.dispatch(${jsonEncode(event.toJson())})',
      );
    } catch (e) {
      _pendingAcks.remove(event.eventId);
      _handleDispatchFailure(event, entry, e);
      return;
    }

    if (!event.ackRequired) {
      _emitLog(entry.copyWith(status: BridgeDeliveryStatus.sent));
      return;
    }

    // Still present means no synchronous ACK arrived during the call above
    // — safe now to surface "awaiting ack" and start the timeout clock. If
    // it's gone, `_handleAck` already resolved and logged it as `acked`.
    final stillPending = _pendingAcks[event.eventId];
    if (stillPending != null) {
      _emitLog(stillPending);
      _scheduleAckTimeout(event);
    }
  }

  void _handleDispatchFailure(
    BridgeEvent event,
    BridgeLogEntry entry,
    Object error,
  ) {
    if (event.retryCount >= _maxRetryAttempts) {
      _emitLog(entry.copyWith(
        status: BridgeDeliveryStatus.failed,
        errorMessage: error.toString(),
      ));
      return;
    }
    final nextAttempt = event.retryCount + 1;
    _emitLog(entry.copyWith(
      status: BridgeDeliveryStatus.retrying,
      errorMessage: error.toString(),
      attempt: nextAttempt,
    ));
    final delay = _retryBackoff[event.retryCount.clamp(0, _retryBackoff.length - 1)];
    Timer(delay, () => _dispatch(event.copyWith(retryCount: nextAttempt)));
  }

  void _scheduleAckTimeout(BridgeEvent event) {
    _ackTimers[event.eventId]?.cancel();
    _ackTimers[event.eventId] = Timer(_ackTimeout, () {
      final pending = _pendingAcks.remove(event.eventId);
      if (pending == null) return; // already acked
      _handleDispatchFailure(
        event,
        pending,
        TimeoutException('No ACK within $_ackTimeout'),
      );
    });
  }

  void _handleAck(String ackForEventId) {
    _ackTimers.remove(ackForEventId)?.cancel();
    final pending = _pendingAcks.remove(ackForEventId);
    if (pending == null) return;
    _emitLog(pending.copyWith(
      status: BridgeDeliveryStatus.acked,
      ackedAt: DateTime.now(),
    ));
  }

  Future<void> _persistQueue() => prefs.setString(
        _queuePrefsKey,
        jsonEncode(_queue.map((e) => e.toJson()).toList()),
      );

  // --- inbound ---

  dynamic _onJsMessage(List<dynamic> arguments) {
    return _processInboundRaw(arguments.isNotEmpty ? arguments.first : null);
  }

  Future<void> _processInboundRaw(Object? raw) async {
    BridgeEvent event;
    try {
      if (raw is! Map) {
        throw const FormatException('Inbound payload was not a JSON object');
      }
      event = BridgeEvent.fromJson(Map<String, dynamic>.from(raw));
    } catch (e) {
      _emitLog(BridgeLogEntry(
        id: 'MALFORMED-${DateTime.now().microsecondsSinceEpoch}',
        direction: BridgeDirection.webToApp,
        status: BridgeDeliveryStatus.malformed,
        errorMessage: e.toString(),
        receivedAt: DateTime.now(),
      ));
      return;
    }

    if (event.eventType == BridgeEventType.ack) {
      final ackForEventId = event.payload['ackForEventId'];
      if (ackForEventId is String) _handleAck(ackForEventId);
      return;
    }

    if (event.eventType == BridgeEventType.bridgeReady) {
      _isReady = true;
      _readyController.add(true);
      _emitLog(BridgeLogEntry(
        id: event.eventId,
        direction: BridgeDirection.webToApp,
        event: event,
        status: BridgeDeliveryStatus.received,
        receivedAt: DateTime.now(),
      ));
      unawaited(_maybeFlush());
      return;
    }

    if (_isDuplicate(event.eventId)) {
      _emitLog(BridgeLogEntry(
        id: event.eventId,
        direction: BridgeDirection.webToApp,
        event: event,
        status: BridgeDeliveryStatus.duplicate,
        receivedAt: DateTime.now(),
      ));
      return;
    }

    _emitLog(BridgeLogEntry(
      id: event.eventId,
      direction: BridgeDirection.webToApp,
      event: event,
      status: BridgeDeliveryStatus.received,
      receivedAt: DateTime.now(),
    ));
    _inboundController.add(event);
    if (event.ackRequired) unawaited(_sendAck(event.eventId));
  }

  Future<void> _sendAck(String forEventId) async {
    final controller = _controller;
    if (controller == null) return;
    final ack = BridgeEvent.outbound(
      eventType: BridgeEventType.ack,
      payload: {'ackForEventId': forEventId},
      ackRequired: false,
    );
    try {
      await controller.evaluateJavascript(
        source: 'window.__nativeBridge.dispatch(${jsonEncode(ack.toJson())})',
      );
    } catch (_) {
      // Best-effort — an unacked ack just means the sender's own
      // timeout/retry path handles it; nothing to surface here.
    }
  }

  /// Also records [eventId] as seen. Bounded by [_maxDedupEntries] with a
  /// [_dedupTtl] eviction sweep on every call, so this never grows unbounded
  /// across a long-running session.
  bool _isDuplicate(String eventId) {
    final now = DateTime.now();
    _dedupSeen.removeWhere((_, seenAt) => now.difference(seenAt) > _dedupTtl);
    if (_dedupSeen.containsKey(eventId)) return true;
    _dedupSeen[eventId] = now;
    while (_dedupSeen.length > _maxDedupEntries) {
      _dedupSeen.remove(_dedupSeen.keys.first);
    }
    return false;
  }

  void _emitLog(BridgeLogEntry entry) => _logController.add(entry);
}
