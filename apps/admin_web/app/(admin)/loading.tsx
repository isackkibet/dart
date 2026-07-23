export default function Loading() {
  return (
    <main style={{ padding: 32 }}>
      <div style={{ height: 24, width: 180, background: 'rgba(255,255,255,.08)', borderRadius: 8, marginBottom: 24 }} />
      <div className="grid grid-4">
        {[1, 2, 3, 4].map((item) => (
          <div key={item} className="card">
            <div style={{ height: 28, background: 'rgba(255,255,255,.08)', borderRadius: 8 }} />
            <div style={{ height: 14, marginTop: 12, background: 'rgba(255,255,255,.06)', borderRadius: 8 }} />
          </div>
        ))}
      </div>
    </main>
  );
}
