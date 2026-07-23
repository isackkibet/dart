import { getFirestore } from "firebase-admin/firestore";
import { onSchedule } from "firebase-functions/v2/scheduler";

const db = getFirestore();

export const reconcileEngagement = onSchedule("every 24 hours", async () => {
  const videosSnap = await db.collection("videos").limit(500).get();

  const batch = db.batch();
  let writes = 0;

  for (const videoDoc of videosSnap.docs) {
    const videoId = videoDoc.id;

    const [likesSnap, savesSnap, viewsSnap] = await Promise.all([
      db
        .collection("videoLikes")
        .where("videoId", "==", videoId)
        .count()
        .get(),
      db
        .collection("videoSaves")
        .where("videoId", "==", videoId)
        .count()
        .get(),
      db
        .collection("videoViewSessions")
        .where("videoId", "==", videoId)
        .count()
        .get(),
    ]);

    const likes = likesSnap.data().count;
    const saves = savesSnap.data().count;
    const views = viewsSnap.data().count;

    const engRef = db.collection("videoEngagement").doc(videoId);
    batch.set(
      engRef,
      { likes, saves, views, reconciledAt: new Date().toISOString() },
      { merge: true }
    );

    writes++;
    if (writes >= 400) break;
  }

  await batch.commit();
  console.log(`Reconciled engagement for ${writes} videos.`);
});
