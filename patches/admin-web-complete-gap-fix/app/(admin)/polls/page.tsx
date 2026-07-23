import { KpiCard } from '@/components/admin/KpiCard';
import { PageHeader } from '@/components/admin/PageHeader';
import { getPollMetrics } from '@/lib/repositories/adminMetrics';
export default async function Page(){
 const m=await getPollMetrics();
 const fields='polls,activePolls,fraudHolds,sponsoredPolls'.split(',');
 return <><PageHeader badge="Step 2.6" title="Infinity Polls Analytics" description="Vote velocity, sponsored poll performance, demographic breakdowns and fraud holds." />
 <section className="grid grid-4">{fields.map((key)=><KpiCard key={key} title={key} value={(m as any)[key] ?? 0} />)}</section></>
}
