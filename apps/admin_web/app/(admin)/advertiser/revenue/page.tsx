import { requirePageAdmin } from '@/lib/auth';
import { getAdRevenueShare } from '@/lib/repositories/adsRepository';
import { DataTable } from '@/components/admin/DataTable';

export default async function AdRevenuePage() {
  await requirePageAdmin('ads:read');
  const rows = await getAdRevenueShare();

  return (
    <main>
      <h1>Ad Revenue Analytics</h1>
      <DataTable
        rows={rows}
        empty="No ad revenue records found."
        columns={[
          { key: 'campaign', header: 'Campaign', render: (row: any) => row.campaignId || '-' },
          { key: 'creator', header: 'Creator', render: (row: any) => row.creatorId || '-' },
          { key: 'revenue', header: 'Revenue', render: (row: any) => `${row.currency || 'KES'} ${row.amount || 0}` },
          { key: 'status', header: 'Status', render: (row: any) => row.status || '-' },
        ]}
      />
    </main>
  );
}
