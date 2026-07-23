import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';

const db = getFirestore();

export const couponRedemptionCommissionProcessor = onDocumentUpdated(
  {
    document: 'smartCoupons/{couponId}',
    region: 'europe-west2',
  },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    // Only fire on the transition to redeemed — not on subsequent updates
    if (before.status === 'redeemed' || after.status !== 'redeemed') return;

    const couponId = event.params.couponId;
    const { creatorId, campaignId, advertiserId } = after as {
      creatorId?: string;
      campaignId?: string;
      advertiserId?: string;
    };

    if (!creatorId || !campaignId) return;

    const lockRef = db.collection('couponCommissionProcessed').doc(couponId);
    const campaignRef = db.collection('rewardedAdCampaigns').doc(campaignId);

    await db.runTransaction(async (tx) => {
      const lock = await tx.get(lockRef);
      if (lock.exists) return;

      const campaignDoc = await tx.get(campaignRef);
      if (!campaignDoc.exists) return;

      const campaign = campaignDoc.data()!;
      const commissionAmount = roundCurrency(
        Number(campaign.couponRedemptionCommissionAmount ?? 0),
      );

      tx.set(lockRef, {
        couponId,
        campaignId,
        creatorId,
        advertiserId: advertiserId ?? null,
        status: 'processed',
        createdAt: FieldValue.serverTimestamp(),
      });

      if (commissionAmount <= 0) return;

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
        createdAt: FieldValue.serverTimestamp(),
      });

      tx.set(
        db.collection('creatorAdEarningStats').doc(creatorId),
        {
          creatorId,
          totalAdRevenue: FieldValue.increment(commissionAmount),
          couponRedemptionCommission: FieldValue.increment(commissionAmount),
          couponsRedeemed: FieldValue.increment(1),
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );

      tx.set(db.collection('creatorRevenueAuditLogs').doc(), {
        creatorId,
        campaignId,
        couponId,
        advertiserId: advertiserId ?? null,
        action: 'coupon_redemption_commission_credited',
        amount: commissionAmount,
        createdAt: FieldValue.serverTimestamp(),
      });
    });
  },
);

function roundCurrency(value: number): number {
  return Math.round(value * 100) / 100;
}
