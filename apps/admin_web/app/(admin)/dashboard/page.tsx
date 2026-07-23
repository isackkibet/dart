import { KpiCard } from '@/components/admin/KpiCard';
import { PageHeader } from '@/components/admin/PageHeader';
import { requirePageAdmin } from '@/lib/auth';
import { getDashboardMetrics } from '@/lib/repositories/adminMetrics';

export default async function DashboardPage() {
  await requirePageAdmin('dashboard:read');
  const m = await getDashboardMetrics();
  const fields = 'videos,liveSessions,creators,adCampaigns,pendingPayouts,moderationQueue,activePolls'.split(',');
  return (
    <>
      <PageHeader badge="Dashboard" title="Admin Dashboard" description="Top-level overview with Finance, Creator Earnings, Ads, Poll Analytics, Moderation and Live Sessions." />
      <section className="grid grid-4">
        {fields.map((key) => <KpiCard key={key} title={key} value={(m as Record<string, number>)[key] ?? 0} />)}
      </section>
    </>
  );
}
