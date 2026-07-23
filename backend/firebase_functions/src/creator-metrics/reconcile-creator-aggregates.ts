import { getFirestore } from "firebase-admin/firestore";
import { onSchedule } from "firebase-functions/v2/scheduler";

const db = getFirestore();

export const reconcileCreatorAggregates = onSchedule(
  "every 24 hours",
  async () => {
    const creatorsSnap = await db.collection("users").limit(200).get();

    for (const creatorDoc of creatorsSnap.docs) {
      const creatorId = creatorDoc.id;

      const videosSnap = await db
        .collection("videos")
        .where("ownerId", "==", creatorId)
        .get();

      let totalViews = 0;
      let totalLikes = 0;
      let totalShares = 0;
      let totalGifts = 0;
      let totalComments = 0;
      const totalVideos = videosSnap.size;

      for (const vDoc of videosSnap.docs) {
        const eng = await db
          .collection("videoEngagement")
          .doc(vDoc.id)
          .get();
        const d = eng.data() ?? {};
        totalViews += (d["views"] as number) ?? 0;
        totalLikes += (d["likes"] as number) ?? 0;
        totalShares += (d["shares"] as number) ?? 0;
        totalGifts += (d["gifts"] as number) ?? 0;
        totalComments += (d["comments"] as number) ?? 0;
      }

      const followersSnap = await db
        .collection("follows")
        .where("creatorId", "==", creatorId)
        .count()
        .get();
      const followerCount = followersSnap.data().count;

      await db.collection("creatorMetrics").doc(creatorId).set(
        {
          totalVideos,
          totalViews,
          totalLikes,
          totalShares,
          totalGifts,
          totalComments,
          followerCount,
          reconciledAt: new Date().toISOString(),
        },
        { merge: true }
      );
    }

    console.log(`Reconciled creator aggregates for ${creatorsSnap.size} creators.`);
  }
);
