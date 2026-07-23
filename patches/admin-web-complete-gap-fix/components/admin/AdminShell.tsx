import Link from 'next/link';
const nav=[
 ['Dashboard','/dashboard'],['Finance','/finance'],['Payouts','/finance/payouts'],
 ['Advertiser','/advertiser'],['Polls','/polls'],['Moderation','/moderation']
];
export function AdminShell({children}:{children:React.ReactNode}) {
 return <div style={{minHeight:'100vh',display:'flex'}}>
  <aside style={{width:280,padding:24,background:'rgba(16,21,39,.92)',borderRight:'1px solid var(--border)',height:'100vh',position:'sticky',top:0}}>
   <h2>YohPal Admin</h2><p style={{color:'var(--muted)'}}>Live v2 Control Tower</p>
   <nav style={{display:'grid',gap:10,marginTop:28}}>
    {nav.map(([label,href])=><Link key={href} href={href} style={{padding:12,borderRadius:16,border:'1px solid rgba(0,217,255,.12)',color:'var(--blue)'}}>{label}</Link>)}
   </nav>
   <p style={{color:'var(--muted)',fontSize:13,marginTop:28}}>RBAC-ready. Enforce roles through Firebase admins collection.</p>
  </aside>
  <main style={{flex:1,padding:32}}>{children}</main>
 </div>
}
