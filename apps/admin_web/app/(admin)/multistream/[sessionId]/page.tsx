import { requirePageAdmin } from '@/lib/auth';
import { getMultistreamDestinations } from '@/lib/repositories/multistreamRepository';
import { DataTable } from '@/components/admin/DataTable';

export default async function MultistreamDetailPage({
  params,
}: {
  params: Promise<{ sessionId: string }>;
}) {
  await requirePageAdmin('live:read');
  const { sessionId } = await params;
  const destinations = await getMultistreamDestinations(sessionId);

  return (
    <main>
      <h1>Destination Health</h1>
      <DataTable
        rows={destinations}
        empty="No destinations found."
        columns={[
          { key: 'platform', header: 'Platform', render: (row: any) => row.platform || '-' },
          { key: 'status', header: 'Status', render: (row: any) => row.status || '-' },
          { key: 'rtmpUrl', header: 'RTMP URL', render: (row: any) => row.rtmpUrl || '-' },
          { key: 'lastError', header: 'Last Error', render: (row: any) => row.lastError || '-' },
          { key: 'lastSeen', header: 'Last Seen', render: (row: any) => String(row.lastSeenAt || '-') },
        ]}
      />
    </main>
  );
}
