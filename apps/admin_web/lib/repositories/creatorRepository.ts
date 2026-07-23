import { db, FieldValue } from '../firebaseAdmin';
import { paginateQuery } from '../pagination';

export async function getCreators(params?: { q?: string; limit?: number; cursor?: string }) {
  let query: FirebaseFirestore.Query = db.collection('creatorProfiles');
  if (params?.q) {
    query = query.where('searchKeywords', 'array-contains', params.q.toLowerCase());
  }
  return paginateQuery(query, params?.cursor, params?.limit || 50);
}

export async function getCreatorEarnings(creatorId: string) {
  const snap = await db
    .collection('creatorEarnings')
    .where('creatorId', '==', creatorId)
    .limit(50)
    .get();
  return snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}

export async function updateCreatorStatus(params: {
  creatorId: string;
  status: 'active' | 'suspended' | 'banned';
  actorUserId: string;
  reason?: string;
}) {
  const creatorRef = db.collection('creatorProfiles').doc(params.creatorId);
  const auditRef = db.collection('creatorAuditLogs').doc();
  await db.runTransaction(async (tx) => {
    tx.update(creatorRef, {
      status: params.status,
      adminReason: params.reason || '',
      updatedAt: FieldValue.serverTimestamp(),
    });
    tx.set(auditRef, {
      creatorId: params.creatorId,
      action: `CREATOR_${params.status.toUpperCase()}`,
      actorUserId: params.actorUserId,
      reason: params.reason || '',
      createdAt: FieldValue.serverTimestamp(),
    });
  });
  return { ok: true };
}

export async function updateCreatorTrustScore(params: {
  creatorId: string;
  trustScore: number;
  actorUserId: string;
  reason?: string;
}) {
  const creatorRef = db.collection('creatorProfiles').doc(params.creatorId);
  const auditRef = db.collection('creatorAuditLogs').doc();
  await db.runTransaction(async (tx) => {
    tx.update(creatorRef, {
      trustScore: params.trustScore,
      trustScoreOverriddenBy: params.actorUserId,
      trustScoreReason: params.reason || '',
      updatedAt: FieldValue.serverTimestamp(),
    });
    tx.set(auditRef, {
      creatorId: params.creatorId,
      action: 'CREATOR_TRUST_SCORE_UPDATED',
      trustScore: params.trustScore,
      actorUserId: params.actorUserId,
      reason: params.reason || '',
      createdAt: FieldValue.serverTimestamp(),
    });
  });
  return { ok: true };
}
