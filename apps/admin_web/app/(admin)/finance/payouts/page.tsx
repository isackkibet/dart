import { DataTable } from '@/components/admin/DataTable';
import { PageHeader } from '@/components/admin/PageHeader';
import { PayoutActions } from '@/components/admin/PayoutActions';
import { requirePageAdmin } from '@/lib/auth';
import { getPendingPayouts } from '@/lib/repositories/financeRepository';
import { LoadMoreLink } from '@/components/admin/LoadMoreLink';

export default async function PayoutsPage({
  searchParams,
}: {
  searchParams: Promise<{ cursor?: string }>;
}) {
  await requirePageAdmin('finance:approve');
  const { cursor } = await searchParams;
  const page = await getPendingPayouts(cursor);
  const rows = page.rows;
  return (
    <>
      <PageHeader
        badge="Finance"
        title="Payout Review Queue"
        description="Pending creator payouts with risk scores, M-Pesa B2C status and approve / hold / reject actions."
      />
      <DataTable
        rows={rows}
        empty="No pending payout requests."
        columns={[
          { key: 'creator', header: 'Creator', render: (r) => r.creatorId || '-' },
          { key: 'amount', header: 'Amount', render: (r) => `${r.currency || 'KES'} ${r.amount || 0}` },
          { key: 'risk', header: 'Risk Score', render: (r) => r.riskScore ?? '-' },
          { key: 'mpesa', header: 'M-Pesa Status', render: (r) => r.mpesaB2CStatus || 'not sent' },
          { key: 'status', header: 'Status', render: (r) => <span className="badge">{r.status || 'pending'}</span> },
          { key: 'actions', header: 'Actions', render: (r) => <PayoutActions payoutId={r.id} /> },
        ]}
      />
      <LoadMoreLink basePath="/finance/payouts" nextCursor={page.nextCursor} />
    </>
  );
}
