import { db, FieldValue } from '../firebaseAdmin';

export async function createBroadcastNotification(params: {
  title: string;
  message: string;
  audience: string;
  actorUserId: string;
}) {
  const ref = await db.collection('notificationBroadcasts').add({
    title: params.title,
    message: params.message,
    audience: params.audience,
    status: 'queued',
    createdBy: params.actorUserId,
    createdAt: FieldValue.serverTimestamp(),
  });
  await db.collection('notificationAuditLogs').add({
    broadcastId: ref.id,
    action: 'NOTIFICATION_BROADCAST_CREATED',
    actorUserId: params.actorUserId,
    audience: params.audience,
    createdAt: FieldValue.serverTimestamp(),
  });
  return { ok: true, broadcastId: ref.id };
}
