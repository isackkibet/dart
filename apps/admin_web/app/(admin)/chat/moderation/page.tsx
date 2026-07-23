import { requirePageAdmin } from '@/lib/auth';
import { getReportedChatMessages } from '@/lib/repositories/chatAdminRepository';
import { DataTable } from '@/components/admin/DataTable';
import { ChatMessageActions } from '@/components/admin/ChatMessageActions';
import { LoadMoreLink } from '@/components/admin/LoadMoreLink';

export default async function ChatModerationPage({
  searchParams,
}: {
  searchParams: Promise<{ cursor?: string }>;
}) {
  await requirePageAdmin('moderation:write');
  const { cursor } = await searchParams;
  const page = await getReportedChatMessages(cursor);
  const messages = page.rows;

  return (
    <main>
      <h1>Chat Message Moderation</h1>
      <DataTable
        rows={messages}
        empty="No reported chat messages."
        columns={[
          { key: 'conversation', header: 'Conversation', render: (row: any) => row.conversationId || '-' },
          { key: 'user', header: 'User', render: (row: any) => row.userId || '-' },
          { key: 'message', header: 'Message', render: (row: any) => row.text || row.message || '-' },
          { key: 'reason', header: 'Report Reason', render: (row: any) => row.reportReason || '-' },
          {
            key: 'actions',
            header: 'Actions',
            render: (row: any) => (
              <ChatMessageActions messageId={row.id} userId={row.userId} />
            ),
          },
        ]}
      />
      <LoadMoreLink basePath="/chat/moderation" nextCursor={page.nextCursor} />
    </main>
  );
}
