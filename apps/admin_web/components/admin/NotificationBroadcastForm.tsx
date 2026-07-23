'use client';
import { useState } from 'react';

export function NotificationBroadcastForm() {
  const [title, setTitle] = useState('');
  const [message, setMessage] = useState('');
  const [audience, setAudience] = useState('all');
  const [busy, setBusy] = useState(false);
  const [result, setResult] = useState('');

  async function submit() {
    setBusy(true);
    const response = await fetch('/api/admin/notifications/broadcast', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ title, message, audience }),
    });
    const body = await response.json();
    setResult(response.ok ? `Queued: ${body.broadcastId}` : body.error || 'Failed');
    setBusy(false);
  }

  return (
    <div className="card" style={{ display: 'grid', gap: 12 }}>
      <input placeholder="Title" value={title} onChange={(e) => setTitle(e.target.value)} />
      <textarea placeholder="Message" value={message} onChange={(e) => setMessage(e.target.value)} />
      <select value={audience} onChange={(e) => setAudience(e.target.value)}>
        <option value="all">All Users</option>
        <option value="creators">Creators</option>
        <option value="businesses">Businesses</option>
        <option value="inactive">Inactive Users</option>
      </select>
      <button className="btn" disabled={busy} onClick={submit}>
        Queue Broadcast
      </button>
      {result && <p>{result}</p>}
    </div>
  );
}
