import { db, FieldValue } from '../firebaseAdmin';

export async function getPendingReconciliation() {
  const snap = await db
    .collection('walletReconciliation')
    .where('status', '==', 'pending')
    .limit(100)
    .get();
  return snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}

export async function resolveReconciliation(params: {
  id: string;
  action: 'approved' | 'rejected';
  actorUserId: string;
  reason?: string;
}) {
  const ref = db.collection('walletReconciliation').doc(params.id);
  await ref.update({
    status: params.action,
    resolvedBy: params.actorUserId,
    resolutionReason: params.reason || '',
    resolvedAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });
  await db.collection('financeAuditLogs').add({
    action: `RECONCILIATION_${params.action.toUpperCase()}`,
    reconciliationId: params.id,
    actorUserId: params.actorUserId,
    reason: params.reason || '',
    createdAt: FieldValue.serverTimestamp(),
  });
  return { ok: true };
}
