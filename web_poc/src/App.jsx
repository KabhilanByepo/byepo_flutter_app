import { useEffect, useRef, useState } from 'react';
import { onBridgeEvent, sendToApp } from './bridge.js';

function upsertLog(log, entry) {
  const index = log.findIndex((e) => e.id === entry.id);
  if (index === -1) return [{ ...entry }, ...log];
  const next = [...log];
  next[index] = { ...next[index], ...entry };
  return next;
}

const STATUS_LABEL = {
  queued: 'QUEUED',
  sending: 'SENDING',
  sent: 'SENT',
  awaitingAck: 'AWAITING ACK',
  acked: 'ACKED',
  retrying: 'RETRYING',
  failed: 'FAILED',
  received: 'RECEIVED',
  duplicate: 'DUPLICATE',
  malformed: 'MALFORMED',
};

const STATUS_CLASS = {
  failed: 'status-error',
  malformed: 'status-error',
  duplicate: 'status-warn',
  retrying: 'status-warn',
  acked: 'status-ok',
  sent: 'status-ok',
  received: 'status-ok',
};

function Row({ entry }) {
  const isAppToWeb = entry.direction === 'appToWeb';
  const latency = entry.sentAt && entry.ackedAt ? entry.ackedAt - entry.sentAt : null;
  return (
    <li className="log-row">
      <span className="log-arrow">{isAppToWeb ? '↙' : '↗'}</span>
      <div className="log-body">
        <div className="log-title">{entry.event?.eventType ?? '(unparseable payload)'}</div>
        <div className="log-subtitle">{entry.errorMessage ?? JSON.stringify(entry.event?.payload ?? '')}</div>
      </div>
      <div className="log-meta">
        <span className={`status-pill ${STATUS_CLASS[entry.status] ?? ''}`}>{STATUS_LABEL[entry.status] ?? entry.status}</span>
        {latency != null && <span className="latency">{latency}ms</span>}
      </div>
    </li>
  );
}

export default function App() {
  const [log, setLog] = useState([]);
  const [ready, setReady] = useState(false);
  const lastSentRef = useRef(null);

  useEffect(() => {
    const unsubscribe = onBridgeEvent((entry) => {
      setReady(true);
      setLog((prev) => upsertLog(prev, entry));
    });
    return unsubscribe;
  }, []);

  const sendSingle = () => {
    const event = sendToApp('USER_ACTION', { action: 'BUTTON_TAP', label: 'Single event from web' });
    lastSentRef.current = event;
  };

  const sendRapid = () => {
    for (let i = 1; i <= 5; i++) {
      sendToApp('USER_ACTION', { sequence: i, action: 'WEB_RAPID_FIRE_DEMO' });
    }
  };

  const resendLast = () => {
    if (!lastSentRef.current) return;
    // Same eventId, sent again — App-side BridgeService should log this as `duplicate`.
    if (window.flutter_inappwebview) {
      window.flutter_inappwebview.callHandler('nativeBridgeHandler', lastSentRef.current);
    }
  };

  const sendMalformed = () => {
    // Bypasses bridge.js's event construction entirely — sends a payload
    // missing required fields straight through the raw channel.
    if (window.flutter_inappwebview) {
      window.flutter_inappwebview.callHandler('nativeBridgeHandler', { oops: 'not a valid BridgeEvent' });
    }
  };

  const sendLarge = () => {
    const orders = Array.from({ length: 50 }, (_, i) => ({
      orderId: `ORD${3000 + i}`,
      status: i % 2 === 0 ? 'COMPLETED' : 'PENDING',
      price: 100 + i,
      items: Array.from({ length: 5 }, (_, j) => ({
        sku: `SKU-${i}-${j}`,
        qty: j + 1,
        meta: { warehouse: `WH-${j % 3}`, fragile: j % 2 === 1 },
      })),
    }));
    const event = sendToApp('API_RESPONSE', { orders });
    lastSentRef.current = event;
  };

  return (
    <div className="app">
      <header className="app-header">
        <h1>Byepo Bridge POC</h1>
        <span className={`ready-pill ${ready ? 'ready' : ''}`}>{ready ? 'Bridge connected' : 'Waiting for app…'}</span>
      </header>

      <div className="controls">
        <button onClick={sendSingle}>Send to App</button>
        <button onClick={sendRapid}>Rapid Fire (5)</button>
        <button onClick={resendLast}>Resend Last (duplicate)</button>
        <button onClick={sendMalformed}>Send Malformed</button>
        <button onClick={sendLarge}>Send Large Payload</button>
      </div>

      <ul className="log-list">
        {log.length === 0 && <li className="log-empty">No events yet</li>}
        {log.map((entry) => (
          <Row key={entry.id} entry={entry} />
        ))}
      </ul>
    </div>
  );
}
