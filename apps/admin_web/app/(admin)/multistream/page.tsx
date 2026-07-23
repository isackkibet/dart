import { requirePageAdmin } from '@/lib/auth';
import { getMultistreamSessions } from '@/lib/repositories/multistreamRepository';
import { DataTable } from '@/components/admin/DataTable';
import Link from 'next/link';

export default async function MultistreamPage() {
  await requirePageAdmin('live:read');
  const sessions = await getMultistreamSessions();

  return (
    <main>
      <h1>Multi-Streaming Sessions</h1>
      <DataTable
        rows={sessions}
        empty="No multistream sessions found."
        columns={[
          { key: 'liveSessionId', header: 'Live Session', render: (row: any) => row.liveSessionId || '-' },
          { key: 'creator', header: 'Creator', render: (row: any) => row.creatorUserId || '-' },
          { key: 'status', header: 'Status', render: (row: any) => row.status || '-' },
          { key: 'destinations', header: 'Destinations', render: (row: any) => row.destinationCount || 0 },
          { key: 'errors', header: 'Errors', render: (row: any) => row.errorCount || 0 },
          {
            key: 'detail',
            header: 'Detail',
            render: (row: any) => (
              <Link href={`/multistream/${row.id}`} className="btn secondary" style={{ fontSize: 12 }}>
                Destinations
              </Link>
            ),
          },
        ]}
      />
    </main>
  );
}
