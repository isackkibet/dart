import { requirePageAdmin } from '@/lib/auth';
import { getAdCampaigns } from '@/lib/repositories/adsRepository';
import { DataTable } from '@/components/admin/DataTable';
import { AdCampaignActions } from '@/components/admin/AdCampaignActions';
import { LoadMoreLink } from '@/components/admin/LoadMoreLink';

export default async function CampaignsPage({
  searchParams,
}: {
  searchParams: Promise<{ status?: string; cursor?: string }>;
}) {
  await requirePageAdmin('ads:read');
  const params = await searchParams;
  const page = await getAdCampaigns({ status: params.status, cursor: params.cursor });
  const campaigns = page.rows;

  return (
    <main>
      <h1>Ad Campaigns</h1>
      <form style={{ marginBottom: 20 }}>
        <select name="status" defaultValue={params.status || ''}>
          <option value="">All</option>
          <option value="pending">Pending</option>
          <option value="approved">Approved</option>
          <option value="rejected">Rejected</option>
          <option value="active">Active</option>
        </select>
        <button className="btn" style={{ marginLeft: 8 }}>Filter</button>
      </form>
      <DataTable
        rows={campaigns}
        empty="No ad campaigns found."
        columns={[
          { key: 'name', header: 'Campaign', render: (row: any) => row.name || row.title || '-' },
          { key: 'advertiser', header: 'Advertiser', render: (row: any) => row.advertiserId || '-' },
          { key: 'budget', header: 'Budget', render: (row: any) => `${row.currency || 'KES'} ${row.budget || 0}` },
          { key: 'status', header: 'Status', render: (row: any) => row.status || '-' },
          { key: 'actions', header: 'Actions', render: (row: any) => <AdCampaignActions campaignId={row.id} /> },
        ]}
      />
      <LoadMoreLink basePath="/advertiser/campaigns" nextCursor={page.nextCursor} />
    </main>
  );
}
