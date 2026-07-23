import { requirePageAdmin } from '@/lib/auth';
import {
  getContactsGrowth,
  getInviteFraudPatterns,
  getReferralAnalytics,
} from '@/lib/repositories/growthRepository';
import { DataTable } from '@/components/admin/DataTable';

export default async function GrowthPage() {
  await requirePageAdmin('dashboard:read');
  const referrals = await getReferralAnalytics();
  const fraud = await getInviteFraudPatterns();
  const contacts = await getContactsGrowth();

  return (
    <main>
      <h1>Contacts & User Growth</h1>
      <h2>Referral Conversion</h2>
      <DataTable
        rows={referrals}
        empty="No referral records found."
        columns={[
          { key: 'referrer', header: 'Referrer', render: (row: any) => row.referrerUserId || '-' },
          { key: 'referred', header: 'Referred', render: (row: any) => row.referredUserId || '-' },
          { key: 'status', header: 'Status', render: (row: any) => row.status || '-' },
        ]}
      />
      <h2>Invite Fraud Patterns</h2>
      <DataTable
        rows={fraud}
        empty="No invite fraud patterns found."
        columns={[
          { key: 'pattern', header: 'Pattern', render: (row: any) => row.pattern || '-' },
          { key: 'risk', header: 'Risk', render: (row: any) => row.riskScore || '-' },
          { key: 'status', header: 'Status', render: (row: any) => row.status || '-' },
        ]}
      />
      <h2>Contacts Growth</h2>
      <DataTable
        rows={contacts}
        empty="No contacts data found."
        columns={[
          { key: 'owner', header: 'Owner', render: (row: any) => row.ownerUserId || '-' },
          { key: 'count', header: 'Contact Count', render: (row: any) => row.count || '-' },
        ]}
      />
    </main>
  );
}
