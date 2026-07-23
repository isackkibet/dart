import { requirePageAdmin } from '@/lib/auth';
import { getLiveSessions } from '@/lib/repositories/liveRepository';
import { DataTable } from '@/components/admin/DataTable';
import { LiveActions } from '@/components/admin/LiveActions';
import { LoadMoreLink } from '@/components/admin/LoadMoreLink';

export default async function LiveAdminPage({
  searchParams,
}: {
  searchParams: Promise<{ status?: string; cursor?: string }>;
}) {
  await requirePageAdmin('live:read');
  const params = await searchParams;
  const page = await getLiveSessions({ status: params.status, cursor: params.cursor });
  const sessions = page.rows;

  return (
    <main>
      <h1>Live Sessions</h1>
      <form style={{ marginBottom: 20 }}>
        <select name="status" defaultValue={params.status || ''}>
          <option value="">All</option>
          <option value="starting">Starting</option>
          <option value="live">Live</option>
          <option value="ended">Ended</option>
          <option value="failed">Failed</option>
          <option value="terminated">Terminated</option>
        </select>
        <button className="btn" style={{ marginLeft: 8 }}>Filter</button>
      </form>
      <DataTable
        rows={sessions}
        empty="No live sessions found."
        columns={[
          { key: 'title', header: 'Title', render: (row: any) => row.title || '-' },
          { key: 'creator', header: 'Creator', render: (row: any) => row.creatorUserId || '-' },
          { key: 'status', header: 'Status', render: (row: any) => row.status || '-' },
          { key: 'viewers', header: 'Viewers', render: (row: any) => row.viewerCount || 0 },
          {
            key: 'actions',
            header: 'Actions',
            render: (row: any) => <LiveActions sessionId={row.id} />,
          },
        ]}
      />
      <LoadMoreLink basePath="/live" nextCursor={page.nextCursor} />
    </main>
  );
}
