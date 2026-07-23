import { db } from '../firebaseAdmin';

export async function getContacts() {
  const snap = await db.collection('contacts').limit(100).get();
  return snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}

export async function getUserProfiles() {
  const snap = await db.collection('userProfiles').limit(100).get();
  return snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}
