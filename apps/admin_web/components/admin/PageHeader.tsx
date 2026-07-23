export function PageHeader({title,description,badge}:{title:string;description:string;badge?:string}) {
 return <header style={{marginBottom:24}}>{badge?<span className="badge">{badge}</span>:null}<h1 style={{fontSize:34,margin:'14px 0 8px'}}>{title}</h1><p style={{color:'var(--muted)',maxWidth:880,lineHeight:1.6}}>{description}</p></header>
}
