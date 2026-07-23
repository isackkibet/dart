"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.trafficFunnelRouter = void 0;
const express_1 = require("express");
const firestore_1 = require("firebase-admin/firestore");
const requireAuth_1 = require("../../core/http/requireAuth");
const respond_1 = require("../../core/http/respond");
const trafficFunnel_schema_1 = require("./trafficFunnel.schema");
exports.trafficFunnelRouter = (0, express_1.Router)();
const db = (0, firestore_1.getFirestore)();
exports.trafficFunnelRouter.get("/status", requireAuth_1.requireAuth, async (_req, res) => {
    return (0, respond_1.ok)(res, {
        module: "traffic_funnel",
        status: "ready",
    });
});
exports.trafficFunnelRouter.post("/campaigns", requireAuth_1.requireAuth, async (req, res) => {
    const uid = req.user?.uid;
    if (!uid)
        return (0, respond_1.fail)(res, 401, "missing_user", "Missing user.");
    const parsed = trafficFunnel_schema_1.CreateTrafficCampaignSchema.safeParse(req.body);
    if (!parsed.success) {
        return (0, respond_1.fail)(res, 400, "invalid_campaign_payload", "Invalid traffic campaign payload.", parsed.error.flatten());
    }
    const input = parsed.data;
    const session = await db.collection("liveSessions").doc(input.sessionId).get();
    if (!session.exists) {
        return (0, respond_1.fail)(res, 404, "session_not_found", "Live session not found.");
    }
    if (session.data()?.creatorId !== uid && req.user?.admin !== true) {
        return (0, respond_1.fail)(res, 403, "forbidden", "You cannot create this campaign.");
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
        createdAt: firestore_1.FieldValue.serverTimestamp(),
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
        createdBy: uid,
        updatedBy: uid,
    };
    await doc.set(payload);
    return (0, respond_1.ok)(res, {
        id: doc.id,
        ...payload,
    }, 201);
});
exports.trafficFunnelRouter.get("/campaigns", requireAuth_1.requireAuth, async (req, res) => {
    const uid = req.user?.uid;
    if (!uid)
        return (0, respond_1.fail)(res, 401, "missing_user", "Missing user.");
    const snapshot = await db
        .collection("trafficCampaigns")
        .where("creatorId", "==", uid)
        .orderBy("updatedAt", "desc")
        .limit(100)
        .get();
    return (0, respond_1.ok)(res, {
        campaigns: snapshot.docs.map((doc) => ({
            id: doc.id,
            ...doc.data(),
        })),
    });
});
exports.trafficFunnelRouter.post("/events", requireAuth_1.requireAuth, async (req, res) => {
    const parsed = trafficFunnel_schema_1.CaptureTrafficEventSchema.safeParse(req.body);
    if (!parsed.success) {
        return (0, respond_1.fail)(res, 400, "invalid_traffic_event_payload", "Invalid traffic event payload.", parsed.error.flatten());
    }
    const doc = db.collection("trafficEvents").doc();
    await doc.set({
        ...parsed.data,
        createdAt: firestore_1.FieldValue.serverTimestamp(),
    });
    return (0, respond_1.ok)(res, {
        id: doc.id,
        captured: true,
    }, 201);
});
exports.trafficFunnelRouter.post("/conversions", requireAuth_1.requireAuth, async (req, res) => {
    const parsed = trafficFunnel_schema_1.CaptureConversionSchema.safeParse(req.body);
    if (!parsed.success) {
        return (0, respond_1.fail)(res, 400, "invalid_conversion_payload", "Invalid conversion payload.", parsed.error.flatten());
    }
    const doc = db.collection("conversionEvents").doc();
    await doc.set({
        ...parsed.data,
        createdAt: firestore_1.FieldValue.serverTimestamp(),
    });
    return (0, respond_1.ok)(res, {
        id: doc.id,
        captured: true,
    }, 201);
});
exports.trafficFunnelRouter.get("/sessions/:sessionId/funnel-summary", requireAuth_1.requireAuth, async (req, res) => {
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
    const byPlatform = {};
    const byEventType = {};
    const byConversionType = {};
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
        const valueAmount = typeof data.valueAmount === "number" ? data.valueAmount : 0;
        byConversionType[conversionType] =
            (byConversionType[conversionType] ?? 0) + 1;
        byPlatform[platform] = (byPlatform[platform] ?? 0) + 1;
        totalRevenue += valueAmount;
    }
    return (0, respond_1.ok)(res, {
        sessionId,
        totalEvents: trafficSnapshot.size,
        totalConversions: conversionSnapshot.size,
        totalRevenue,
        byPlatform,
        byEventType,
        byConversionType,
    });
});
exports.trafficFunnelRouter.get("/sessions/:sessionId/summary", requireAuth_1.requireAuth, async (req, res) => {
    const snapshot = await db
        .collection("trafficEvents")
        .where("sessionId", "==", req.params.sessionId)
        .limit(1000)
        .get();
    const byPlatform = {};
    const byEventType = {};
    for (const doc of snapshot.docs) {
        const data = doc.data();
        const platform = String(data.sourcePlatform ?? "unknown");
        const eventType = String(data.eventType ?? "unknown");
        byPlatform[platform] = (byPlatform[platform] ?? 0) + 1;
        byEventType[eventType] = (byEventType[eventType] ?? 0) + 1;
    }
    return (0, respond_1.ok)(res, {
        sessionId: req.params.sessionId,
        totalEvents: snapshot.size,
        byPlatform,
        byEventType,
    });
});
//# sourceMappingURL=trafficFunnel.router.js.map