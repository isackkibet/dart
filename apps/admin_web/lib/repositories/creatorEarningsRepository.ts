import { db } from '../firebaseAdmin';

export async function getCreatorEarningsDetail(creatorId: string) {
  const snap = await db
    .collection('creatorEarnings')
    .where('creatorId', '==', creatorId)
    .limit(200)
    .get();
  const rows = snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
  const summary = rows.reduce((acc: Record<string, number>, row: any) => {
    const source = row.source || 'unknown';
    acc[source] = (acc[source] || 0) + Number(row.amount || 0);
    return acc;
  }, {});
  return { rows, summary };
}
