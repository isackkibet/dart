import { db, FieldValue } from '../firebaseAdmin';
import { paginateQuery } from '../pagination';

export async function getReportedChatMessages(cursor?: string) {
  return paginateQuery(
    db.collection('chatMessages').where('reportStatus', '==', 'reported'),
    cursor,
  );
}

export async function hideChatMessage(params: {
  messageId: string;
  actorUserId: string;
  reason?: string;
}) {
  await db.collection('chatMessages').doc(params.messageId).update({
    visibility: 'hidden',
    moderationStatus: 'hidden',
    hiddenBy: params.actorUserId,
    hiddenReason: params.reason || '',
    hiddenAt: FieldValue.serverTimestamp(),
  });
  await db.collection('chatAuditLogs').add({
    messageId: params.messageId,
    action: 'CHAT_MESSAGE_HIDDEN',
    actorUserId: params.actorUserId,
    reason: params.reason || '',
    createdAt: FieldValue.serverTimestamp(),
  });
  return { ok: true };
}

export async function warnChatUser(params: {
  userId: string;
  actorUserId: string;
  reason?: string;
}) {
  await db.collection('userWarnings').add({
    userId: params.userId,
    warningType: 'chat_policy_violation',
    reason: params.reason || '',
    issuedBy: params.actorUserId,
    createdAt: FieldValue.serverTimestamp(),
  });
  await db.collection('notifications').add({
    userId: params.userId,
    type: 'CHAT_WARNING',
    title: 'Chat Warning',
    message: params.reason || 'Your chat activity violated YohPal policy.',
    read: false,
    createdAt: FieldValue.serverTimestamp(),
  });
  return { ok: true };
}
