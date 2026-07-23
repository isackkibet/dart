import { db, FieldValue } from '../firebaseAdmin';

export async function getSponsoredPolls() {
  const snap = await db
    .collection('polls')
    .where('sponsored', '==', true)
    .limit(100)
    .get();
  return snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}

export async function updateSponsoredPoll(params: {
  pollId: string;
  status: 'approved' | 'rejected' | 'configured';
  actorUserId: string;
  reason?: string;
  config?: Record<string, unknown>;
}) {
  await db.collection('polls').doc(params.pollId).update({
    sponsoredStatus: params.status,
    sponsoredConfig: params.config || {},
    reviewedBy: params.actorUserId,
    reviewReason: params.reason || '',
    reviewedAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });
  await db.collection('pollAuditLogs').add({
    pollId: params.pollId,
    action: `SPONSORED_POLL_${params.status.toUpperCase()}`,
    actorUserId: params.actorUserId,
    reason: params.reason || '',
    createdAt: FieldValue.serverTimestamp(),
  });
  return { ok: true };
}
