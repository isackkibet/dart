import { db, FieldValue } from '../firebaseAdmin';

export async function updateFeaturedContentAction(params: {
  id: string;
  action: 'promoted' | 'demoted' | 'removed';
  actorUserId: string;
  reason?: string;
}) {
  await db.collection('featuredContent').doc(params.id).update({
    status: params.action,
    reviewedBy: params.actorUserId,
    reviewReason: params.reason || '',
    updatedAt: FieldValue.serverTimestamp(),
  });
  await db.collection('discoveryAuditLogs').add({
    featuredContentId: params.id,
    action: `FEATURED_CONTENT_${params.action.toUpperCase()}`,
    actorUserId: params.actorUserId,
    reason: params.reason || '',
    createdAt: FieldValue.serverTimestamp(),
  });
  return { ok: true };
}
