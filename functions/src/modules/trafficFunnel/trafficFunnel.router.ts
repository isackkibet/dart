import { Router } from "express";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { AuthenticatedRequest, requireAuth } from "../../core/http/requireAuth";
import { fail, ok } from "../../core/http/respond";
import {
  CaptureConversionSchema,
  CaptureTrafficEventSchema,
  CreateTrafficCampaignSchema,
} from "./trafficFunnel.schema";

export const trafficFunnelRouter = Router();
const db = getFirestore();

trafficFunnelRouter.get("/status", requireAuth, async (_req, res) => {
  return ok(res, {
    module: "traffic_funnel",
    status: "ready",
  });
});

trafficFunnelRouter.post(
  "/campaigns",
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    const uid = req.user?.uid;
    if (!uid) return fail(res, 401, "missing_user", "Missing user.");
    const parsed = CreateTrafficCampaignSchema.safeParse(req.body);
    if (!parsed.success) {
      return fail(
        res,
        400,
        "invalid_campaign_payload",
        "Invalid traffic campaign payload.",
        parsed.error.flatten(),
      );
    }
    const input = parsed.data;
    const session = await db.collection("liveSessions").doc(input.sessionId).get();
    if (!session.exists) {
      return fail(res, 404, "session_not_found", "Live session not found.");
    }
    if (session.data()?.creatorId !== uid && req.user?.admin !== true) {
      return fail(res, 403, "forbidden", "You cannot create this campaign.");
    }
    const doc = db.collection("trafficCampaigns").doc();
    const campaignCode = `${input.sourcePlatform}_${Date.now()}`;
    const payload = {
      creatorId: uid,
      sessionId: input.sessionId,
      name: input.name,
      sourcePlatform: input.sourcePlatform,
      campaignCode,
      status: "active",
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
      createdBy: uid,
      updatedBy: uid,
    };
    await doc.set(payload);
    return ok(
      res,
      {
        id: doc.id,
        ...payload,
      },
      201,
    );
  },
);

trafficFunnelRouter.get(
  "/campaigns",
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    const uid = req.user?.uid;
    if (!uid) return fail(res, 401, "missing_user", "Missing user.");
    const snapshot = await db
      .collection("trafficCampaigns")
      .where("creatorId", "==", uid)
      .orderBy("updatedAt", "desc")
      .limit(100)
      .get();
    return ok(res, {
      campaigns: snapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      })),
    });
  },
);

trafficFunnelRouter.post("/events", requireAuth, async (req, res) => {
  const parsed = CaptureTrafficEventSchema.safeParse(req.body);
  if (!parsed.success) {
    return fail(
      res,
      400,
      "invalid_traffic_event_payload",
      "Invalid traffic event payload.",
      parsed.error.flatten(),
    );
  }
  const doc = db.collection("trafficEvents").doc();
  await doc.set({
    ...parsed.data,
    createdAt: FieldValue.serverTimestamp(),
  });
  return ok(
    res,
    {
      id: doc.id,
      captured: true,
    },
    201,
  );
});

trafficFunnelRouter.post("/conversions", requireAuth, async (req, res) => {
  const parsed = CaptureConversionSchema.safeParse(req.body);
  if (!parsed.success) {
    return fail(
      res,
      400,
      "invalid_conversion_payload",
      "Invalid conversion payload.",
      parsed.error.flatten(),
    );
  }
  const doc = db.collection("conversionEvents").doc();
  await doc.set({
    ...parsed.data,
    createdAt: FieldValue.serverTimestamp(),
  });
  return ok(
    res,
    {
      id: doc.id,
      captured: true,
    },
    201,
  );
});

trafficFunnelRouter.get(
  "/sessions/:sessionId/funnel-summary",
  requireAuth,
  async (req, res) => {
    const sessionId = req.params.sessionId;
    const [trafficSnapshot, conversionSnapshot] = await Promise.all([
      db
        .collection("trafficEvents")
        .where("sessionId", "==", sessionId)
        .limit(3000)
        .get(),
      db
        .collection("conversionEvents")
        .where("sessionId", "==", sessionId)
        .limit(3000)
        .get(),
    ]);
    const byPlatform: Record<string, number> = {};
    const byEventType: Record<string, number> = {};
    const byConversionType: Record<string, number> = {};
    for (const doc of trafficSnapshot.docs) {
      const data = doc.data();
      const platform = String(data.sourcePlatform ?? "unknown");
      const eventType = String(data.eventType ?? "unknown");
      byPlatform[platform] = (byPlatform[platform] ?? 0) + 1;
      byEventType[eventType] = (byEventType[eventType] ?? 0) + 1;
    }
    let totalRevenue = 0;
    for (const doc of conversionSnapshot.docs) {
      const data = doc.data();
      const conversionType = String(data.conversionType ?? "unknown");
      const platform = String(data.sourcePlatform ?? "unknown");
      const valueAmount =
        typeof data.valueAmount === "number" ? data.valueAmount : 0;
      byConversionType[conversionType] =
        (byConversionType[conversionType] ?? 0) + 1;
      byPlatform[platform] = (byPlatform[platform] ?? 0) + 1;
      totalRevenue += valueAmount;
    }
    return ok(res, {
      sessionId,
      totalEvents: trafficSnapshot.size,
      totalConversions: conversionSnapshot.size,
      totalRevenue,
      byPlatform,
      byEventType,
      byConversionType,
    });
  },
);

trafficFunnelRouter.get(
  "/sessions/:sessionId/summary",
  requireAuth,
  async (req, res) => {
    const snapshot = await db
      .collection("trafficEvents")
      .where("sessionId", "==", req.params.sessionId)
      .limit(1000)
      .get();
    const byPlatform: Record<string, number> = {};
    const byEventType: Record<string, number> = {};
    for (const doc of snapshot.docs) {
      const data = doc.data();
      const platform = String(data.sourcePlatform ?? "unknown");
      const eventType = String(data.eventType ?? "unknown");
      byPlatform[platform] = (byPlatform[platform] ?? 0) + 1;
      byEventType[eventType] = (byEventType[eventType] ?? 0) + 1;
    }
    return ok(res, {
      sessionId: req.params.sessionId,
      totalEvents: snapshot.size,
      byPlatform,
      byEventType,
    });
  },
);
