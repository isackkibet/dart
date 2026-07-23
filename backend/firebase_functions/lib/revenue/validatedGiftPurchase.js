"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.validatedGiftPurchase = void 0;
const https_1 = require("firebase-functions/v2/https");
const firebaseAdmin_1 = require("../shared/firebaseAdmin");
const revenueAuditLogger_1 = require("./revenueAuditLogger");
/**
 * Server-side gift catalog. Must stay in sync with the tiers rendered by
 * LiveGiftPanel (apps/mobile_flutter/lib/features/live_streaming/widgets/live_gift_panel.dart).
 * Deliberately fixed — no client-supplied amount is ever trusted. The old
 * "Custom" gift (client typed an arbitrary integer straight into Firestore)
 * is retired; if a variable-amount gift is needed later it must add a
 * validated min/max here, not accept a raw client number.
 */
const GIFT_CATALOG = {
    clap: { amount: 10, currency: 'KES' },
    rose: { amount: 50, currency: 'KES' },
    fire: { amount: 100, currency: 'KES' },
    crown: { amount: 500, currency: 'KES' },
};
/**
 * Replaces the client's direct write to liveSessions/{id}/gifts/{id}.
 * Validates the gift type against a server-side catalog, checks and debits
 * the sender's walletBalances.available, then writes the gift document in
 * the same shape the client used to write it — so the existing
 * giftRevenueProcessor trigger keeps crediting the creator's earnings
 * exactly as it does today. This function only closes the missing half:
 * nothing previously verified the sender could afford the gift, or debited
 * them for sending it.
 */
exports.validatedGiftPurchase = (0, https_1.onCall)({ region: 'us-central1' }, async (request) => {
    const senderUserId = request.auth?.uid;
    if (!senderUserId) {
        throw new https_1.HttpsError('unauthenticated', 'Login required.');
    }
    const { sessionId, creatorId, giftType } = request.data ?? {};
    if (!sessionId || typeof sessionId !== 'string') {
        throw new https_1.HttpsError('invalid-argument', 'sessionId is required.');
    }
    if (!creatorId || typeof creatorId !== 'string') {
        throw new https_1.HttpsError('invalid-argument', 'creatorId is required.');
    }
    if (senderUserId === creatorId) {
        throw new https_1.HttpsError('invalid-argument', 'You cannot gift yourself.');
    }
    const catalogEntry = GIFT_CATALOG[giftType];
    if (!catalogEntry) {
        throw new https_1.HttpsError('invalid-argument', `Unknown gift type: ${giftType}`);
    }
    const { amount, currency } = catalogEntry;
    const sessionRef = firebaseAdmin_1.db.collection('liveSessions').doc(sessionId);
    const walletRef = firebaseAdmin_1.db.collection('walletBalances').doc(senderUserId);
    const giftRef = sessionRef.collection('gifts').doc();
    const txnRef = firebaseAdmin_1.db.collection('walletTransactions').doc();
    const sessionSnap = await sessionRef.get();
    if (!sessionSnap.exists) {
        throw new https_1.HttpsError('not-found', 'Live session not found.');
    }
    if (sessionSnap.data()?.creatorId !== creatorId) {
        throw new https_1.HttpsError('invalid-argument', 'creatorId does not match this session.');
    }
    let remainingBalance = 0;
    await firebaseAdmin_1.db.runTransaction(async (tx) => {
        const walletSnap = await tx.get(walletRef);
        const available = walletSnap.data()?.available ?? 0;
        if (available < amount) {
            throw new https_1.HttpsError('failed-precondition', `Insufficient wallet balance: available KES ${available}, gift costs KES ${amount}.`);
        }
        remainingBalance = available - amount;
        tx.set(walletRef, {
            userId: senderUserId,
            available: firebaseAdmin_1.FieldValue.increment(-amount),
            updatedAt: firebaseAdmin_1.FieldValue.serverTimestamp(),
        }, { merge: true });
        tx.set(txnRef, {
            id: txnRef.id,
            userId: senderUserId,
            type: 'gift_sent',
            amount,
            currency,
            status: 'completed',
            createdAt: firebaseAdmin_1.FieldValue.serverTimestamp(),
        });
        // Same shape LiveGiftRepository.sendGift used to write client-side.
        // giftRevenueProcessor (onDocumentCreated trigger) picks this up
        // unchanged and credits the creator's earnings.
        tx.set(giftRef, {
            id: giftRef.id,
            sessionId,
            senderUserId,
            creatorId,
            giftType,
            amount,
            currency,
            verified: true,
            createdAt: firebaseAdmin_1.FieldValue.serverTimestamp(),
        });
        // Firestore rules no longer let the client bump giftTotal directly
        // (see firestore.rules), so this function owns that side effect too.
        tx.update(sessionRef, {
            giftTotal: firebaseAdmin_1.FieldValue.increment(amount),
            updatedAt: firebaseAdmin_1.FieldValue.serverTimestamp(),
        });
        // Preserves the engagement-score event LiveGiftRepository.sendGift
        // used to write, so live engagement ranking is unaffected by the move
        // to a validated server path.
        tx.set(firebaseAdmin_1.db.collection('liveEvents').doc(), {
            sessionId,
            userId: senderUserId,
            creatorId,
            type: 'gift',
            giftType,
            amount,
            score: 15,
            createdAt: firebaseAdmin_1.FieldValue.serverTimestamp(),
        });
    });
    await (0, revenueAuditLogger_1.writeAuditLog)('gift_purchase_validated', {
        giftId: giftRef.id,
        sessionId,
        senderUserId,
        creatorId,
        giftType,
        amount,
        currency,
    });
    return {
        status: 'success',
        giftId: giftRef.id,
        amount,
        currency,
        remainingBalance,
    };
});
