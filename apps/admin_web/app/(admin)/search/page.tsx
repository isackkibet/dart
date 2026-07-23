import { requirePageAdmin } from '@/lib/auth';
import { getSearchLogs, getBlockedSearchTerms } from '@/lib/repositories/discoveryRepository';
import { DataTable } from '@/components/admin/DataTable';

export default async function SearchAdminPage() {
  await requirePageAdmin('dashboard:read');
  const logs = await getSearchLogs();
  const blocked = await getBlockedSearchTerms();

  return (
    <main>
      <h1>Search Analytics</h1>
      <h2>Recent Search Logs</h2>
      <DataTable
        rows={logs}
        empty="No search logs found."
        columns={[
          { key: 'query', header: 'Query', render: (row: any) => row.query || '-' },
          { key: 'user', header: 'User', render: (row: any) => row.userId || '-' },
          { key: 'results', header: 'Results', render: (row: any) => row.resultCount ?? '-' },
        ]}
      />
      <h2>Blocked Search Terms</h2>
      <DataTable
        rows={blocked}
        empty="No blocked terms found."
        columns={[
          { key: 'term', header: 'Term', render: (row: any) => row.term || '-' },
          { key: 'reason', header: 'Reason', render: (row: any) => row.reason || '-' },
        ]}
      />
    </main>
  );
}
