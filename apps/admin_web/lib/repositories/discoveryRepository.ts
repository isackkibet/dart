import { db, FieldValue } from '../firebaseAdmin';

export async function getFeaturedContent() {
  const snap = await db.collection('featuredContent').limit(100).get();
  return snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}

export async function updateFeaturedContent(params: {
  id: string;
  status: 'approved' | 'removed';
  actorUserId: string;
  reason?: string;
}) {
  await db.collection('featuredContent').doc(params.id).update({
    status: params.status,
    reviewedBy: params.actorUserId,
    reviewReason: params.reason || '',
    updatedAt: FieldValue.serverTimestamp(),
  });
  return { ok: true };
}

export async function getTrendingTopics() {
  const snap = await db.collection('trendingTopics').limit(100).get();
  return snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}

export async function getSearchLogs() {
  const snap = await db
    .collection('searchLogs')
    .orderBy('createdAt', 'desc')
    .limit(100)
    .get();
  return snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}

export async function getBlockedSearchTerms() {
  const snap = await db.collection('blockedSearchTerms').limit(100).get();
  return snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}
