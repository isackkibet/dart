import { requirePageAdmin } from '@/lib/auth';
import { getTrendingTopics } from '@/lib/repositories/discoveryRepository';
import { DataTable } from '@/components/admin/DataTable';

export default async function TrendingTopicsPage() {
  await requirePageAdmin('video:write');
  const rows = await getTrendingTopics();

  return (
    <main>
      <h1>Trending Topics</h1>
      <DataTable
        rows={rows}
        empty="No trending topics found."
        columns={[
          { key: 'topic', header: 'Topic', render: (row: any) => row.topic || row.name || '-' },
          { key: 'score', header: 'Score', render: (row: any) => row.score || 0 },
          { key: 'status', header: 'Status', render: (row: any) => row.status || '-' },
        ]}
      />
    </main>
  );
}
