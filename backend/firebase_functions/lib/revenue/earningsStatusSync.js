"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.earningsStatusSync = void 0;
const firestore_1 = require("firebase-functions/v2/firestore");
const walletBalanceAggregator_1 = require("./walletBalanceAggregator");
const revenueAuditLogger_1 = require("./revenueAuditLogger");
/**
 * Fires whenever a creatorEarnings document is updated.
 * Only acts on status transitions (pending→approved, approved→paid, etc.)
 * and recalculates the creator's walletBalances totals.
 */
exports.earningsStatusSync = (0, firestore_1.onDocumentUpdated)('creatorEarnings/{earningId}', async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after)
        return;
    // Skip if status didn't change — avoids unnecessary recalculation
    if (before.status === after.status)
        return;
    const creatorId = after.creatorId;
    if (!creatorId)
        return;
    await (0, walletBalanceAggregator_1.recalculateWalletBalance)(creatorId);
    await (0, revenueAuditLogger_1.writeAuditLog)('earnings_status_updated', {
        earningId: event.params.earningId,
        creatorId,
        oldStatus: before.status,
        newStatus: after.status,
    });
});
