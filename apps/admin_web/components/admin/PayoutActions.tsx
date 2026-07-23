'use client';
import { useState } from 'react';
import { useRouter } from 'next/navigation';

type Action = 'hold' | 'approve' | 'reject';

export function PayoutActions({ payoutId }: { payoutId: string }) {
  const [reason, setReason] = useState('');
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState('');
  const [ok, setOk] = useState(true);
  const router = useRouter();

  async function act(action: Action) {
    setBusy(true);
    setMessage('');
    try {
      const response = await fetch(`/api/admin/payouts/${payoutId}/${action}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ reason }),
      });
      const body = await response.json();
      setOk(response.ok);
      setMessage(response.ok ? `${action} successful` : body.error || 'Action failed');
      if (response.ok) router.refresh();
    } catch {
      setOk(false);
      setMessage('Network error');
    } finally {
      setBusy(false);
    }
  }

  return (
    <div style={{ display: 'grid', gap: 10 }}>
      <textarea
        placeholder="Reason / notes"
        value={reason}
        onChange={(e) => setReason(e.target.value)}
        rows={2}
        style={{ padding: 10, borderRadius: 10, width: '100%', background: 'rgba(255,255,255,.06)', border: '1px solid var(--border)', color: 'var(--text)', resize: 'vertical' }}
      />
      <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
        <button disabled={busy} className="btn secondary" onClick={() => act('hold')}>Hold</button>
        <button disabled={busy} className="btn" onClick={() => act('approve')}>Approve</button>
        <button disabled={busy} className="btn danger" onClick={() => act('reject')}>Reject</button>
      </div>
      {message && (
        <p style={{ fontSize: 12, color: ok ? '#00c864' : 'var(--danger)', marginTop: 2 }}>{message}</p>
      )}
    </div>
  );
}
