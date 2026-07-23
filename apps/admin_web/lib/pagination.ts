export function encodeCursor(value: unknown) {
  if (!value) return undefined;
  const v = value as any;
  const normalized = v?.toDate ? v.toDate().toISOString() : String(value);
  return Buffer.from(normalized).toString('base64');
}

export function decodeCursor(cursor?: string) {
  if (!cursor) return undefined;
  return new Date(Buffer.from(cursor, 'base64').toString('utf8'));
}

export async function paginateQuery(
  query: FirebaseFirestore.Query,
  cursor?: string,
  limit = 50,
) {
  let q = query.orderBy('createdAt', 'desc').limit(limit);
  const decoded = decodeCursor(cursor);
  if (decoded) q = q.startAfter(decoded);
  const snap = await q.get();
  const rows = snap.docs.map((doc) => ({ id: doc.id, ...doc.data() } as Record<string, any>));
  const last = snap.docs[snap.docs.length - 1];
  return {
    rows,
    nextCursor: last ? encodeCursor(last.get('createdAt')) : undefined,
  };
}
