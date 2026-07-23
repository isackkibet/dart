import { db } from '../firebaseAdmin';

export async function getReferralAnalytics() {
  const snap = await db.collection('referrals').limit(100).get();
  return snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}

export async function getInviteFraudPatterns() {
  const snap = await db
    .collection('inviteFraudPatterns')
    .where('status', '==', 'open')
    .limit(100)
    .get();
  return snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}

export async function getContactsGrowth() {
  const snap = await db.collection('contacts').limit(100).get();
  return snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}
