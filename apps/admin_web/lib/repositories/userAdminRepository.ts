import { db, FieldValue } from '../firebaseAdmin';

export async function getUserProfile(userId: string) {
  const doc = await db.collection('userProfiles').doc(userId).get();
  return doc.exists ? { id: doc.id, ...doc.data() } : null;
}

export async function updateUserStatus(params: {
  userId: string;
  status: 'active' | 'suspended' | 'warned';
  actorUserId: string;
  reason?: string;
}) {
  await db.collection('userProfiles').doc(params.userId).update({
    status: params.status,
    adminReason: params.reason || '',
    updatedAt: FieldValue.serverTimestamp(),
  });
  await db.collection('userAuditLogs').add({
    userId: params.userId,
    action: `USER_${params.status.toUpperCase()}`,
    actorUserId: params.actorUserId,
    reason: params.reason || '',
    createdAt: FieldValue.serverTimestamp(),
  });
  return { ok: true };
}
