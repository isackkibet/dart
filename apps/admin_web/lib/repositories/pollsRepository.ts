import { db, FieldValue } from '../firebaseAdmin';
import { paginateQuery } from '../pagination';

export async function getPolls(params?: { status?: string; cursor?: string }) {
  let query: FirebaseFirestore.Query = db.collection('polls');
  if (params?.status) {
    query = query.where('status', '==', params.status);
  }
  return paginateQuery(query, params?.cursor);
}

export async function updatePollStatus(params: {
  pollId: string;
  status: 'closed' | 'deleted';
  actorUserId: string;
  reason?: string;
}) {
  await db.collection('polls').doc(params.pollId).update({
    status: params.status,
    reviewedBy: params.actorUserId,
    reviewReason: params.reason || '',
    updatedAt: FieldValue.serverTimestamp(),
  });
  await db.collection('pollAuditLogs').add({
    pollId: params.pollId,
    action: `POLL_${params.status.toUpperCase()}`,
    actorUserId: params.actorUserId,
    reason: params.reason || '',
    createdAt: FieldValue.serverTimestamp(),
  });
  return { ok: true };
}

export async function getHeldPollVotes() {
  const snap = await db
    .collection('pollVotes')
    .where('riskStatus', '==', 'hold')
    .limit(100)
    .get();
  return snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}

export async function updatePollVoteStatus(params: {
  voteId: string;
  status: 'approved' | 'discarded';
  actorUserId: string;
  reason?: string;
}) {
  await db.collection('pollVotes').doc(params.voteId).update({
    riskStatus: params.status,
    reviewedBy: params.actorUserId,
    reviewReason: params.reason || '',
    reviewedAt: FieldValue.serverTimestamp(),
  });
  await db.collection('pollAuditLogs').add({
    voteId: params.voteId,
    action: `POLL_VOTE_${params.status.toUpperCase()}`,
    actorUserId: params.actorUserId,
    reason: params.reason || '',
    createdAt: FieldValue.serverTimestamp(),
  });
  return { ok: true };
}
