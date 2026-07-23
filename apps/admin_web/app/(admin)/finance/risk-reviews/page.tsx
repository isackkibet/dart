import { requirePageAdmin } from '@/lib/auth';
import { getOpenRiskReviews } from '@/lib/repositories/riskReviewRepository';
import { DataTable } from '@/components/admin/DataTable';
import { PageHeader } from '@/components/admin/PageHeader';
import { RiskReviewActions } from '@/components/admin/RiskReviewActions';

export default async function RiskReviewsPage() {
  await requirePageAdmin('finance:approve');
  const rows = await getOpenRiskReviews();
  return (
    <>
      <PageHeader
        badge="Finance"
        title="Risk Review Queue"
        description="Open risk reviews flagged by automated scoring. Approve to clear or escalate for further investigation."
      />
      <DataTable
        rows={rows}
        empty="No open risk reviews."
        columns={[
          { key: 'entity', header: 'Entity', render: (row: Record<string, unknown>) => (row.entityId as string) || '-' },
          { key: 'risk', header: 'Risk Score', render: (row: Record<string, unknown>) => String(row.riskScore ?? '-') },
          { key: 'reason', header: 'Reason', render: (row: Record<string, unknown>) => (row.reason as string) || '-' },
          { key: 'status', header: 'Status', render: (row: Record<string, unknown>) => <span className="badge">{(row.status as string) || 'open'}</span> },
          { key: 'actions', header: 'Actions', render: (row: Record<string, unknown>) => <RiskReviewActions reviewId={row.id as string} /> },
        ]}
      />
    </>
  );
}
