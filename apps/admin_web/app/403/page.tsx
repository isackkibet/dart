import Link from 'next/link';

export default function ForbiddenPage() {
  return (
    <main className="center-page">
      <section className="card">
        <span className="badge danger">403</span>
        <h1>Access Forbidden</h1>
        <p>You do not have permission to access this admin section.</p>
        <Link href="/dashboard" className="btn">
          Return to Dashboard
        </Link>
      </section>
    </main>
  );
}
