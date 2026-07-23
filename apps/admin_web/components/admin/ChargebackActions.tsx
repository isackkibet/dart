'use client';
import { useRouter } from 'next/navigation';
import { useState } from 'react';

export function ChargebackActions({ id }: { id: string }) {
  const router = useRouter();
  const [reason, setReason] = useState('');
  const [busy, setBusy] = useState(false);

  async function act(action: 'approve' | 'reject' | 'escalate') {
    setBusy(true);
    await fetch(`/api/admin/chargebacks/${id}/${action}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ reason }),
    });
    setBusy(false);
    router.refresh();
  }

  return (
    <div style={{ display: 'grid', gap: 8 }}>
      <textarea
        value={reason}
        onChange={(e) => setReason(e.target.value)}
        placeholder="Reason"
        rows={2}
        style={{ padding: 8, borderRadius: 8, width: '100%', background: 'rgba(255,255,255,.06)', border: '1px solid var(--border)', color: 'var(--text)', resize: 'vertical' }}
      />
      <div style={{ display: 'flex', gap: 8 }}>
        <button className="btn" disabled={busy} onClick={() => act('approve')}>Approve</button>
        <button className="btn secondary" disabled={busy} onClick={() => act('escalate')}>Escalate</button>
        <button className="btn danger" disabled={busy} onClick={() => act('reject')}>Reject</button>
      </div>
    </div>
  );
}
