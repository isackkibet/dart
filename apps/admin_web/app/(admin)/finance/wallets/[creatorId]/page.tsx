import { requirePageAdmin } from '@/lib/auth';
import { getCreatorWalletSummary } from '@/lib/repositories/walletRepository';
import { DataTable } from '@/components/admin/DataTable';
import { PageHeader } from '@/components/admin/PageHeader';

export default async function CreatorWalletPage({
  params,
}: {
  params: Promise<{ creatorId: string }>;
}) {
  await requirePageAdmin('wallet:read');
  const { creatorId } = await params;
  const summary = await getCreatorWalletSummary(creatorId);

  return (
    <>
      <PageHeader
        badge="Finance"
        title={`Creator Wallet — ${creatorId}`}
        description="Wallet balance and full transaction ledger for this creator."
      />
      <section className="card" style={{ marginBottom: 24 }}>
        <p style={{ color: 'var(--muted)', fontSize: 12, marginBottom: 8 }}>Balance</p>
        {summary.balance ? (
          <pre style={{ fontSize: 12, color: 'var(--text)', whiteSpace: 'pre-wrap' }}>
            {JSON.stringify(summary.balance, null, 2)}
          </pre>
        ) : (
          <p style={{ color: 'var(--muted)' }}>No balance record found.</p>
        )}
      </section>
      <DataTable
        rows={summary.transactions}
        empty="No wallet transactions found."
        columns={[
          { key: 'type', header: 'Type', render: (row: Record<string, unknown>) => (row.type as string) || '-' },
          { key: 'amount', header: 'Amount', render: (row: Record<string, unknown>) => String(row.amount ?? 0) },
          { key: 'source', header: 'Source', render: (row: Record<string, unknown>) => (row.source as string) || '-' },
          { key: 'status', header: 'Status', render: (row: Record<string, unknown>) => <span className="badge">{(row.status as string) || '-'}</span> },
        ]}
      />
    </>
  );
}
