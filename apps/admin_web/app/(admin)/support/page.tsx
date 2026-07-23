import { requirePageAdmin } from '@/lib/auth';
import { getSupportTickets } from '@/lib/repositories/supportRepository';
import { DataTable } from '@/components/admin/DataTable';

export default async function SupportTicketsPage({
  searchParams,
}: {
  searchParams: Promise<{ status?: string }>;
}) {
  await requirePageAdmin('dashboard:read');
  const params = await searchParams;
  const tickets = await getSupportTickets({ status: params.status });

  return (
    <main>
      <h1>Support Tickets</h1>
      <DataTable
        rows={tickets}
        empty="No support tickets found."
        columns={[
          { key: 'subject', header: 'Subject', render: (row: any) => row.subject || '-' },
          { key: 'user', header: 'User', render: (row: any) => row.userId || '-' },
          { key: 'status', header: 'Status', render: (row: any) => row.status || '-' },
          { key: 'assignedTo', header: 'Assigned To', render: (row: any) => row.assignedTo || '-' },
        ]}
      />
    </main>
  );
}
