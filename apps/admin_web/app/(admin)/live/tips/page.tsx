import { requirePageAdmin } from '@/lib/auth';
import { getLiveTips } from '@/lib/repositories/liveTipsRepository';
import { DataTable } from '@/components/admin/DataTable';

export default async function LiveTipsPage() {
  await requirePageAdmin('finance:read');
  const tips = await getLiveTips();

  return (
    <main>
      <h1>Live Tips / Revenue</h1>
      <DataTable
        rows={tips}
        empty="No live tips found."
        columns={[
          { key: 'sessionId', header: 'Session', render: (row: any) => row.sessionId || '-' },
          { key: 'creator', header: 'Creator', render: (row: any) => row.creatorUserId || '-' },
          { key: 'amount', header: 'Amount', render: (row: any) => `${row.currency || 'KES'} ${row.amount || 0}` },
          { key: 'status', header: 'Status', render: (row: any) => row.status || '-' },
        ]}
      />
    </main>
  );
}
