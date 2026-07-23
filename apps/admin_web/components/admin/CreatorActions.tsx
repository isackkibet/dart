'use client';
import { useRouter } from 'next/navigation';
import { useState } from 'react';

export function CreatorActions({ creatorId }: { creatorId: string }) {
  const router = useRouter();
  const [reason, setReason] = useState('');
  const [trustScore, setTrustScore] = useState('');
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState('');
  const [ok, setOk] = useState(true);

  async function statusAction(action: 'suspend' | 'ban') {
    setBusy(true);
    setMessage('');
    try {
      const res = await fetch(`/api/admin/creators/${creatorId}/${action}`, {
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

  async function saveTrustScore() {
    setBusy(true);
    setMessage('');
    try {
      const res = await fetch(`/api/admin/creators/${creatorId}/trust-score`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ trustScore: Number(trustScore), reason }),
      });
      const body = await res.json();
      setOk(res.ok);
      setMessage(res.ok ? 'Trust score updated' : body.error || 'Action failed');
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
      <input
        placeholder="Trust score (0–100)"
        value={trustScore}
        onChange={(e) => setTrustScore(e.target.value)}
        type="number"
        min={0}
        max={100}
        style={{ padding: 8, borderRadius: 8, background: 'rgba(255,255,255,.06)', border: '1px solid var(--border)', color: 'var(--text)' }}
      />
      <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
        <button className="btn secondary" disabled={busy} onClick={() => statusAction('suspend')}>Suspend</button>
        <button className="btn danger" disabled={busy} onClick={() => statusAction('ban')}>Ban</button>
        <button className="btn" disabled={busy} onClick={saveTrustScore}>Update Trust Score</button>
      </div>
      {message && (
        <p style={{ fontSize: 11, color: ok ? '#00c864' : 'var(--danger)', marginTop: 2 }}>{message}</p>
      )}
    </div>
  );
}
