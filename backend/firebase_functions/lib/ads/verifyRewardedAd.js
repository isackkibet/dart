"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.verifyRewardedAd = void 0;
const https_1 = require("firebase-functions/v2/https");
const firebaseAdmin_1 = require("../shared/firebaseAdmin");
/**
 * The mobile client currently decides "did I earn this reward" from its own
 * local Timer, which is trivially spoofable and gives the user no real
 * confirmation that a reward was actually credited server-side.
 *
 * This does not replace real ad-network verification (e.g. AdMob SSV) — the
 * app has no ad SDK wired in yet, so there is no third-party proof of ad
 * playback available to check against. What it does do: let the client ask
 * the server "was this specific tier actually processed and credited",
 * backed by the same `rewardedAdProcessedEvents` idempotency record
 * rewardedAdProcessor writes, so the UI can show a real "reward confirmed"
 * state instead of assuming its own timer was honest.
 */
exports.verifyRewardedAd = (0, https_1.onCall)({ region: 'us-central1' }, async (request) => {
    const userId = request.auth?.uid;
    if (!userId) {
        throw new https_1.HttpsError('unauthenticated', 'Login required.');
    }
    const { campaignId, type } = request.data ?? {};
    if (!campaignId || (type !== 'tier_30_complete' && type !== 'tier_60_complete')) {
        throw new https_1.HttpsError('invalid-argument', 'campaignId and a valid tier type are required.');
    }
    const processedSnap = await firebaseAdmin_1.db
        .collection('rewardedAdProcessedEvents')
        .doc(`${userId}_${campaignId}_${type}`)
        .get();
    if (!processedSnap.exists) {
        return {
            verified: false,
            reason: 'Reward has not been credited yet — it may still be processing, or was rejected.',
        };
    }
    return { verified: true };
});
