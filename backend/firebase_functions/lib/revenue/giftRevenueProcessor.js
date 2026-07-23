"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.giftRevenueProcessor = void 0;
const firestore_1 = require("firebase-functions/v2/firestore");
const firebaseAdmin_1 = require("../shared/firebaseAdmin");
const revenueAuditLogger_1 = require("./revenueAuditLogger");
exports.giftRevenueProcessor = (0, firestore_1.onDocumentCreated)('liveSessions/{sessionId}/gifts/{giftId}', async (event) => {
    const { sessionId, giftId } = event.params;
    const gift = event.data?.data();
    if (!gift)
        return;
    const creatorId = gift.creatorId;
    const senderUserId = gift.senderUserId;
    const amount = gift.amount;
    const currency = gift.currency ?? 'KES';
    const giftType = gift.giftType;
    if (!creatorId || !amount || amount <= 0)
        return;
    // Idempotency lock — revenueProcessedGifts/{giftId} acts as a processing
    // guard. Firestore triggers have at-least-once delivery; the transaction
    // below makes gift crediting exactly-once.
    const lockRef = firebaseAdmin_1.db.collection('revenueProcessedGifts').doc(giftId);
    let alreadyProcessed = false;
    await firebaseAdmin_1.db.runTransaction(async (tx) => {
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
            processedAt: firebaseAdmin_1.FieldValue.serverTimestamp(),
        });
        // Create creatorEarnings record (status: pending — awaits manual approval)
        const earningRef = firebaseAdmin_1.db.collection('creatorEarnings').doc();
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
            createdAt: firebaseAdmin_1.FieldValue.serverTimestamp(),
            updatedAt: firebaseAdmin_1.FieldValue.serverTimestamp(),
        });
        // Write monetisationEvent for analytics/audit trail
        const eventRef = firebaseAdmin_1.db.collection('monetisationEvents').doc();
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
            createdAt: firebaseAdmin_1.FieldValue.serverTimestamp(),
        });
    });
    if (alreadyProcessed)
        return;
    await (0, revenueAuditLogger_1.writeAuditLog)('gift_credited', {
        giftId,
        sessionId,
        creatorId,
        senderUserId: senderUserId ?? null,
        amount,
        currency,
    });
});
