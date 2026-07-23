import { db } from '../firebaseAdmin';

export async function getMultistreamSessions() {
  const snap = await db
    .collection('multistreamSessions')
    .orderBy('createdAt', 'desc')
    .limit(100)
    .get();
  return snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}

export async function getMultistreamDestinations(sessionId: string) {
  const snap = await db
    .collection('multistreamDestinations')
    .where('sessionId', '==', sessionId)
    .limit(100)
    .get();
  return snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}
