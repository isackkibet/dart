import * as admin from 'firebase-admin';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { onRequest } from 'firebase-functions/v2/https';
import { db, FieldValue } from './shared/firebaseAdmin';

// ── Video ──────────────────────────────────────────────────────────────────
export { processVideoUpload }           from './video/processVideoUpload';
export { registerHlsVideos }            from './video/registerHlsVideos';
export { finalizeVideoPlaybackAssets }  from './video/finalizeVideoPlaybackAssets';
export { recordPlaybackDiagnostic }     from './video/recordPlaybackDiagnostic';
export { backfillVideoThumbnails }        from './video/backfillVideoThumbnails';
export { validateUltraLowLatencyFeed1O }  from './video/phase1oValidation';
export { validatePredictiveExperience1P } from './performance/validatePredictiveExperience1P';
export { validateContextIntelligence1R }  from './context/validateContextIntelligence1R';

// ── AI ────────────────────────────────────────────────────────────────────
export { processAiVideoJob } from './ai/aiJobProcessor';

// ── Live Streaming ─────────────────────────────────────────────────────────
export { createLiveKitToken } from './live/liveKitToken';

// ── Multistreaming ─────────────────────────────────────────────────────────
export {
  startMultistreamFanOut,
  stopMultistreamFanOut,
  retryMultistreamDestination,
} from './multistream/multistreamFanOut';

// ── Media Worker Dispatch (Phase MS-1) ─────────────────────────────────────
export {
  mediaWorkerDispatch,
  retryMediaWorkerJob,
} from './modules/mediaWorkerDispatch';

// ── Pilot Operations (Phase MS-5) ──────────────────────────────────────────
export {
  generatePilotReport,
} from './modules/pilot';

// ── Ad Billing (Phase 5H) ──────────────────────────────────────────────────
export {
  adBillingProcessor,
  campaignBudgetStatusUpdater,
} from './ads/adBillingProcessor';

// ── Advanced Ads Monetisation (Phase 7D) ───────────────────────────────────
export { rewardedAdProcessor } from './ads/rewardedAdProcessor';
export { verifyRewardedAd } from './ads/verifyRewardedAd';
export {
  viewerRewardLeaderboardAggregator,
  couponLeaderboardAggregator,
} from './ads/adLeaderboardAggregator';

// ── Creator Revenue Intelligence (Phase 7F) ────────────────────────────────
export { creatorAdRevenueProcessor } from './ads/creatorAdRevenueProcessor';
export { couponRedemptionCommissionProcessor } from './ads/couponRedemptionCommission';
export { creatorReputationScoreUpdater } from './ads/creatorReputationScore';

// ── Revenue (Phase 5G) ─────────────────────────────────────────────────────
export { giftRevenueProcessor } from './revenue/giftRevenueProcessor';
export { validatedGiftPurchase } from './revenue/validatedGiftPurchase';
export { walletBalanceAggregator } from './revenue/walletBalanceAggregator';
export { earningsStatusSync } from './revenue/earningsStatusSync';
export { triggerMpesaPayout } from './revenue/mpesaPayoutTrigger';

// ── Social — Follow counters ───────────────────────────────────────────────
export { onFollowCreated, onFollowDeleted } from './social/followCounters';

// ── Search Indexing (Phase 6E) ─────────────────────────────────────────────
export { searchKeywordsBackfill } from './search/searchKeywordsBackfill';
export {
  videoSearchIndexer,
  creatorSearchIndexer,
  liveSearchIndexer,
  businessSearchIndexer,
} from './search/searchIndexers';

// ── Video events ───────────────────────────────────────────────────────────
export const onVideoCreated = onDocumentCreated('videos/{videoId}', async (event) => {
  const videoId = event.params.videoId;
  await db.collection('aiVideoJobs').add({
    videoId,
    type: 'full_ai_analysis',
    status: 'queued',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
});

export const onVideoEvent = onDocumentCreated('videoEvents/{eventId}', async (event) => {
  const data = event.data?.data();
  if (!data?.videoId) return;
  const ref = db.collection('videos').doc(data.videoId as string);
  const field =
    data.type === 'video.viewed'
      ? 'views'
      : data.type === 'video.liked'
        ? 'likes'
        : data.type === 'video.shared'
          ? 'shares'
          : null;
  if (field) {
    await ref.set(
      { [field]: FieldValue.increment(1), updatedAt: FieldValue.serverTimestamp() },
      { merge: true },
    );
  }
});

export const validatePollVote = onDocumentCreated('pollVotes/{voteId}', async (event) => {
  const d = event.data?.data();
  if (!d) return;
  const duplicate = await db
    .collection('pollVotes')
    .where('pollId', '==', d.pollId)
    .where('userId', '==', d.userId)
    .get();
  if (duplicate.size > 1) await event.data?.ref.delete();
});

// ── YCIOS — AI Creator Intelligence OS (Phase 1) ──────────────────────────
export {
  createYciosProject,
  archiveYciosProject,
  restoreYciosProject,
  duplicateYciosProject,
  enqueueYciosRenderJob,
} from './ycios/yciosWorkspaceApi';
export {
  createYciosAgentTask,
  yciosAgentDispatcher,
} from './ycios/yciosAgentOrchestrator';
export { yciosRenderJobProcessor } from './ycios/yciosRenderQueue';

export const createWalletSession = onRequest(async (req, res) => {
  const { userId, purpose, amountKes } = req.body as {
    userId: string;
    purpose: string;
    amountKes: number;
  };
  const doc = await db.collection('walletSessions').add({
    userId,
    purpose,
    amountKes,
    status: 'pending',
    createdAt: FieldValue.serverTimestamp(),
  });
  res.json({
    sessionId: doc.id,
    checkoutUrl: `https://wallet.yohpal.com/session/${doc.id}`,
  });
});
