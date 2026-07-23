type Column<T>={key:string;header:string;render:(row:T)=>React.ReactNode};
export function DataTable<T>({columns,rows,empty}:{columns:Column<T>[];rows:T[];empty?:string}) {
 if(!rows.length) return <div className="card" style={{color:'var(--muted)'}}>{empty||'No records found.'}</div>;
 return <div className="card" style={{overflowX:'auto'}}><table className="table"><thead><tr>{columns.map(c=><th key={c.key}>{c.header}</th>)}</tr></thead><tbody>{rows.map((r,i)=><tr key={i}>{columns.map(c=><td key={c.key}>{c.render(r)}</td>)}</tr>)}</tbody></table></div>
}
