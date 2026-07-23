import { requirePageAdmin } from '@/lib/auth';
import { getCreators } from '@/lib/repositories/creatorRepository';
import { DataTable } from '@/components/admin/DataTable';
import { PageHeader } from '@/components/admin/PageHeader';
import { CreatorActions } from '@/components/admin/CreatorActions';
import { LoadMoreLink } from '@/components/admin/LoadMoreLink';

export default async function CreatorsPage({
  searchParams,
}: {
  searchParams: Promise<{ q?: string; cursor?: string }>;
}) {
  await requirePageAdmin('creator:read');
  const params = await searchParams;
  const page = await getCreators({ q: params.q, cursor: params.cursor });
  const creators = page.rows;

  return (
    <>
      <PageHeader
        badge="Creators"
        title="Creator Management"
        description="Search, suspend, ban, or adjust trust scores for creators. Requires creator_manager or owner role."
      />
      <form style={{ marginBottom: 20 }}>
        <input
          name="q"
          placeholder="Search by keyword (matches searchKeywords array)"
          defaultValue={params.q || ''}
          style={{ padding: 12, borderRadius: 12, width: 360, background: 'rgba(255,255,255,.06)', border: '1px solid var(--border)', color: 'var(--text)' }}
        />
        <button className="btn" style={{ marginLeft: 10 }}>Search</button>
      </form>
      <DataTable
        rows={creators}
        empty="No creators found."
        columns={[
          { key: 'name', header: 'Name', render: (row: Record<string, unknown>) => (row.displayName as string) || (row.name as string) || '-' },
          { key: 'email', header: 'Email', render: (row: Record<string, unknown>) => (row.email as string) || '-' },
          { key: 'status', header: 'Status', render: (row: Record<string, unknown>) => <span className="badge">{(row.status as string) || 'active'}</span> },
          { key: 'trust', header: 'Trust Score', render: (row: Record<string, unknown>) => String(row.trustScore ?? '-') },
          { key: 'actions', header: 'Actions', render: (row: Record<string, unknown>) => <CreatorActions creatorId={row.id as string} /> },
        ]}
      />
      <LoadMoreLink basePath="/creators" nextCursor={page.nextCursor} />
    </>
  );
}
