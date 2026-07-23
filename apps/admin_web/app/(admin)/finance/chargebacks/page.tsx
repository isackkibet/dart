import { requirePageAdmin } from '@/lib/auth';
import { getChargebacks } from '@/lib/repositories/disputeRepository';
import { DataTable } from '@/components/admin/DataTable';
import { LoadMoreLink } from '@/components/admin/LoadMoreLink';
import { ChargebackActions } from '@/components/admin/ChargebackActions';

export default async function ChargebacksPage({
  searchParams,
}: {
  searchParams: Promise<{ cursor?: string }>;
}) {
  await requirePageAdmin('finance:approve');
  const { cursor } = await searchParams;
  const page = await getChargebacks(cursor);

  return (
    <main>
      <h1>Chargebacks / Disputes</h1>
      <DataTable
        rows={page.rows}
        empty="No open chargebacks."
        columns={[
          { key: 'user', header: 'User', render: (r: any) => r.userId || '-' },
          { key: 'amount', header: 'Amount', render: (r: any) => `${r.currency || 'KES'} ${r.amount || 0}` },
          { key: 'reason', header: 'Reason', render: (r: any) => r.reason || '-' },
          { key: 'actions', header: 'Actions', render: (r: any) => <ChargebackActions id={r.id} /> },
        ]}
      />
      <LoadMoreLink basePath="/finance/chargebacks" nextCursor={page.nextCursor} />
    </main>
  );
}
