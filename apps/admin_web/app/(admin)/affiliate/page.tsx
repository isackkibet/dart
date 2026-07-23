import { requirePageAdmin } from '@/lib/auth';
import { getAffiliatePrograms } from '@/lib/repositories/affiliateRepository';
import { DataTable } from '@/components/admin/DataTable';

export default async function AffiliatePage() {
  await requirePageAdmin('affiliate:read');
  const programs = await getAffiliatePrograms();

  return (
    <main>
      <h1>Affiliate Programs</h1>
      <DataTable
        rows={programs}
        empty="No affiliate programs found."
        columns={[
          { key: 'name', header: 'Program', render: (row: any) => row.name || '-' },
          { key: 'status', header: 'Status', render: (row: any) => row.status || '-' },
          { key: 'commission', header: 'Commission', render: (row: any) => row.commissionRate || '-' },
        ]}
      />
    </main>
  );
}
