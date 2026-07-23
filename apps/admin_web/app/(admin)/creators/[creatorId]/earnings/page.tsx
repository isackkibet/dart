import { requirePageAdmin } from '@/lib/auth';
import { getCreatorEarningsDetail } from '@/lib/repositories/creatorEarningsRepository';
import { DataTable } from '@/components/admin/DataTable';

export default async function CreatorEarningsPage({
  params,
}: {
  params: Promise<{ creatorId: string }>;
}) {
  await requirePageAdmin('creator:read');
  const { creatorId } = await params;
  const data = await getCreatorEarningsDetail(creatorId);

  return (
    <main>
      <h1>Creator Earnings Detail</h1>
      <section style={{ display: 'grid', gridTemplateColumns: 'repeat(5, 1fr)', gap: 12, marginBottom: 24 }}>
        {['ads', 'gifts', 'subscriptions', 'affiliate', 'live_commerce'].map((source) => (
          <div key={source} className="card">
            <span className="badge">{source}</span>
            <h2>{(data.summary as any)[source] || 0}</h2>
          </div>
        ))}
      </section>
      <DataTable
        rows={data.rows}
        empty="No creator earnings found."
        columns={[
          { key: 'source', header: 'Source', render: (r: any) => r.source || '-' },
          { key: 'amount', header: 'Amount', render: (r: any) => `${r.currency || 'KES'} ${r.amount || 0}` },
          { key: 'status', header: 'Status', render: (r: any) => r.status || '-' },
        ]}
      />
    </main>
  );
}
