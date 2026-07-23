import { db } from '../firebaseAdmin';

export async function getAdRevenueTimeseries() {
  const snap = await db.collection('adRevenueShare').orderBy('createdAt', 'desc').limit(100).get();
  return snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}

export async function getPollAnalytics() {
  const snap = await db.collection('pollVotes').limit(100).get();
  return snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}

export async function getAiProcessingAnalytics() {
  const snap = await db.collection('aiJobLogs').orderBy('createdAt', 'desc').limit(100).get();
  return snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}
