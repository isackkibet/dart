import { db, FieldValue } from '../firebaseAdmin';
import { paginateQuery } from '../pagination';

export async function getLiveSessions(params?: { status?: string; limit?: number; cursor?: string }) {
  let query: FirebaseFirestore.Query = db.collection('liveSessions');
  if (params?.status) {
    query = query.where('status', '==', params.status);
  }
  return paginateQuery(query, params?.cursor, params?.limit || 50);
}

export async function terminateLiveSession(params: {
  sessionId: string;
  actorUserId: string;
  reason?: string;
}) {
  const liveRef = db.collection('liveSessions').doc(params.sessionId);
  const auditRef = db.collection('liveAuditLogs').doc();
  await db.runTransaction(async (tx) => {
    tx.update(liveRef, {
      status: 'terminated',
      terminatedBy: params.actorUserId,
      terminationReason: params.reason || '',
      terminatedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    tx.set(auditRef, {
      sessionId: params.sessionId,
      action: 'LIVE_TERMINATED',
      actorUserId: params.actorUserId,
      reason: params.reason || '',
      createdAt: FieldValue.serverTimestamp(),
    });
  });
  return { ok: true };
}

export async function rotateRtmpKey(params: { sessionId: string; actorUserId: string }) {
  const newKey = `rtmp_${crypto.randomUUID()}`;
  await db.collection('liveSessions').doc(params.sessionId).update({
    rtmpStreamKey: newKey,
    rtmpKeyRotatedBy: params.actorUserId,
    rtmpKeyRotatedAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });
  await db.collection('liveAuditLogs').add({
    sessionId: params.sessionId,
    action: 'RTMP_KEY_ROTATED',
    actorUserId: params.actorUserId,
    createdAt: FieldValue.serverTimestamp(),
  });
  return { ok: true, rtmpStreamKey: newKey };
}

export async function revokeRtmpKey(params: {
  sessionId: string;
  actorUserId: string;
  reason?: string;
}) {
  await db.collection('liveSessions').doc(params.sessionId).update({
    rtmpStreamKey: FieldValue.delete(),
    rtmpKeyRevoked: true,
    rtmpKeyRevokedBy: params.actorUserId,
    rtmpKeyRevokedReason: params.reason || '',
    updatedAt: FieldValue.serverTimestamp(),
  });
  await db.collection('liveAuditLogs').add({
    sessionId: params.sessionId,
    action: 'RTMP_KEY_REVOKED',
    actorUserId: params.actorUserId,
    reason: params.reason || '',
    createdAt: FieldValue.serverTimestamp(),
  });
  return { ok: true };
}
