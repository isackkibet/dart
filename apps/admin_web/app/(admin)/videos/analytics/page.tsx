import { requirePageAdmin } from '@/lib/auth';
import { getVideoStats } from '@/lib/repositories/videoAnalyticsRepository';
import { DataTable } from '@/components/admin/DataTable';

export default async function VideoAnalyticsPage() {
  await requirePageAdmin('video:read');
  const rows = await getVideoStats();

  return (
    <main>
      <h1>Video Analytics</h1>
      <DataTable
        rows={rows}
        empty="No video analytics found."
        columns={[
          { key: 'video',  header: 'Video',  render: (r: any) => r.videoId || '-' },
          { key: 'views',  header: 'Views',  render: (r: any) => r.views  || 0  },
          { key: 'likes',  header: 'Likes',  render: (r: any) => r.likes  || 0  },
          { key: 'shares', header: 'Shares', render: (r: any) => r.shares || 0  },
        ]}
      />
    </main>
  );
}
