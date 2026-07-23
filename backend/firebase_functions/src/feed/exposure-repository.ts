import * as admin from "firebase-admin";
import type { ViewerVideoExposure } from "./viewer-video-exposure";

const db = admin.firestore();

export async function recordVideoExposure(
  exposure: ViewerVideoExposure
): Promise<void> {
  const docRef = db
    .collection("viewerExposure")
    .doc(exposure.viewerId)
    .collection("videos")
    .doc(exposure.videoId);

  await docRef.set(
    {
      ...exposure,
      lastShownAt: exposure.lastShownAt,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );
}

export async function loadExposure(
  viewerId: string,
  videoId: string
): Promise<ViewerVideoExposure | undefined> {
  const snap = await db
    .collection("viewerExposure")
    .doc(viewerId)
    .collection("videos")
    .doc(videoId)
    .get();

  if (!snap.exists) return undefined;
  return snap.data() as ViewerVideoExposure;
}

export async function loadExcludedVideoIds(
  viewerId: string
): Promise<string[]> {
  const snap = await db
    .collection("viewerExposure")
    .doc(viewerId)
    .collection("videos")
    .where("automaticFeedEligible", "==", false)
    .select()
    .get();

  return snap.docs.map((d) => d.id);
}
