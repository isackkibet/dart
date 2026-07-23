import { db, FieldValue } from '../firebaseAdmin';
import { paginateQuery } from '../pagination';

export async function getAffiliatePrograms() {
  const snap = await db
    .collection('affiliatePrograms')
    .orderBy('createdAt', 'desc')
    .limit(100)
    .get();
  return snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}

export async function getAffiliateEarnings(params?: { status?: string; cursor?: string }) {
  let query: FirebaseFirestore.Query = db.collection('affiliateEarnings');
  if (params?.status) {
    query = query.where('status', '==', params.status);
  }
  return paginateQuery(query, params?.cursor);
}

export async function updateAffiliateCommission(params: {
  earningId: string;
  status: 'approved' | 'discarded';
  actorUserId: string;
  reason?: string;
}) {
  await db.collection('affiliateEarnings').doc(params.earningId).update({
    status: params.status,
    reviewedBy: params.actorUserId,
    reviewReason: params.reason || '',
    reviewedAt: FieldValue.serverTimestamp(),
  });
  await db.collection('affiliateAuditLogs').add({
    earningId: params.earningId,
    action: `AFFILIATE_COMMISSION_${params.status.toUpperCase()}`,
    actorUserId: params.actorUserId,
    reason: params.reason || '',
    createdAt: FieldValue.serverTimestamp(),
  });
  return { ok: true };
}
