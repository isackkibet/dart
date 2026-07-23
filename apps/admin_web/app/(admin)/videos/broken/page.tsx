import { requirePageAdmin } from '@/lib/auth';
import { getBrokenVideos } from '@/lib/repositories/videoRepository';
import { DataTable } from '@/components/admin/DataTable';
import { PageHeader } from '@/components/admin/PageHeader';
import { VideoActions } from '@/components/admin/VideoActions';

export default async function BrokenVideosPage() {
  await requirePageAdmin('video:read');
  const videos = await getBrokenVideos();

  return (
    <>
      <PageHeader
        badge="Videos"
        title="Broken Videos / Failed HLS"
        description="Videos with transcode_failed, processing_failed, or broken status. Actions available to hide or delete."
      />
      <DataTable
        rows={videos}
        empty="No broken videos found."
        columns={[
          { key: 'title', header: 'Title', render: (row: Record<string, unknown>) => (row.title as string) || '-' },
          { key: 'creator', header: 'Creator', render: (row: Record<string, unknown>) => (row.userId as string) || '-' },
          { key: 'status', header: 'Status', render: (row: Record<string, unknown>) => <span className="badge">{(row.status as string) || '-'}</span> },
          { key: 'error', header: 'Error', render: (row: Record<string, unknown>) => (row.transcodeError as string) || (row.error as string) || '-' },
          { key: 'actions', header: 'Actions', render: (row: Record<string, unknown>) => <VideoActions videoId={row.id as string} /> },
        ]}
      />
    </>
  );
}
