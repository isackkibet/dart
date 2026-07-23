'use client';
import { useRouter } from 'next/navigation';
import { useState } from 'react';

export function AiJobActions({ jobId }: { jobId: string }) {
  const router = useRouter();
  const [reason, setReason] = useState('');
  const [busy, setBusy] = useState(false);

  async function requeue() {
    setBusy(true);
    await fetch(`/api/admin/ai-video-jobs/${jobId}/requeue`, {
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
        placeholder="Requeue reason"
        value={reason}
        onChange={(e) => setReason(e.target.value)}
      />
      <button className="btn" disabled={busy} onClick={requeue}>
        Requeue
      </button>
    </div>
  );
}
