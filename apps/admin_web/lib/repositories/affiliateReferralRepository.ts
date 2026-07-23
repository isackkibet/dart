import { db } from '../firebaseAdmin';

export async function getReferralTracking() {
  const snap = await db.collection('referrals').limit(100).get();
  return snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}
