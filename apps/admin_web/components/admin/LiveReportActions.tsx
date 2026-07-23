'use client';
import { useRouter } from 'next/navigation';
import { useState } from 'react';

export function LiveReportActions({ reportId }: { reportId: string }) {
  const router = useRouter();
  const [reason, setReason] = useState('');
  const [busy, setBusy] = useState(false);

  async function act(action: 'approve' | 'reject' | 'escalate') {
    setBusy(true);
    await fetch(`/api/admin/live-reports/${reportId}/${action}`, {
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
        placeholder="Review reason"
        value={reason}
        onChange={(e) => setReason(e.target.value)}
      />
      <div style={{ display: 'flex', gap: 8 }}>
        <button className="btn secondary" disabled={busy} onClick={() => act('approve')}>
          Approve
        </button>
        <button className="btn secondary" disabled={busy} onClick={() => act('escalate')}>
          Escalate
        </button>
        <button className="btn danger" disabled={busy} onClick={() => act('reject')}>
          Reject
        </button>
      </div>
    </div>
  );
}
