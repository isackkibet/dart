import { requirePageAdmin } from '@/lib/auth';
import { getBlockedSearchTerms } from '@/lib/repositories/discoveryRepository';
import { DataTable } from '@/components/admin/DataTable';

export default async function BlockedSearchTermsPage() {
  await requirePageAdmin('dashboard:read');
  const rows = await getBlockedSearchTerms();

  return (
    <main>
      <h1>Blocked Search Terms</h1>
      <DataTable
        rows={rows}
        empty="No blocked terms."
        columns={[
          { key: 'term',   header: 'Term',   render: (r: any) => r.term   || '-' },
          { key: 'reason', header: 'Reason', render: (r: any) => r.reason || '-' },
          { key: 'status', header: 'Status', render: (r: any) => r.status || '-' },
        ]}
      />
    </main>
  );
}
