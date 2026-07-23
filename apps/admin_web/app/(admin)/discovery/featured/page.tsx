import { requirePageAdmin } from '@/lib/auth';
import { getFeaturedContent } from '@/lib/repositories/discoveryRepository';
import { DataTable } from '@/components/admin/DataTable';

export default async function FeaturedContentPage() {
  await requirePageAdmin('video:write');
  const rows = await getFeaturedContent();

  return (
    <main>
      <h1>Featured Content</h1>
      <DataTable
        rows={rows}
        empty="No featured content found."
        columns={[
          { key: 'contentId', header: 'Content', render: (row: any) => row.contentId || '-' },
          { key: 'type', header: 'Type', render: (row: any) => row.contentType || '-' },
          { key: 'status', header: 'Status', render: (row: any) => row.status || '-' },
        ]}
      />
    </main>
  );
}
