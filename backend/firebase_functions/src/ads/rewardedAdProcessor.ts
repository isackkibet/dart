import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { getFirestore, FieldValue, Timestamp } from 'firebase-admin/firestore';

const db = getFirestore();

// Minimum wall-clock seconds that must have elapsed between a user's
// `view_start` event and a tier-completion event for that same
// user+campaign, before a reward is credited. `watchedSeconds` in the
// event payload is a client-reported number and cannot be trusted on its
// own — this app has no ad-network SDK wired in yet, so there is no
// server-side ad-impression proof (e.g. AdMob SSV) available. Requiring
// real elapsed time between two server-stamped Firestore writes at least
// forces an attacker to spend the real wall-clock time rather than
// instantly writing a `tier_60_complete` event straight after opening the
// ad screen, which is what the app allowed before this check existed.
// This is a mitigation, not a full fix — closing this properly still
// requires integrating a real ad SDK with server-side reward verification.
const MIN_ELAPSED_GRACE_SECONDS = 3;

async function hasElapsedSinceViewStart(
  userId: string,
  campaignId: string,
  requiredSeconds: number,
): Promise<boolean> {
  const viewStartSnap = await db
    .collection('rewardedAdEvents')
    .where('userId', '==', userId)
    .where('campaignId', '==', campaignId)
    .where('type', '==', 'view_start')
    .orderBy('createdAt', 'desc')
    .limit(1)
    .get();

  if (viewStartSnap.empty) return false;

  const viewStartAt = viewStartSnap.docs[0].data().createdAt as Timestamp | undefined;
  if (!viewStartAt) return false;

  const elapsedMs = Date.now() - viewStartAt.toMillis();
  const requiredMs = (requiredSeconds - MIN_ELAPSED_GRACE_SECONDS) * 1000;
  return elapsedMs >= Math.max(requiredMs, 0);
}

export const rewardedAdProcessor = onDocumentCreated(
  {
    document: 'rewardedAdEvents/{eventId}',
    region: 'europe-west2',
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    const eventId = event.params.eventId;
    const { userId, campaignId, type } = data as {
      userId: string;
      campaignId: string;
      type: string;
    };

    if (!userId || !campaignId) return;
    // view_start itself never grants a reward — nothing to validate yet.
    if (type === 'view_start') return;

    // Key on user+campaign+type so a user earns each tier at most once per campaign,
    // regardless of how many engagement events the mobile app writes.
    const processedRef = db
      .collection('rewardedAdProcessedEvents')
      .doc(`${userId}_${campaignId}_${type}`);

    const requiredSeconds = type === 'tier_30_complete' ? 30 : type === 'tier_60_complete' ? 60 : null;
    if (requiredSeconds !== null) {
      const elapsedOk = await hasElapsedSinceViewStart(userId, campaignId, requiredSeconds);
      if (!elapsedOk) {
        await db.collection('rewardedAdAuditLogs').add({
          eventId,
          userId,
          campaignId,
          type,
          action: 'reward_rejected_insufficient_elapsed_time',
          createdAt: FieldValue.serverTimestamp(),
        });
        return;
      }
    }

    await db.runTransaction(async (tx) => {
      const processed = await tx.get(processedRef);
      if (processed.exists) return;

      const campaignRef = db.collection('rewardedAdCampaigns').doc(campaignId);
      const campaignDoc = await tx.get(campaignRef);
      if (!campaignDoc.exists) return;

      const campaign = campaignDoc.data()!;

      tx.set(processedRef, {
        eventId,
        userId,
        campaignId,
        type,
        status: 'processed',
        createdAt: FieldValue.serverTimestamp(),
      });

      if (type === 'tier_30_complete') {
        tx.set(db.collection('viewerRewards').doc(), {
          userId,
          campaignId,
          rewardTier: '30_seconds',
          rewardType: 'cash_or_points',
          amount: campaign.tierOneCashAmount ?? 0,
          currency: campaign.tierOneCurrency ?? 'KES',
          status: 'pending_web_wallet_credit',
          createdAt: FieldValue.serverTimestamp(),
        });
      }

      if (type === 'tier_60_complete') {
        const couponRef = db.collection('smartCoupons').doc();
        tx.set(couponRef, {
          id: couponRef.id,
          userId,
          advertiserId: campaign.advertiserId,
          campaignId,
          rewardTier: '60_seconds',
          couponType: campaign.couponType ?? 'discount',
          value: campaign.couponValue ?? 0,
          description: campaign.couponDescription ?? '',
          code: `YOH-${couponRef.id.substring(0, 8).toUpperCase()}`,
          status: 'active',
          createdAt: FieldValue.serverTimestamp(),
          expiresAt: null,
        });
      }

      tx.set(db.collection('rewardedAdAuditLogs').doc(), {
        eventId,
        userId,
        campaignId,
        type,
        action: 'reward_processed',
        createdAt: FieldValue.serverTimestamp(),
      });
    });
  },
);
