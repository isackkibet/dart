import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';

const db = getFirestore();

export const creatorReputationScoreUpdater = onDocumentWritten(
  {
    document: 'creatorProfiles/{creatorId}',
    region: 'europe-west2',
  },
  async (event) => {
    const after = event.data?.after.data();
    if (!after) return; // document deleted — no score to compute

    const creatorId = event.params.creatorId;

    const contentQuality     = Number(after.contentQualityScore      ?? 50);
    const audienceRetention  = Number(after.audienceRetentionScore   ?? 50);
    const watchCompletion    = Number(after.watchCompletionScore     ?? 50);
    const communityCompliance = Number(after.communityComplianceScore ?? 80);
    const fraudScore         = Number(after.fraudScore               ?? 0);
    const businessVerified   = after.businessVerified === true ? 10 : 0;

    // Four quality signals (0–100 each × 0.2 = 0–80 total),
    // plus a +10 business-verified bonus, minus a fraud penalty (0–100 × 0.2 = 0–20).
    // Final range: 0–90 before clamp.
    const score = clamp(
      contentQuality    * 0.2 +
      audienceRetention * 0.2 +
      watchCompletion   * 0.2 +
      communityCompliance * 0.2 +
      businessVerified  -
      fraudScore        * 0.2,
    );

    await db.collection('creatorReputationScores').doc(creatorId).set(
      {
        creatorId,
        score,
        grade: gradeScore(score),
        contentQuality,
        audienceRetention,
        fraudScore,
        watchCompletion,
        communityCompliance,
        businessVerified: after.businessVerified === true,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  },
);

function clamp(value: number): number {
  return Math.max(0, Math.min(100, Math.round(value)));
}

function gradeScore(score: number): string {
  if (score >= 90) return 'elite';
  if (score >= 80) return 'diamond';
  if (score >= 70) return 'gold';
  if (score >= 60) return 'silver';
  return 'bronze';
}
