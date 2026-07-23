import Link from 'next/link';

export function LoadMoreLink({
  nextCursor,
  basePath,
}: {
  nextCursor?: string;
  basePath: string;
}) {
  if (!nextCursor) return null;
  return (
    <div style={{ marginTop: 20 }}>
      <Link href={`${basePath}?cursor=${encodeURIComponent(nextCursor)}`} className="btn secondary">
        Load More
      </Link>
    </div>
  );
}
