import { db, FieldValue } from '../firebaseAdmin';
import { paginateQuery } from '../pagination';

export async function getChargebacks(cursor?: string) {
  return paginateQuery(
    db.collection('chargebacks').where('status', '==', 'open'),
    cursor,
  );
}

export async function updateChargeback(params: {
  id: string;
  status: 'approved' | 'rejected' | 'escalated';
  actorUserId: string;
  reason?: string;
}) {
  await db.collection('chargebacks').doc(params.id).update({
    status: params.status,
    reviewedBy: params.actorUserId,
    reviewReason: params.reason || '',
    reviewedAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });
  await db.collection('financeAuditLogs').add({
    action: `CHARGEBACK_${params.status.toUpperCase()}`,
    chargebackId: params.id,
    actorUserId: params.actorUserId,
    reason: params.reason || '',
    createdAt: FieldValue.serverTimestamp(),
  });
  return { ok: true };
}
