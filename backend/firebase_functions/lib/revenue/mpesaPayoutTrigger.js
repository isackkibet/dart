"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.triggerMpesaPayout = void 0;
const https_1 = require("firebase-functions/v2/https");
const firebaseAdmin_1 = require("../shared/firebaseAdmin");
const revenueAuditLogger_1 = require("./revenueAuditLogger");
const MIN_PAYOUT_KES = 100;
exports.triggerMpesaPayout = (0, https_1.onCall)(async (request) => {
    const uid = request.auth?.uid;
    if (!uid)
        throw new https_1.HttpsError('unauthenticated', 'Must be signed in');
    const { amountKes, phoneNumber } = request.data;
    if (!amountKes || amountKes < MIN_PAYOUT_KES) {
        throw new https_1.HttpsError('invalid-argument', `Minimum payout is KES ${MIN_PAYOUT_KES}`);
    }
    if (!phoneNumber || !/^\+2547\d{8}$/.test(phoneNumber)) {
        throw new https_1.HttpsError('invalid-argument', 'phoneNumber must be a valid Kenyan M-Pesa number (+2547XXXXXXXX)');
    }
    // Check wallet has sufficient approved balance.
    // NOTE: this previously read/wrote a `wallets/{uid}` collection that
    // nothing else in the codebase ever populates — walletBalanceAggregator
    // and earningsStatusSync both write `walletBalances/{uid}`, and that is
    // what the Flutter WalletRepository reads. Reading `wallets` here made
    // `available` permanently 0 for every user, so every payout request
    // failed with "insufficient balance" regardless of real balance. Fixed
    // to read/write the same collection the rest of the revenue pipeline
    // uses.
    const walletRef = firebaseAdmin_1.db.collection('walletBalances').doc(uid);
    const walletSnap = await walletRef.get();
    const wallet = walletSnap.data();
    const available = wallet?.available ?? 0;
    if (available < amountKes) {
        throw new https_1.HttpsError('failed-precondition', `Insufficient balance: available KES ${available}, requested KES ${amountKes}`);
    }
    // Idempotency: create payout doc and reserve funds atomically
    const payoutRef = firebaseAdmin_1.db.collection('payouts').doc();
    await firebaseAdmin_1.db.runTransaction(async (tx) => {
        const freshWallet = await tx.get(walletRef);
        const freshAvailable = freshWallet.data()?.available ?? 0;
        if (freshAvailable < amountKes) {
            throw new https_1.HttpsError('failed-precondition', 'Insufficient balance (re-checked)');
        }
        tx.set(payoutRef, {
            userId: uid,
            amountKes,
            phoneNumber,
            status: 'queued',
            provider: 'mpesa',
            createdAt: firebaseAdmin_1.FieldValue.serverTimestamp(),
            updatedAt: firebaseAdmin_1.FieldValue.serverTimestamp(),
        });
        tx.set(walletRef, {
            available: firebaseAdmin_1.FieldValue.increment(-amountKes),
            reserved: firebaseAdmin_1.FieldValue.increment(amountKes),
            updatedAt: firebaseAdmin_1.FieldValue.serverTimestamp(),
        }, { merge: true });
    });
    await (0, revenueAuditLogger_1.writeAuditLog)('payout_queued', {
        userId: uid,
        amountKes,
        payoutId: payoutRef.id,
        provider: 'mpesa',
    });
    return { payoutId: payoutRef.id, status: 'queued' };
});
