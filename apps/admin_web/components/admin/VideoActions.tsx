'use client';
import { useRouter } from 'next/navigation';
import { useState } from 'react';

type Action = 'hide' | 'unhide' | 'restrict' | 'delete';

export function VideoActions({ videoId }: { videoId: string }) {
  const router = useRouter();
  const [reason, setReason] = useState('');
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState('');
  const [ok, setOk] = useState(true);

  async function act(action: Action) {
    setBusy(true);
    setMessage('');
    try {
      const res = await fetch(`/api/admin/videos/${videoId}/${action}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ reason }),
      });
      const body = await res.json();
      setOk(res.ok);
      setMessage(res.ok ? `${action} successful` : body.error || 'Action failed');
      if (res.ok) router.refresh();
    } catch {
      setOk(false);
      setMessage('Network error');
    } finally {
      setBusy(false);
    }
  }

  return (
    <div style={{ display: 'grid', gap: 8 }}>
      <textarea
        placeholder="Reason"
        value={reason}
        onChange={(e) => setReason(e.target.value)}
        rows={2}
        style={{ padding: 8, borderRadius: 8, width: '100%', background: 'rgba(255,255,255,.06)', border: '1px solid var(--border)', color: 'var(--text)', resize: 'vertical' }}
      />
      <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
        <button className="btn secondary" disabled={busy} onClick={() => act('hide')}>Hide</button>
        <button className="btn secondary" disabled={busy} onClick={() => act('unhide')}>Unhide</button>
        <button className="btn secondary" disabled={busy} onClick={() => act('restrict')}>Restrict</button>
        <button className="btn danger" disabled={busy} onClick={() => act('delete')}>Delete</button>
      </div>
      {message && (
        <p style={{ fontSize: 11, color: ok ? '#00c864' : 'var(--danger)', marginTop: 2 }}>{message}</p>
      )}
    </div>
  );
}
