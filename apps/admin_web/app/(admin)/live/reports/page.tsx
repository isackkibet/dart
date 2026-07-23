import { requirePageAdmin } from '@/lib/auth';
import { getLiveReports } from '@/lib/repositories/liveReportRepository';
import { DataTable } from '@/components/admin/DataTable';
import { LiveReportActions } from '@/components/admin/LiveReportActions';

export default async function LiveReportsPage() {
  await requirePageAdmin('live:moderate');
  const reports = await getLiveReports();

  return (
    <main>
      <h1>Live Reports</h1>
      <DataTable
        rows={reports}
        empty="No open live reports."
        columns={[
          { key: 'sessionId', header: 'Session', render: (row: any) => row.sessionId || '-' },
          { key: 'reporter', header: 'Reporter', render: (row: any) => row.reporterUserId || '-' },
          { key: 'reason', header: 'Reason', render: (row: any) => row.reason || '-' },
          { key: 'status', header: 'Status', render: (row: any) => row.status || '-' },
          {
            key: 'actions',
            header: 'Actions',
            render: (row: any) => <LiveReportActions reportId={row.id} />,
          },
        ]}
      />
    </main>
  );
}
