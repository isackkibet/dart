import { db, FieldValue } from '../firebaseAdmin';
import { sendMpesaB2C } from '../mpesaB2C';
import { paginateQuery } from '../pagination';

export type PayoutRow = {
  id: string;
  creatorId?: string;
  phoneNumber?: string;
  amount?: number;
  currency?: string;
  status?: string;
  riskScore?: number;
  mpesaB2CStatus?: string;
};

export async function getPendingPayouts(cursor?: string) {
  return paginateQuery(
    db.collection('walletPayouts').where('status', '==', 'pending'),
    cursor,
  );
}

export async function getWalletLedger(limit = 50) {
  try {
    const s = await db.collection('walletLedger').limit(limit).get();
    return s.docs.map(d => ({ id: d.id, ...d.data() }));
  } catch { return []; }
}

export async function approvePayout(params: {
  payoutId: string;
  actorUserId: string;
  reason?: string;
}) {
  const payoutRef = db.collection('walletPayouts').doc(params.payoutId);
  const auditRef = db.collection('financeAuditLogs').doc();

  const payoutDoc = await payoutRef.get();
  if (!payoutDoc.exists) throw new Error('Payout not found');
  const payout = payoutDoc.data() || {};

  const b2c = await sendMpesaB2C({
    payoutId: params.payoutId,
    phoneNumber: payout.phoneNumber || '',
    amount: Number(payout.amount || 0),
    remarks: params.reason || 'YohPal payout',
    occasion: 'YohPal Creator Payout',
  });

  await db.runTransaction(async (tx) => {
    tx.update(payoutRef, {
      status: 'disbursement_submitted',
      reviewedBy: params.actorUserId,
      reviewedAt: FieldValue.serverTimestamp(),
      reviewReason: params.reason || '',
      mpesaB2CStatus: b2c.status,
      mpesaConversationId: b2c.conversationId,
      mpesaOriginatorConversationId: b2c.originatorConversationId,
      updatedAt: FieldValue.serverTimestamp(),
    });
    tx.set(auditRef, {
      action: 'PAYOUT_APPROVED_B2C_SUBMITTED',
      payoutId: params.payoutId,
      actorUserId: params.actorUserId,
      reason: params.reason || '',
      mpesaB2CStatus: b2c.status,
      mpesaConversationId: b2c.conversationId,
      createdAt: FieldValue.serverTimestamp(),
    });
  });

  return { ok: true, mpesaB2CStatus: b2c.status };
}

export async function updatePayoutStatus(params: {
  payoutId: string;
  status: 'held' | 'rejected';
  actorUserId: string;
  reason?: string;
}) {
  const payoutRef = db.collection('walletPayouts').doc(params.payoutId);
  const auditRef = db.collection('financeAuditLogs').doc();

  await db.runTransaction(async (tx) => {
    tx.update(payoutRef, {
      status: params.status,
      reviewedBy: params.actorUserId,
      reviewedAt: FieldValue.serverTimestamp(),
      reviewReason: params.reason || '',
      updatedAt: FieldValue.serverTimestamp(),
    });
    tx.set(auditRef, {
      action: `PAYOUT_${params.status.toUpperCase()}`,
      payoutId: params.payoutId,
      actorUserId: params.actorUserId,
      reason: params.reason || '',
      createdAt: FieldValue.serverTimestamp(),
    });
  });

  return { ok: true };
}
