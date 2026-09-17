// Wire protocol counterpart to lib/core/bridge/bridge_service.dart.
//
// App->Web: Flutter calls `window.__nativeBridge.dispatch(eventObject)`.
// Web->App: we call `window.flutter_inappwebview.callHandler('nativeBridgeHandler', eventObject)`.

const DEDUP_TTL_MS = 10 * 60 * 1000;
const seenInbound = new Map(); // eventId -> seenAt (ms)

const listeners = new Set();

// initBridge() runs (and may synchronously fire the BRIDGE_READY handshake)
// before React has mounted and subscribed via onBridgeEvent — without this
// buffer, that first notify() has no listener yet and is lost, leaving the
// UI stuck on "Waiting for app..." despite the handshake having actually
// succeeded. Replaying this history to each new subscriber closes that race.
const HISTORY_LIMIT = 50;
const history = [];

function notify(entry) {
  history.push(entry);
  if (history.length > HISTORY_LIMIT) history.shift();
  listeners.forEach((fn) => fn(entry));
}

/** Subscribe to every log-worthy bridge event (both directions), replaying
 * anything that fired before this subscription existed. Returns an unsubscribe fn. */
export function onBridgeEvent(fn) {
  history.forEach(fn);
  listeners.add(fn);
  return () => listeners.delete(fn);
}

function uuid() {
  if (typeof crypto !== 'undefined' && crypto.randomUUID) return crypto.randomUUID();
  // Fallback for older WebView engines without crypto.randomUUID.
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
    const r = (Math.random() * 16) | 0;
    const v = c === 'x' ? r : (r & 0x3) | 0x8;
    return v.toString(16);
  });
}

function isBridgeAvailable() {
  return typeof window !== 'undefined' && !!window.flutter_inappwebview;
}

function isDuplicateInbound(eventId) {
  const now = Date.now();
  for (const [id, seenAt] of seenInbound) {
    if (now - seenAt > DEDUP_TTL_MS) seenInbound.delete(id);
  }
  if (seenInbound.has(eventId)) return true;
  seenInbound.set(eventId, now);
  return false;
}

function makeEvent(eventType, payload, ackRequired) {
  return {
    eventId: `EVT-${uuid()}`,
    eventType,
    timestamp: new Date().toISOString(),
    source: 'web',
    version: 1,
    ackRequired,
    retryCount: 0,
    payload,
  };
}

/** Web->App. Returns the event that was (attempted to be) sent. */
export function sendToApp(eventType, payload = {}, { ackRequired = true } = {}) {
  const event = makeEvent(eventType, payload, ackRequired);

  if (!isBridgeAvailable()) {
    // Running standalone in a plain browser (e.g. `npm run dev`) — no
    // native host to deliver to. Log it so the demo UI still shows intent.
    console.warn('[bridge] flutter_inappwebview unavailable — standalone mode', event);
    notify({ id: event.eventId, direction: 'webToApp', event, status: 'failed', errorMessage: 'Native bridge unavailable (standalone browser)' });
    return event;
  }

  notify({ id: event.eventId, direction: 'webToApp', event, status: event.ackRequired ? 'awaitingAck' : 'sent', sentAt: Date.now() });
  window.flutter_inappwebview.callHandler('nativeBridgeHandler', event);
  return event;
}

function sendAck(forEventId) {
  if (!isBridgeAvailable()) return;
  const ack = makeEvent('ACK', { ackForEventId: forEventId }, false);
  window.flutter_inappwebview.callHandler('nativeBridgeHandler', ack);
}

function handleInbound(raw) {
  if (!raw || typeof raw !== 'object') {
    notify({ id: `malformed-${Date.now()}`, direction: 'appToWeb', status: 'malformed', errorMessage: 'Payload was not an object', receivedAt: Date.now() });
    return;
  }
  const event = raw;
  if (!event.eventId || !event.eventType) {
    notify({ id: `malformed-${Date.now()}`, direction: 'appToWeb', event, status: 'malformed', errorMessage: 'Missing eventId/eventType', receivedAt: Date.now() });
    return;
  }

  if (event.eventType === 'ACK') {
    // Correlates back to the *original* sent event's row (keyed by
    // ackForEventId), mirroring BridgeService._handleAck on the Dart side —
    // this is not a new row for the ACK control message itself.
    const ackForEventId = event.payload?.ackForEventId;
    if (ackForEventId) {
      notify({ id: ackForEventId, direction: 'webToApp', status: 'acked', ackedAt: Date.now() });
    }
    return;
  }

  if (isDuplicateInbound(event.eventId)) {
    notify({ id: event.eventId, direction: 'appToWeb', event, status: 'duplicate', receivedAt: Date.now() });
    return;
  }

  notify({ id: event.eventId, direction: 'appToWeb', event, status: 'received', receivedAt: Date.now() });
  if (event.ackRequired) sendAck(event.eventId);
}

let readySent = false;

function sendReadyHandshake() {
  if (readySent || !isBridgeAvailable()) return;
  readySent = true;
  sendToApp('BRIDGE_READY', {}, { ackRequired: false });
}

/** Call once at app startup (see main.jsx). */
export function initBridge() {
  window.__nativeBridge = {
    dispatch(event) {
      try {
        handleInbound(event);
      } catch (e) {
        notify({ direction: 'appToWeb', status: 'malformed', errorMessage: String(e), receivedAt: Date.now() });
      }
    },
  };

  if (isBridgeAvailable()) {
    sendReadyHandshake();
  } else {
    // Fired by flutter_inappwebview once its JS runtime is fully injected.
    window.addEventListener('flutterInAppWebViewPlatformReady', sendReadyHandshake);
  }
}
