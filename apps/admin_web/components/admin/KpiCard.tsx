export function KpiCard({title,value,caption}:{title:string;value:string|number;caption?:string}) {
 return <div className="card"><div style={{fontSize:30,fontWeight:900}}>{value}</div><div style={{marginTop:8,fontWeight:700}}>{title}</div>{caption?<div style={{marginTop:6,color:'var(--muted)',fontSize:13}}>{caption}</div>:null}</div>
}
