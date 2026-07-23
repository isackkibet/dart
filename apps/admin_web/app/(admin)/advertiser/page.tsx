import { KpiCard } from '@/components/admin/KpiCard';
import { PageHeader } from '@/components/admin/PageHeader';
import { requirePageAdmin } from '@/lib/auth';
import { getAdvertiserMetrics } from '@/lib/repositories/adminMetrics';

export default async function AdvertiserPage() {
  await requirePageAdmin('ads:read');
  const m = await getAdvertiserMetrics();
  const fields = 'campaigns,adRevenueShare,activeCampaigns,sponsoredPolls'.split(',');
  return (
    <>
      <PageHeader badge="Advertiser" title="Advertiser Dashboard" description="Ads KPI dashboard for campaigns, ad revenue share, active placements and sponsored polls." />
      <section className="grid grid-4">
        {fields.map((key) => <KpiCard key={key} title={key} value={(m as Record<string, number>)[key] ?? 0} />)}
      </section>
    </>
  );
}
