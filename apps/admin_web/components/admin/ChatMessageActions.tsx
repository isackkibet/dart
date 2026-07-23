'use client';
import { useRouter } from 'next/navigation';
import { useState } from 'react';

export function ChatMessageActions({
  messageId,
  userId,
}: {
  messageId: string;
  userId: string;
}) {
  const router = useRouter();
  const [reason, setReason] = useState('');
  const [busy, setBusy] = useState(false);

  async function act(action: 'hide' | 'warn') {
    setBusy(true);
    const url =
      action === 'hide'
        ? `/api/admin/chat/messages/${messageId}/hide`
        : `/api/admin/chat/users/${userId}/warn`;
    await fetch(url, {
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
        <button className="btn secondary" disabled={busy} onClick={() => act('warn')}>
          Warn User
        </button>
        <button className="btn danger" disabled={busy} onClick={() => act('hide')}>
          Hide Message
        </button>
      </div>
    </div>
  );
}
