import { db } from '../firebaseAdmin';

export async function getVideoStats() {
  const snap = await db.collection('videoStats').limit(100).get();
  return snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}
