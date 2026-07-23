import { getFirestore } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { evaluateMinorPublication } from "./evaluate-minor-publication";
import { MinorPublicationEvidence } from "./minor-safety.types";

const db = getFirestore();

export const publishVideo = onCall(async (request) => {
  const userId = request.auth?.uid;
  if (!userId) {
    throw new HttpsError("unauthenticated", "Authentication is required.");
  }

  const videoId = String(request.data?.videoId ?? "");
  if (!videoId) {
    throw new HttpsError("invalid-argument", "videoId is required.");
  }

  const videoDoc = await db.collection("videos").doc(videoId).get();
  if (!videoDoc.exists) {
    throw new HttpsError("not-found", "Video not found.");
  }

  const data = videoDoc.data()!;
  if (data["ownerId"] !== userId && data["creatorId"] !== userId) {
    throw new HttpsError("permission-denied", "Not the video owner.");
  }

  const classification = data["minorContentClassification"] ?? {};
  const evidence: MinorPublicationEvidence = {
    videoId,
    creatorId: userId,
    classificationCompleted: classification["completed"] === true,
    contentType: classification["contentType"] ?? "none",
    ageRating: classification["ageRating"] ?? "",
    containsIdentifiableMinor:
      classification["containsIdentifiableMinor"] === true,
    creatorVerificationStatus:
      classification["creatorVerificationStatus"] ?? "not_required",
    guardianConsentRequired:
      classification["guardianConsentRequired"] === true,
    guardianConsentVerified:
      classification["guardianConsentVerified"] === true,
    manualReviewRequired: classification["manualReviewRequired"] === true,
    manualReviewPassed: classification["manualReviewPassed"] === true,
  };

  const blockers = evaluateMinorPublication(evidence);
  if (blockers.length > 0) {
    throw new HttpsError("failed-precondition", blockers.join(" | "), {
      blockers,
    });
  }

  await db.collection("videos").doc(videoId).update({
    status: "published",
    publishedAt: new Date().toISOString(),
  });

  return { published: true };
});
