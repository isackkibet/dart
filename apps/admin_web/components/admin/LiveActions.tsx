'use client';
import { useRouter } from 'next/navigation';
import { useState } from 'react';

export function LiveActions({ sessionId }: { sessionId: string }) {
  const router = useRouter();
  const [reason, setReason] = useState('');
  const [busy, setBusy] = useState(false);

  async function act(action: 'terminate' | 'rotate-rtmp-key' | 'revoke-rtmp-key') {
    setBusy(true);
    await fetch(`/api/admin/live/${sessionId}/${action}`, {
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
      <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
        <button className="btn danger" disabled={busy} onClick={() => act('terminate')}>
          Force End
        </button>
        <button className="btn secondary" disabled={busy} onClick={() => act('rotate-rtmp-key')}>
          Rotate RTMP Key
        </button>
        <button className="btn secondary" disabled={busy} onClick={() => act('revoke-rtmp-key')}>
          Revoke RTMP Key
        </button>
      </div>
    </div>
  );
}
