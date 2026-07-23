'use client';
import { useRouter } from 'next/navigation';
import { useState } from 'react';

export function PollActions({ pollId }: { pollId: string }) {
  const router = useRouter();
  const [reason, setReason] = useState('');
  const [busy, setBusy] = useState(false);

  async function act(action: 'close' | 'delete') {
    setBusy(true);
    await fetch(`/api/admin/polls/${pollId}/${action}`, {
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
        placeholder="Reason"
        value={reason}
        onChange={(e) => setReason(e.target.value)}
      />
      <div style={{ display: 'flex', gap: 8 }}>
        <button className="btn secondary" disabled={busy} onClick={() => act('close')}>
          Close
        </button>
        <button className="btn danger" disabled={busy} onClick={() => act('delete')}>
          Delete
        </button>
      </div>
    </div>
  );
}
