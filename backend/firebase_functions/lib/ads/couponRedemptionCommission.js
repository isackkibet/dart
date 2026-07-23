"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.couponRedemptionCommissionProcessor = void 0;
const firestore_1 = require("firebase-functions/v2/firestore");
const firestore_2 = require("firebase-admin/firestore");
const db = (0, firestore_2.getFirestore)();
exports.couponRedemptionCommissionProcessor = (0, firestore_1.onDocumentUpdated)({
    document: 'smartCoupons/{couponId}',
    region: 'europe-west2',
}, async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after)
        return;
    // Only fire on the transition to redeemed — not on subsequent updates
    if (before.status === 'redeemed' || after.status !== 'redeemed')
        return;
    const couponId = event.params.couponId;
    const { creatorId, campaignId, advertiserId } = after;
    if (!creatorId || !campaignId)
        return;
    const lockRef = db.collection('couponCommissionProcessed').doc(couponId);
    const campaignRef = db.collection('rewardedAdCampaigns').doc(campaignId);
    await db.runTransaction(async (tx) => {
        const lock = await tx.get(lockRef);
        if (lock.exists)
            return;
        const campaignDoc = await tx.get(campaignRef);
        if (!campaignDoc.exists)
            return;
        const campaign = campaignDoc.data();
        const commissionAmount = roundCurrency(Number(campaign.couponRedemptionCommissionAmount ?? 0));
        tx.set(lockRef, {
            couponId,
            campaignId,
            creatorId,
            advertiserId: advertiserId ?? null,
            status: 'processed',
            createdAt: firestore_2.FieldValue.serverTimestamp(),
        });
        if (commissionAmount <= 0)
            return;
        const earningRef = db.collection('creatorEarnings').doc();
        tx.set(earningRef, {
            id: earningRef.id,
            creatorId,
            source: 'coupon_redemption',
            sourceId: couponId,
            campaignId,
            advertiserId: advertiserId ?? null,
            amount: commissionAmount,
            currency: campaign.currency ?? 'KES',
            status: 'pending',
            createdAt: firestore_2.FieldValue.serverTimestamp(),
        });
        tx.set(db.collection('creatorAdEarningStats').doc(creatorId), {
            creatorId,
            totalAdRevenue: firestore_2.FieldValue.increment(commissionAmount),
            couponRedemptionCommission: firestore_2.FieldValue.increment(commissionAmount),
            couponsRedeemed: firestore_2.FieldValue.increment(1),
            updatedAt: firestore_2.FieldValue.serverTimestamp(),
        }, { merge: true });
        tx.set(db.collection('creatorRevenueAuditLogs').doc(), {
            creatorId,
            campaignId,
            couponId,
            advertiserId: advertiserId ?? null,
            action: 'coupon_redemption_commission_credited',
            amount: commissionAmount,
            createdAt: firestore_2.FieldValue.serverTimestamp(),
        });
    });
});
function roundCurrency(value) {
    return Math.round(value * 100) / 100;
}
