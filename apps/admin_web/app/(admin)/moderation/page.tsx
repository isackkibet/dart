import { PageHeader } from '@/components/admin/PageHeader';
import { DataTable } from '@/components/admin/DataTable';
import { ModerationActions } from '@/components/admin/ModerationActions';
import { requirePageAdmin } from '@/lib/auth';
import { getModerationReports } from '@/lib/repositories/moderationRepository';
import { LoadMoreLink } from '@/components/admin/LoadMoreLink';

export default async function ModerationPage({
  searchParams,
}: {
  searchParams: Promise<{ cursor?: string }>;
}) {
  await requirePageAdmin('moderation:read');
  const { cursor } = await searchParams;
  const page = await getModerationReports(cursor);
  const rows = page.rows;
  return (
    <>
      <PageHeader
        badge="Moderation"
        title="Moderation Report Queue"
        description="Queue for user-submitted content and user reports. Required for final launch gate."
      />
      <DataTable
        rows={rows}
        empty="No open moderation reports."
        columns={[
          { key: 'targetType', header: 'Target Type', render: (r) => r.targetType || '-' },
          { key: 'targetId', header: 'Target ID', render: (r) => r.targetId || '-' },
          { key: 'reason', header: 'Reason', render: (r) => r.reason || '-' },
          { key: 'reporter', header: 'Reporter', render: (r) => r.reporterUserId || '-' },
          { key: 'status', header: 'Status', render: (r) => <span className="badge">{r.status || 'open'}</span> },
          { key: 'actions', header: 'Actions', render: (r) => <ModerationActions reportId={r.id} /> },
        ]}
      />
      <LoadMoreLink basePath="/moderation" nextCursor={page.nextCursor} />
    </>
  );
}
