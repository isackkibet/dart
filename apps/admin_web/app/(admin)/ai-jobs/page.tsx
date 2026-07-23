import { requirePageAdmin } from '@/lib/auth';
import { getAiVideoJobs } from '@/lib/repositories/aiJobsRepository';
import { DataTable } from '@/components/admin/DataTable';
import { AiJobActions } from '@/components/admin/AiJobActions';
import { LoadMoreLink } from '@/components/admin/LoadMoreLink';

export default async function AiJobsPage({
  searchParams,
}: {
  searchParams: Promise<{ status?: string; cursor?: string }>;
}) {
  await requirePageAdmin('video:write');
  const params = await searchParams;
  const page = await getAiVideoJobs({ status: params.status, cursor: params.cursor });
  const jobs = page.rows;

  return (
    <main>
      <h1>AI Video Jobs</h1>
      <DataTable
        rows={jobs}
        empty="No AI video jobs found."
        columns={[
          { key: 'videoId', header: 'Video', render: (row: any) => row.videoId || '-' },
          { key: 'type', header: 'Type', render: (row: any) => row.jobType || row.type || '-' },
          { key: 'status', header: 'Status', render: (row: any) => row.status || '-' },
          { key: 'attempts', header: 'Attempts', render: (row: any) => row.attempts || 0 },
          { key: 'actions', header: 'Actions', render: (row: any) => <AiJobActions jobId={row.id} /> },
        ]}
      />
      <LoadMoreLink basePath="/ai-jobs" nextCursor={page.nextCursor} />
    </main>
  );
}
