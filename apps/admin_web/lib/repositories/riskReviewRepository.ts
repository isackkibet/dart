import { db, FieldValue } from '../firebaseAdmin';

export async function getOpenRiskReviews() {
  const snap = await db
    .collection('riskReviews')
    .where('status', '==', 'open')
    .limit(100)
    .get();
  return snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}

export async function updateRiskReview(params: {
  id: string;
  status: 'approved' | 'escalated';
  actorUserId: string;
  reason?: string;
}) {
  const ref = db.collection('riskReviews').doc(params.id);
  await ref.update({
    status: params.status,
    reviewedBy: params.actorUserId,
    reviewReason: params.reason || '',
    reviewedAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });
  await db.collection('financeAuditLogs').add({
    action: `RISK_REVIEW_${params.status.toUpperCase()}`,
    riskReviewId: params.id,
    actorUserId: params.actorUserId,
    reason: params.reason || '',
    createdAt: FieldValue.serverTimestamp(),
  });
  return { ok: true };
}
