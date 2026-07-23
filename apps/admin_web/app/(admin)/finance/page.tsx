import { KpiCard } from '@/components/admin/KpiCard';
import { PageHeader } from '@/components/admin/PageHeader';
import { requirePageAdmin } from '@/lib/auth';
import { getFinanceMetrics } from '@/lib/repositories/adminMetrics';

export default async function FinancePage() {
  await requirePageAdmin('finance:read');
  const m = await getFinanceMetrics();
  const fields = 'walletLedger,walletBalances,pendingPayouts,pendingReconciliation,creatorEarnings,riskReviews,auditLogs'.split(',');
  return (
    <>
      <PageHeader badge="Finance" title="Finance Dashboard" description="Monetisation overview for wallet ledger, wallet balances, payouts, creator earnings, risk reviews and M-Pesa reconciliation." />
      <section className="grid grid-4">
        {fields.map((key) => <KpiCard key={key} title={key} value={(m as Record<string, number>)[key] ?? 0} />)}
      </section>
    </>
  );
}
