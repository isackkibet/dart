import { requirePageAdmin } from '@/lib/auth';
import { getPendingReconciliation } from '@/lib/repositories/reconciliationRepository';
import { DataTable } from '@/components/admin/DataTable';
import { PageHeader } from '@/components/admin/PageHeader';
import { ReconciliationActions } from '@/components/admin/ReconciliationActions';

export default async function ReconciliationPage() {
  await requirePageAdmin('finance:approve');
  const rows = await getPendingReconciliation();
  return (
    <>
      <PageHeader
        badge="Finance"
        title="Wallet Reconciliation"
        description="Pending reconciliation items requiring admin approval or rejection."
      />
      <DataTable
        rows={rows}
        empty="No pending reconciliation items."
        columns={[
          { key: 'walletId', header: 'Wallet', render: (row: Record<string, unknown>) => (row.walletId as string) || '-' },
          { key: 'amount', header: 'Amount', render: (row: Record<string, unknown>) => String(row.amount ?? 0) },
          { key: 'type', header: 'Type', render: (row: Record<string, unknown>) => (row.type as string) || '-' },
          { key: 'status', header: 'Status', render: (row: Record<string, unknown>) => <span className="badge">{(row.status as string) || 'pending'}</span> },
          { key: 'actions', header: 'Actions', render: (row: Record<string, unknown>) => <ReconciliationActions itemId={row.id as string} /> },
        ]}
      />
    </>
  );
}
