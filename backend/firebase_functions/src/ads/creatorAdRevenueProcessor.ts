import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';
import { resolveCreatorTier } from './creatorRevenueConfig';

const db = getFirestore();

export const creatorAdRevenueProcessor = onDocumentCreated(
  {
    document: 'rewardedAdEvents/{eventId}',
    region: 'europe-west2',
  },
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    if (!['tier_30_complete', 'tier_60_complete'].includes(data.type)) return;

    const { creatorId, campaignId, liveSessionId } = data as {
      creatorId?: string;
      campaignId?: string;
      liveSessionId?: string;
      type: string;
    };

    if (!creatorId || !campaignId || !liveSessionId) return;

    const lockRef = db
      .collection('creatorAdRevenueProcessedEvents')
      .doc(`${event.params.eventId}_${creatorId}`);
    const liveRef = db.collection('liveSessions').doc(liveSessionId);
    const campaignRef = db.collection('rewardedAdCampaigns').doc(campaignId);

    await db.runTransaction(async (tx) => {
      const lock = await tx.get(lockRef);
      if (lock.exists) return;

      const [liveDoc, campaignDoc] = await Promise.all([
        tx.get(liveRef),
        tx.get(campaignRef),
      ]);
      if (!liveDoc.exists || !campaignDoc.exists) return;

      const live = liveDoc.data()!;
      const campaign = campaignDoc.data()!;
      const viewerCount = Number(live.viewerCount ?? live.concurrentViewers ?? 0);
      const tier = resolveCreatorTier(viewerCount);

      tx.set(lockRef, {
        eventId: event.params.eventId,
        creatorId,
        campaignId,
        liveSessionId,
        viewerCount,
        eligible: tier !== null,
        createdAt: FieldValue.serverTimestamp(),
      });

      if (!tier) return;

      const baseAmount = Number(
        data.type === 'tier_60_complete'
          ? (campaign.creatorTierTwoRewardBase ?? campaign.creatorRewardBase ?? 0)
          : (campaign.creatorTierOneRewardBase ?? campaign.creatorRewardBase ?? 0),
      );
      const creatorAmount = roundCurrency((baseAmount * tier.creatorSharePercent) / 100);
      if (creatorAmount <= 0) return;

      const earningRef = db.collection('creatorEarnings').doc();
      tx.set(earningRef, {
        id: earningRef.id,
        creatorId,
        source: 'rewarded_ad',
        sourceId: campaignId,
        liveSessionId,
        amount: creatorAmount,
        currency: campaign.currency ?? 'KES',
        status: 'pending',
        tier: tier.tier,
        viewerCount,
        campaignId,
        rewardEventType: data.type,
        createdAt: FieldValue.serverTimestamp(),
      });

      tx.set(
        db.collection('creatorAdEarningStats').doc(creatorId),
        {
          creatorId,
          totalAdRevenue: FieldValue.increment(creatorAmount),
          rewardedAdRevenue: FieldValue.increment(creatorAmount),
          adsCompleted: FieldValue.increment(1),
          tier: tier.tier,
          lastViewerCount: viewerCount,
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );

      tx.set(db.collection('creatorRevenueAuditLogs').doc(), {
        creatorId,
        campaignId,
        liveSessionId,
        eventId: event.params.eventId,
        action: 'creator_rewarded_ad_revenue_credited',
        amount: creatorAmount,
        tier: tier.tier,
        viewerCount,
        createdAt: FieldValue.serverTimestamp(),
      });
    });
  },
);

function roundCurrency(value: number): number {
  return Math.round(value * 100) / 100;
}
