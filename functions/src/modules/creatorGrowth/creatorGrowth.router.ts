import { Router } from "express";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { AuthenticatedRequest, requireAuth } from "../../core/http/requireAuth";
import { fail, ok } from "../../core/http/respond";
import { GenerateRecommendationsSchema } from "./creatorGrowth.schema";

export const creatorGrowthRouter = Router();
const db = getFirestore();

creatorGrowthRouter.get("/status", requireAuth, async (_req, res) => {
  return ok(res, {
    module: "creator_growth",
    status: "ready",
  });
});

creatorGrowthRouter.get(
  "/creators/:creatorId/score",
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    const requester = req.user?.uid;
    const creatorId = req.params.creatorId;
    if (!requester) return fail(res, 401, "missing_user", "Missing user.");
    if (requester !== creatorId && req.user?.admin !== true) {
      return fail(res, 403, "forbidden", "You cannot view this score.");
    }
    const [traffic, conversions, ledger, sessions] = await Promise.all([
      db.collection("trafficEvents").where("creatorId", "==", creatorId).limit(3000).get(),
      db.collection("conversionEvents").where("creatorId", "==", creatorId).limit(3000).get(),
      db
        .collection("ledgerEntries")
        .where("ownerType", "==", "creator")
        .where("ownerId", "==", creatorId)
        .limit(3000)
        .get(),
      db.collection("liveSessions").where("creatorId", "==", creatorId).limit(500).get(),
    ]);
    let totalRevenue = 0;
    for (const item of ledger.docs) {
      const data = item.data();
      if (data.direction === "credit") {
        totalRevenue += typeof data.amount === "number" ? data.amount : 0;
      }
    }
    const reachScore = Math.min(100, traffic.size / 20);
    const conversionScore = Math.min(100, conversions.size / 5);
    const monetisationScore = Math.min(100, totalRevenue / 100);
    const consistencyScore = Math.min(100, sessions.size * 10);
    const retentionScore = Math.min(100, conversions.size > 0 ? 45 + conversions.size : 10);
    const collaborationScore = 20;
    const viralityScore = Math.min(100, traffic.size / 10);
    const overallScore = Number(
      (
        (reachScore +
          conversionScore +
          retentionScore +
          monetisationScore +
          consistencyScore +
          collaborationScore +
          viralityScore) /
        7
      ).toFixed(2),
    );
    return ok(res, {
      creatorId,
      reachScore,
      conversionScore,
      retentionScore,
      monetisationScore,
      consistencyScore,
      collaborationScore,
      viralityScore,
      overallScore,
      updatedAt: new Date().toISOString(),
    });
  },
);

creatorGrowthRouter.get(
  "/creators/:creatorId/recommendations",
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    const requester = req.user?.uid;
    const creatorId = req.params.creatorId;
    if (!requester) return fail(res, 401, "missing_user", "Missing user.");
    if (requester !== creatorId && req.user?.admin !== true) {
      return fail(res, 403, "forbidden", "You cannot view recommendations.");
    }
    const snapshot = await db
      .collection("growthRecommendations")
      .where("creatorId", "==", creatorId)
      .orderBy("createdAt", "desc")
      .limit(50)
      .get();
    return ok(res, {
      recommendations: snapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      })),
    });
  },
);

creatorGrowthRouter.post(
  "/creators/:creatorId/recommendations/generate",
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    const requester = req.user?.uid;
    const creatorId = req.params.creatorId;
    if (!requester) return fail(res, 401, "missing_user", "Missing user.");
    if (requester !== creatorId && req.user?.admin !== true) {
      return fail(res, 403, "forbidden", "You cannot generate recommendations.");
    }
    const parsed = GenerateRecommendationsSchema.safeParse(req.body ?? {});
    if (!parsed.success) {
      return fail(
        res,
        400,
        "invalid_growth_generation_payload",
        "Invalid growth generation payload.",
        parsed.error.flatten(),
      );
    }
    const traffic = await db
      .collection("trafficEvents")
      .where("creatorId", "==", creatorId)
      .limit(1000)
      .get();
    const conversions = await db
      .collection("conversionEvents")
      .where("creatorId", "==", creatorId)
      .limit(1000)
      .get();
    const recommendations = [];
    if (traffic.size < 100) {
      recommendations.push({
        title: "Increase external teaser traffic",
        description:
          "Create platform-specific campaign links for TikTok, YouTube, Facebook, and Instagram to pull viewers back into YohPal.",
        priority: "high",
        category: "traffic",
        expectedImpact: "reach uplift",
      });
    }
    if (conversions.size < Math.max(1, traffic.size * 0.05)) {
      recommendations.push({
        title: "Improve YohPal conversion prompt",
        description:
          "Use a timed CTA overlay during high-engagement moments to move viewers from teaser platforms into YohPal.",
        priority: "high",
        category: "conversion",
        expectedImpact: "conversion lift",
      });
    }
    recommendations.push({
      title: "Run a post-live clip burst",
      description:
        "Turn the live session into short clips and publish them as follow-up posts with YohPal attribution links.",
      priority: "medium",
      category: "content_loop",
      expectedImpact: "repeat traffic",
    });
    const batch = db.batch();
    const created = [];
    for (const item of recommendations) {
      const doc = db.collection("growthRecommendations").doc();
      const payload = {
        creatorId,
        sessionId: parsed.data.sessionId ?? null,
        ...item,
        status: "open",
        createdAt: FieldValue.serverTimestamp(),
        createdBy: requester,
      };
      batch.set(doc, payload);
      created.push({ id: doc.id, ...payload });
    }
    await batch.commit();
    return ok(
      res,
      {
        createdCount: created.length,
        recommendations: created,
      },
      201,
    );
  },
);
