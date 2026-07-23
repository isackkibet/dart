import { KpiCard } from '@/components/admin/KpiCard';
import { PageHeader } from '@/components/admin/PageHeader';
import { getDashboardMetrics } from '@/lib/repositories/adminMetrics';
export default async function Page(){
 const m=await getDashboardMetrics();
 const fields='videos,liveSessions,creators,adCampaigns,pendingPayouts,moderationQueue,activePolls'.split(',');
 return <><PageHeader badge="Step 2.1" title="Admin Dashboard" description="Top-level overview with Finance, Creator Earnings, Ads, Poll Analytics, Moderation and Live Sessions." />
 <section className="grid grid-4">{fields.map((key)=><KpiCard key={key} title={key} value={(m as any)[key] ?? 0} />)}</section></>
}
