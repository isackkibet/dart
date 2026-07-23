import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { db, FieldValue } from '../shared/firebaseAdmin';
import { writeAuditLog } from './revenueAuditLogger';

export const giftRevenueProcessor = onDocumentCreated(
  'liveSessions/{sessionId}/gifts/{giftId}',
  async (event) => {
    const { sessionId, giftId } = event.params;
    const gift = event.data?.data();
    if (!gift) return;

    const creatorId = gift.creatorId as string | undefined;
    const senderUserId = gift.senderUserId as string | undefined;
    const amount = gift.amount as number | undefined;
    const currency = (gift.currency as string | undefined) ?? 'KES';
    const giftType = gift.giftType as string | undefined;

    if (!creatorId || !amount || amount <= 0) return;

    // Idempotency lock — revenueProcessedGifts/{giftId} acts as a processing
    // guard. Firestore triggers have at-least-once delivery; the transaction
    // below makes gift crediting exactly-once.
    const lockRef = db.collection('revenueProcessedGifts').doc(giftId);

    let alreadyProcessed = false;

    await db.runTransaction(async (tx) => {
      const lockDoc = await tx.get(lockRef);
      if (lockDoc.exists) {
        alreadyProcessed = true;
        return;
      }

      // Claim the processing lock
      tx.set(lockRef, {
        giftId,
        sessionId,
        creatorId,
        amount,
        processedAt: FieldValue.serverTimestamp(),
      });

      // Create creatorEarnings record (status: pending — awaits manual approval)
      const earningRef = db.collection('creatorEarnings').doc();
      tx.set(earningRef, {
        id: earningRef.id,
        creatorId,
        source: 'live_gift',
        sourceId: giftId,
        sessionId,
        senderUserId: senderUserId ?? null,
        amount,
        currency,
        giftType: giftType ?? null,
        status: 'pending',
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });

      // Write monetisationEvent for analytics/audit trail
      const eventRef = db.collection('monetisationEvents').doc();
      tx.set(eventRef, {
        id: eventRef.id,
        creatorId,
        type: 'gift_received',
        sourceId: giftId,
        sessionId,
        senderUserId: senderUserId ?? null,
        amount,
        currency,
        giftType: giftType ?? null,
        createdAt: FieldValue.serverTimestamp(),
      });
    });

    if (alreadyProcessed) return;

    await writeAuditLog('gift_credited', {
      giftId,
      sessionId,
      creatorId,
      senderUserId: senderUserId ?? null,
      amount,
      currency,
    });
  }
);
