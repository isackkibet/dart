import { db } from '../firebaseAdmin';

export async function getLiveTips(limit = 100) {
  const snap = await db
    .collection('liveTips')
    .orderBy('createdAt', 'desc')
    .limit(limit)
    .get();
  return snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}
