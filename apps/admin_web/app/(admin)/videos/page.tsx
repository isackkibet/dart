import { requirePageAdmin } from '@/lib/auth';
import { getVideos } from '@/lib/repositories/videoRepository';
import { DataTable } from '@/components/admin/DataTable';
import { PageHeader } from '@/components/admin/PageHeader';
import { VideoActions } from '@/components/admin/VideoActions';
import { LoadMoreLink } from '@/components/admin/LoadMoreLink';

export default async function VideosPage({
  searchParams,
}: {
  searchParams: Promise<{ status?: string; visibility?: string; creatorUserId?: string; cursor?: string }>;
}) {
  await requirePageAdmin('video:read');
  const params = await searchParams;
  const page = await getVideos({
    status: params.status,
    visibility: params.visibility,
    creatorUserId: params.creatorUserId,
    cursor: params.cursor,
  });
  const videos = page.rows;

  return (
    <>
      <PageHeader
        badge="Videos"
        title="Video Management"
        description="Browse, filter, hide, restrict, or delete videos. Use query params: ?status=&visibility=&creatorUserId="
      />
      <DataTable
        rows={videos}
        empty="No videos found."
        columns={[
          { key: 'title', header: 'Title', render: (row: Record<string, unknown>) => (row.title as string) || '-' },
          { key: 'creator', header: 'Creator', render: (row: Record<string, unknown>) => (row.userId as string) || '-' },
          { key: 'status', header: 'Status', render: (row: Record<string, unknown>) => <span className="badge">{(row.status as string) || '-'}</span> },
          { key: 'visibility', header: 'Visibility', render: (row: Record<string, unknown>) => <span className="badge">{(row.visibility as string) || 'public'}</span> },
          { key: 'actions', header: 'Actions', render: (row: Record<string, unknown>) => <VideoActions videoId={row.id as string} /> },
        ]}
      />
      <LoadMoreLink basePath="/videos" nextCursor={page.nextCursor} />
    </>
  );
}
