import { requirePageAdmin } from '@/lib/auth';
import { getAffiliateEarnings } from '@/lib/repositories/affiliateRepository';
import { DataTable } from '@/components/admin/DataTable';
import { AffiliateCommissionActions } from '@/components/admin/AffiliateCommissionActions';
import { LoadMoreLink } from '@/components/admin/LoadMoreLink';

export default async function AffiliateEarningsPage({
  searchParams,
}: {
  searchParams: Promise<{ status?: string; cursor?: string }>;
}) {
  await requirePageAdmin('affiliate:write');
  const params = await searchParams;
  const page = await getAffiliateEarnings({ status: params.status, cursor: params.cursor });
  const earnings = page.rows;

  return (
    <main>
      <h1>Affiliate Earnings / Fraud Review</h1>
      <DataTable
        rows={earnings}
        empty="No affiliate earnings found."
        columns={[
          { key: 'affiliate', header: 'Affiliate', render: (row: any) => row.affiliateUserId || '-' },
          { key: 'amount', header: 'Amount', render: (row: any) => `${row.currency || 'KES'} ${row.amount || 0}` },
          { key: 'source', header: 'Source', render: (row: any) => row.source || '-' },
          { key: 'status', header: 'Status', render: (row: any) => row.status || '-' },
          { key: 'actions', header: 'Actions', render: (row: any) => <AffiliateCommissionActions earningId={row.id} /> },
        ]}
      />
      <LoadMoreLink basePath="/affiliate/earnings" nextCursor={page.nextCursor} />
    </main>
  );
}
