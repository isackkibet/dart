import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';

const db = getFirestore();

export const viewerRewardLeaderboardAggregator = onDocumentCreated(
  {
    document: 'viewerRewards/{rewardId}',
    region: 'europe-west2',
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (event) => {
    const data = event.data?.data();
    if (!data?.userId) return;

    await db
      .collection('viewerAdEarningStats')
      .doc(data.userId as string)
      .set(
        {
          userId: data.userId,
          username: data.username ?? 'YohPal User',
          totalEarned: FieldValue.increment(Number(data.amount ?? 0)),
          adsWatched: FieldValue.increment(1),
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
  },
);

export const couponLeaderboardAggregator = onDocumentCreated(
  {
    document: 'smartCoupons/{couponId}',
    region: 'europe-west2',
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (event) => {
    const data = event.data?.data();
    if (!data?.userId) return;

    await db
      .collection('viewerAdEarningStats')
      .doc(data.userId as string)
      .set(
        {
          userId: data.userId,
          couponsUnlocked: FieldValue.increment(1),
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
  },
);
