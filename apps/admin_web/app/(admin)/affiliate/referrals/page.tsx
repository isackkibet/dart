import { requirePageAdmin } from '@/lib/auth';
import { getReferralTracking } from '@/lib/repositories/affiliateReferralRepository';
import { DataTable } from '@/components/admin/DataTable';

export default async function ReferralsPage() {
  await requirePageAdmin('affiliate:read');
  const rows = await getReferralTracking();

  return (
    <main>
      <h1>Referral Tracking</h1>
      <DataTable
        rows={rows}
        empty="No referrals found."
        columns={[
          { key: 'referrer', header: 'Referrer', render: (r: any) => r.referrerUserId || '-' },
          { key: 'referred', header: 'Referred', render: (r: any) => r.referredUserId || '-' },
          { key: 'status',   header: 'Status',   render: (r: any) => r.status         || '-' },
        ]}
      />
    </main>
  );
}
