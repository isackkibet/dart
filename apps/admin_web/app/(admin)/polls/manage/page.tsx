import { requirePageAdmin } from '@/lib/auth';
import { getPolls } from '@/lib/repositories/pollsRepository';
import { DataTable } from '@/components/admin/DataTable';
import { PollActions } from '@/components/admin/PollActions';
import { LoadMoreLink } from '@/components/admin/LoadMoreLink';

export default async function PollManagePage({
  searchParams,
}: {
  searchParams: Promise<{ status?: string; cursor?: string }>;
}) {
  await requirePageAdmin('polls:read');
  const params = await searchParams;
  const page = await getPolls({ status: params.status, cursor: params.cursor });
  const polls = page.rows;

  return (
    <main>
      <h1>Poll Management</h1>
      <DataTable
        rows={polls}
        empty="No polls found."
        columns={[
          { key: 'question', header: 'Question', render: (row: any) => row.question || row.title || '-' },
          { key: 'creator', header: 'Creator', render: (row: any) => row.creatorId || '-' },
          { key: 'status', header: 'Status', render: (row: any) => row.status || '-' },
          { key: 'actions', header: 'Actions', render: (row: any) => <PollActions pollId={row.id} /> },
        ]}
      />
      <LoadMoreLink basePath="/polls/manage" nextCursor={page.nextCursor} />
    </main>
  );
}
