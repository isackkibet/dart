import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { onDocumentWritten } from "firebase-functions/v2/firestore";

const db = getFirestore();

export const updateCreatorAggregates = onDocumentWritten(
  "videoEngagement/{videoId}",
  async (event) => {
    const videoId = event.params.videoId;

    const videoDoc = await db.collection("videos").doc(videoId).get();
    if (!videoDoc.exists) return;

    const creatorId: string = videoDoc.data()?.ownerId ?? videoDoc.data()?.creatorId ?? "";
    if (!creatorId) return;

    const before = event.data?.before?.data() ?? {};
    const after = event.data?.after?.data() ?? {};

    const deltaViews = (after["views"] ?? 0) - (before["views"] ?? 0);
    const deltaLikes = (after["likes"] ?? 0) - (before["likes"] ?? 0);
    const deltaShares = (after["shares"] ?? 0) - (before["shares"] ?? 0);
    const deltaGifts = (after["gifts"] ?? 0) - (before["gifts"] ?? 0);

    if (!deltaViews && !deltaLikes && !deltaShares && !deltaGifts) return;

    const metricsRef = db.collection("creatorMetrics").doc(creatorId);
    await metricsRef.set(
      {
        totalViews: FieldValue.increment(deltaViews),
        totalLikes: FieldValue.increment(deltaLikes),
        totalShares: FieldValue.increment(deltaShares),
        totalGifts: FieldValue.increment(deltaGifts),
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
  }
);
