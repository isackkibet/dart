import { requirePageAdmin } from '@/lib/auth';
import { getSponsoredPolls } from '@/lib/repositories/sponsoredPollRepository';
import { DataTable } from '@/components/admin/DataTable';

export default async function SponsoredPollsPage() {
  await requirePageAdmin('polls:write');
  const rows = await getSponsoredPolls();

  return (
    <main>
      <h1>Sponsored Poll Management</h1>
      <DataTable
        rows={rows}
        empty="No sponsored polls found."
        columns={[
          { key: 'question', header: 'Poll', render: (r: any) => r.question || '-' },
          { key: 'sponsor', header: 'Sponsor', render: (r: any) => r.sponsorId || '-' },
          { key: 'status', header: 'Status', render: (r: any) => r.sponsoredStatus || '-' },
        ]}
      />
    </main>
  );
}
