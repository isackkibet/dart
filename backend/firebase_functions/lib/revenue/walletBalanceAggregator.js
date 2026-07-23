"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.walletBalanceAggregator = void 0;
exports.aggregateEarnings = aggregateEarnings;
exports.recalculateWalletBalance = recalculateWalletBalance;
const firestore_1 = require("firebase-functions/v2/firestore");
const firebaseAdmin_1 = require("../shared/firebaseAdmin");
const revenueAuditLogger_1 = require("./revenueAuditLogger");
/** Pure aggregation — no I/O, fully unit-testable. */
function aggregateEarnings(earnings) {
    let pending = 0;
    let approved = 0;
    let paid = 0;
    let lifetime = 0;
    let currency = 'KES';
    for (const e of earnings) {
        const amount = e.amount || 0;
        lifetime += amount;
        if (e.currency)
            currency = e.currency;
        if (e.status === 'pending')
            pending += amount;
        else if (e.status === 'approved')
            approved += amount;
        else if (e.status === 'paid')
            paid += amount;
    }
    return { pending, approved, paid, lifetime, available: approved, currency };
}
/** Reads all earnings for a creator, aggregates, and writes walletBalances. */
async function recalculateWalletBalance(creatorId) {
    const snap = await firebaseAdmin_1.db
        .collection('creatorEarnings')
        .where('creatorId', '==', creatorId)
        .get();
    const earnings = snap.docs.map((d) => {
        const data = d.data();
        return {
            amount: data.amount || 0,
            status: data.status || 'pending',
            currency: data.currency,
        };
    });
    const totals = aggregateEarnings(earnings);
    await firebaseAdmin_1.db.collection('walletBalances').doc(creatorId).set({
        userId: creatorId,
        available: totals.available,
        pending: totals.pending,
        paid: totals.paid,
        lifetime: totals.lifetime,
        currency: totals.currency,
        lastUpdatedAt: firebaseAdmin_1.FieldValue.serverTimestamp(),
    }, { merge: true });
    await (0, revenueAuditLogger_1.writeAuditLog)('wallet_updated', {
        creatorId,
        available: totals.available,
        pending: totals.pending,
        paid: totals.paid,
        lifetime: totals.lifetime,
        currency: totals.currency,
    });
}
/** Fires on every new creatorEarnings doc to keep wallet balance current. */
exports.walletBalanceAggregator = (0, firestore_1.onDocumentCreated)('creatorEarnings/{earningId}', async (event) => {
    const earning = event.data?.data();
    if (!earning?.creatorId)
        return;
    await recalculateWalletBalance(earning.creatorId);
});
