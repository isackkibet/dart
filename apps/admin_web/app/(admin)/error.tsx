'use client';

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <main style={{ padding: 32 }}>
      <div className="card" style={{ maxWidth: 480 }}>
        <h1 style={{ fontSize: 20, marginBottom: 8 }}>Something went wrong</h1>
        <p style={{ color: 'var(--muted)', marginBottom: 20 }}>{error.message}</p>
        <button className="btn" onClick={reset}>Retry</button>
      </div>
    </main>
  );
}
