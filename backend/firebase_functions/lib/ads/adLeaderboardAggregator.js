"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.couponLeaderboardAggregator = exports.viewerRewardLeaderboardAggregator = void 0;
const firestore_1 = require("firebase-functions/v2/firestore");
const firestore_2 = require("firebase-admin/firestore");
const db = (0, firestore_2.getFirestore)();
exports.viewerRewardLeaderboardAggregator = (0, firestore_1.onDocumentCreated)({
    document: 'viewerRewards/{rewardId}',
    region: 'europe-west2',
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (event) => {
    const data = event.data?.data();
    if (!data?.userId)
        return;
    await db
        .collection('viewerAdEarningStats')
        .doc(data.userId)
        .set({
        userId: data.userId,
        username: data.username ?? 'YohPal User',
        totalEarned: firestore_2.FieldValue.increment(Number(data.amount ?? 0)),
        adsWatched: firestore_2.FieldValue.increment(1),
        updatedAt: firestore_2.FieldValue.serverTimestamp(),
    }, { merge: true });
});
exports.couponLeaderboardAggregator = (0, firestore_1.onDocumentCreated)({
    document: 'smartCoupons/{couponId}',
    region: 'europe-west2',
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (event) => {
    const data = event.data?.data();
    if (!data?.userId)
        return;
    await db
        .collection('viewerAdEarningStats')
        .doc(data.userId)
        .set({
        userId: data.userId,
        couponsUnlocked: firestore_2.FieldValue.increment(1),
        updatedAt: firestore_2.FieldValue.serverTimestamp(),
    }, { merge: true });
});
