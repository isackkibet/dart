"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.createWalletSession = exports.yciosRenderJobProcessor = exports.yciosAgentDispatcher = exports.createYciosAgentTask = exports.enqueueYciosRenderJob = exports.duplicateYciosProject = exports.restoreYciosProject = exports.archiveYciosProject = exports.createYciosProject = exports.validatePollVote = exports.onVideoEvent = exports.onVideoCreated = exports.businessSearchIndexer = exports.liveSearchIndexer = exports.creatorSearchIndexer = exports.videoSearchIndexer = exports.searchKeywordsBackfill = exports.onFollowDeleted = exports.onFollowCreated = exports.triggerMpesaPayout = exports.earningsStatusSync = exports.walletBalanceAggregator = exports.validatedGiftPurchase = exports.giftRevenueProcessor = exports.creatorReputationScoreUpdater = exports.couponRedemptionCommissionProcessor = exports.creatorAdRevenueProcessor = exports.couponLeaderboardAggregator = exports.viewerRewardLeaderboardAggregator = exports.verifyRewardedAd = exports.rewardedAdProcessor = exports.campaignBudgetStatusUpdater = exports.adBillingProcessor = exports.generatePilotReport = exports.retryMediaWorkerJob = exports.mediaWorkerDispatch = exports.retryMultistreamDestination = exports.stopMultistreamFanOut = exports.startMultistreamFanOut = exports.createLiveKitToken = exports.processAiVideoJob = exports.validateContextIntelligence1R = exports.validatePredictiveExperience1P = exports.validateUltraLowLatencyFeed1O = exports.backfillVideoThumbnails = exports.recordPlaybackDiagnostic = exports.finalizeVideoPlaybackAssets = exports.registerHlsVideos = exports.processVideoUpload = void 0;
const admin = __importStar(require("firebase-admin"));
const firestore_1 = require("firebase-functions/v2/firestore");
const https_1 = require("firebase-functions/v2/https");
const firebaseAdmin_1 = require("./shared/firebaseAdmin");
// ── Video ──────────────────────────────────────────────────────────────────
var processVideoUpload_1 = require("./video/processVideoUpload");
Object.defineProperty(exports, "processVideoUpload", { enumerable: true, get: function () { return processVideoUpload_1.processVideoUpload; } });
var registerHlsVideos_1 = require("./video/registerHlsVideos");
Object.defineProperty(exports, "registerHlsVideos", { enumerable: true, get: function () { return registerHlsVideos_1.registerHlsVideos; } });
var finalizeVideoPlaybackAssets_1 = require("./video/finalizeVideoPlaybackAssets");
Object.defineProperty(exports, "finalizeVideoPlaybackAssets", { enumerable: true, get: function () { return finalizeVideoPlaybackAssets_1.finalizeVideoPlaybackAssets; } });
var recordPlaybackDiagnostic_1 = require("./video/recordPlaybackDiagnostic");
Object.defineProperty(exports, "recordPlaybackDiagnostic", { enumerable: true, get: function () { return recordPlaybackDiagnostic_1.recordPlaybackDiagnostic; } });
var backfillVideoThumbnails_1 = require("./video/backfillVideoThumbnails");
Object.defineProperty(exports, "backfillVideoThumbnails", { enumerable: true, get: function () { return backfillVideoThumbnails_1.backfillVideoThumbnails; } });
var phase1oValidation_1 = require("./video/phase1oValidation");
Object.defineProperty(exports, "validateUltraLowLatencyFeed1O", { enumerable: true, get: function () { return phase1oValidation_1.validateUltraLowLatencyFeed1O; } });
var validatePredictiveExperience1P_1 = require("./performance/validatePredictiveExperience1P");
Object.defineProperty(exports, "validatePredictiveExperience1P", { enumerable: true, get: function () { return validatePredictiveExperience1P_1.validatePredictiveExperience1P; } });
var validateContextIntelligence1R_1 = require("./context/validateContextIntelligence1R");
Object.defineProperty(exports, "validateContextIntelligence1R", { enumerable: true, get: function () { return validateContextIntelligence1R_1.validateContextIntelligence1R; } });
// ── AI ────────────────────────────────────────────────────────────────────
var aiJobProcessor_1 = require("./ai/aiJobProcessor");
Object.defineProperty(exports, "processAiVideoJob", { enumerable: true, get: function () { return aiJobProcessor_1.processAiVideoJob; } });
// ── Live Streaming ─────────────────────────────────────────────────────────
var liveKitToken_1 = require("./live/liveKitToken");
Object.defineProperty(exports, "createLiveKitToken", { enumerable: true, get: function () { return liveKitToken_1.createLiveKitToken; } });
// ── Multistreaming ─────────────────────────────────────────────────────────
var multistreamFanOut_1 = require("./multistream/multistreamFanOut");
Object.defineProperty(exports, "startMultistreamFanOut", { enumerable: true, get: function () { return multistreamFanOut_1.startMultistreamFanOut; } });
Object.defineProperty(exports, "stopMultistreamFanOut", { enumerable: true, get: function () { return multistreamFanOut_1.stopMultistreamFanOut; } });
Object.defineProperty(exports, "retryMultistreamDestination", { enumerable: true, get: function () { return multistreamFanOut_1.retryMultistreamDestination; } });
// ── Media Worker Dispatch (Phase MS-1) ─────────────────────────────────────
var mediaWorkerDispatch_1 = require("./modules/mediaWorkerDispatch");
Object.defineProperty(exports, "mediaWorkerDispatch", { enumerable: true, get: function () { return mediaWorkerDispatch_1.mediaWorkerDispatch; } });
Object.defineProperty(exports, "retryMediaWorkerJob", { enumerable: true, get: function () { return mediaWorkerDispatch_1.retryMediaWorkerJob; } });
// ── Pilot Operations (Phase MS-5) ──────────────────────────────────────────
var pilot_1 = require("./modules/pilot");
Object.defineProperty(exports, "generatePilotReport", { enumerable: true, get: function () { return pilot_1.generatePilotReport; } });
// ── Ad Billing (Phase 5H) ──────────────────────────────────────────────────
var adBillingProcessor_1 = require("./ads/adBillingProcessor");
Object.defineProperty(exports, "adBillingProcessor", { enumerable: true, get: function () { return adBillingProcessor_1.adBillingProcessor; } });
Object.defineProperty(exports, "campaignBudgetStatusUpdater", { enumerable: true, get: function () { return adBillingProcessor_1.campaignBudgetStatusUpdater; } });
// ── Advanced Ads Monetisation (Phase 7D) ───────────────────────────────────
var rewardedAdProcessor_1 = require("./ads/rewardedAdProcessor");
Object.defineProperty(exports, "rewardedAdProcessor", { enumerable: true, get: function () { return rewardedAdProcessor_1.rewardedAdProcessor; } });
var verifyRewardedAd_1 = require("./ads/verifyRewardedAd");
Object.defineProperty(exports, "verifyRewardedAd", { enumerable: true, get: function () { return verifyRewardedAd_1.verifyRewardedAd; } });
var adLeaderboardAggregator_1 = require("./ads/adLeaderboardAggregator");
Object.defineProperty(exports, "viewerRewardLeaderboardAggregator", { enumerable: true, get: function () { return adLeaderboardAggregator_1.viewerRewardLeaderboardAggregator; } });
Object.defineProperty(exports, "couponLeaderboardAggregator", { enumerable: true, get: function () { return adLeaderboardAggregator_1.couponLeaderboardAggregator; } });
// ── Creator Revenue Intelligence (Phase 7F) ────────────────────────────────
var creatorAdRevenueProcessor_1 = require("./ads/creatorAdRevenueProcessor");
Object.defineProperty(exports, "creatorAdRevenueProcessor", { enumerable: true, get: function () { return creatorAdRevenueProcessor_1.creatorAdRevenueProcessor; } });
var couponRedemptionCommission_1 = require("./ads/couponRedemptionCommission");
Object.defineProperty(exports, "couponRedemptionCommissionProcessor", { enumerable: true, get: function () { return couponRedemptionCommission_1.couponRedemptionCommissionProcessor; } });
var creatorReputationScore_1 = require("./ads/creatorReputationScore");
Object.defineProperty(exports, "creatorReputationScoreUpdater", { enumerable: true, get: function () { return creatorReputationScore_1.creatorReputationScoreUpdater; } });
// ── Revenue (Phase 5G) ─────────────────────────────────────────────────────
var giftRevenueProcessor_1 = require("./revenue/giftRevenueProcessor");
Object.defineProperty(exports, "giftRevenueProcessor", { enumerable: true, get: function () { return giftRevenueProcessor_1.giftRevenueProcessor; } });
var validatedGiftPurchase_1 = require("./revenue/validatedGiftPurchase");
Object.defineProperty(exports, "validatedGiftPurchase", { enumerable: true, get: function () { return validatedGiftPurchase_1.validatedGiftPurchase; } });
var walletBalanceAggregator_1 = require("./revenue/walletBalanceAggregator");
Object.defineProperty(exports, "walletBalanceAggregator", { enumerable: true, get: function () { return walletBalanceAggregator_1.walletBalanceAggregator; } });
var earningsStatusSync_1 = require("./revenue/earningsStatusSync");
Object.defineProperty(exports, "earningsStatusSync", { enumerable: true, get: function () { return earningsStatusSync_1.earningsStatusSync; } });
var mpesaPayoutTrigger_1 = require("./revenue/mpesaPayoutTrigger");
Object.defineProperty(exports, "triggerMpesaPayout", { enumerable: true, get: function () { return mpesaPayoutTrigger_1.triggerMpesaPayout; } });
// ── Social — Follow counters ───────────────────────────────────────────────
var followCounters_1 = require("./social/followCounters");
Object.defineProperty(exports, "onFollowCreated", { enumerable: true, get: function () { return followCounters_1.onFollowCreated; } });
Object.defineProperty(exports, "onFollowDeleted", { enumerable: true, get: function () { return followCounters_1.onFollowDeleted; } });
// ── Search Indexing (Phase 6E) ─────────────────────────────────────────────
var searchKeywordsBackfill_1 = require("./search/searchKeywordsBackfill");
Object.defineProperty(exports, "searchKeywordsBackfill", { enumerable: true, get: function () { return searchKeywordsBackfill_1.searchKeywordsBackfill; } });
var searchIndexers_1 = require("./search/searchIndexers");
Object.defineProperty(exports, "videoSearchIndexer", { enumerable: true, get: function () { return searchIndexers_1.videoSearchIndexer; } });
Object.defineProperty(exports, "creatorSearchIndexer", { enumerable: true, get: function () { return searchIndexers_1.creatorSearchIndexer; } });
Object.defineProperty(exports, "liveSearchIndexer", { enumerable: true, get: function () { return searchIndexers_1.liveSearchIndexer; } });
Object.defineProperty(exports, "businessSearchIndexer", { enumerable: true, get: function () { return searchIndexers_1.businessSearchIndexer; } });
// ── Video events ───────────────────────────────────────────────────────────
exports.onVideoCreated = (0, firestore_1.onDocumentCreated)('videos/{videoId}', async (event) => {
    const videoId = event.params.videoId;
    await firebaseAdmin_1.db.collection('aiVideoJobs').add({
        videoId,
        type: 'full_ai_analysis',
        status: 'queued',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
});
exports.onVideoEvent = (0, firestore_1.onDocumentCreated)('videoEvents/{eventId}', async (event) => {
    const data = event.data?.data();
    if (!data?.videoId)
        return;
    const ref = firebaseAdmin_1.db.collection('videos').doc(data.videoId);
    const field = data.type === 'video.viewed'
        ? 'views'
        : data.type === 'video.liked'
            ? 'likes'
            : data.type === 'video.shared'
                ? 'shares'
                : null;
    if (field) {
        await ref.set({ [field]: firebaseAdmin_1.FieldValue.increment(1), updatedAt: firebaseAdmin_1.FieldValue.serverTimestamp() }, { merge: true });
    }
});
exports.validatePollVote = (0, firestore_1.onDocumentCreated)('pollVotes/{voteId}', async (event) => {
    const d = event.data?.data();
    if (!d)
        return;
    const duplicate = await firebaseAdmin_1.db
        .collection('pollVotes')
        .where('pollId', '==', d.pollId)
        .where('userId', '==', d.userId)
        .get();
    if (duplicate.size > 1)
        await event.data?.ref.delete();
});
// ── YCIOS — AI Creator Intelligence OS (Phase 1) ──────────────────────────
var yciosWorkspaceApi_1 = require("./ycios/yciosWorkspaceApi");
Object.defineProperty(exports, "createYciosProject", { enumerable: true, get: function () { return yciosWorkspaceApi_1.createYciosProject; } });
Object.defineProperty(exports, "archiveYciosProject", { enumerable: true, get: function () { return yciosWorkspaceApi_1.archiveYciosProject; } });
Object.defineProperty(exports, "restoreYciosProject", { enumerable: true, get: function () { return yciosWorkspaceApi_1.restoreYciosProject; } });
Object.defineProperty(exports, "duplicateYciosProject", { enumerable: true, get: function () { return yciosWorkspaceApi_1.duplicateYciosProject; } });
Object.defineProperty(exports, "enqueueYciosRenderJob", { enumerable: true, get: function () { return yciosWorkspaceApi_1.enqueueYciosRenderJob; } });
var yciosAgentOrchestrator_1 = require("./ycios/yciosAgentOrchestrator");
Object.defineProperty(exports, "createYciosAgentTask", { enumerable: true, get: function () { return yciosAgentOrchestrator_1.createYciosAgentTask; } });
Object.defineProperty(exports, "yciosAgentDispatcher", { enumerable: true, get: function () { return yciosAgentOrchestrator_1.yciosAgentDispatcher; } });
var yciosRenderQueue_1 = require("./ycios/yciosRenderQueue");
Object.defineProperty(exports, "yciosRenderJobProcessor", { enumerable: true, get: function () { return yciosRenderQueue_1.yciosRenderJobProcessor; } });
exports.createWalletSession = (0, https_1.onRequest)(async (req, res) => {
    const { userId, purpose, amountKes } = req.body;
    const doc = await firebaseAdmin_1.db.collection('walletSessions').add({
        userId,
        purpose,
        amountKes,
        status: 'pending',
        createdAt: firebaseAdmin_1.FieldValue.serverTimestamp(),
    });
    res.json({
        sessionId: doc.id,
        checkoutUrl: `https://wallet.yohpal.com/session/${doc.id}`,
    });
});
