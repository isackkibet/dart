"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.clipFactoryRouter = void 0;
const express_1 = require("express");
const firestore_1 = require("firebase-admin/firestore");
const requireAuth_1 = require("../../core/http/requireAuth");
const respond_1 = require("../../core/http/respond");
const clipFactory_schema_1 = require("./clipFactory.schema");
exports.clipFactoryRouter = (0, express_1.Router)();
const db = (0, firestore_1.getFirestore)();
exports.clipFactoryRouter.get("/status", requireAuth_1.requireAuth, async (_req, res) => {
    return (0, respond_1.ok)(res, {
        module: "clip_factory",
        status: "ready",
    });
});
exports.clipFactoryRouter.get("/sessions/:sessionId/replay", requireAuth_1.requireAuth, async (req, res) => {
    const uid = req.user?.uid;
    if (!uid)
        return (0, respond_1.fail)(res, 401, "missing_user", "Missing user.");
    const sessionId = req.params.sessionId;
    const snapshot = await db
        .collection("sessionReplays")
        .where("sessionId", "==", sessionId)
        .limit(1)
        .get();
    if (snapshot.empty) {
        return (0, respond_1.ok)(res, { replay: null });
    }
    const doc = snapshot.docs[0];
    const data = doc.data();
    if (data.creatorId !== uid && req.user?.admin !== true) {
        return (0, respond_1.fail)(res, 403, "forbidden", "You cannot view this replay.");
    }
    return (0, respond_1.ok)(res, {
        replay: { id: doc.id, ...data },
    });
});
exports.clipFactoryRouter.get("/sessions/:sessionId/clips", requireAuth_1.requireAuth, async (req, res) => {
    const uid = req.user?.uid;
    if (!uid)
        return (0, respond_1.fail)(res, 401, "missing_user", "Missing user.");
    const sessionId = req.params.sessionId;
    const snapshot = await db
        .collection("clipSegments")
        .where("sessionId", "==", sessionId)
        .orderBy("startOffsetSeconds", "asc")
        .get();
    const clips = snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
    return (0, respond_1.ok)(res, { clips });
});
exports.clipFactoryRouter.post("/sessions/:sessionId/clips/generate", requireAuth_1.requireAuth, async (req, res) => {
    const uid = req.user?.uid;
    if (!uid)
        return (0, respond_1.fail)(res, 401, "missing_user", "Missing user.");
    const parsed = clipFactory_schema_1.GenerateClipsSchema.safeParse(req.body ?? {});
    if (!parsed.success) {
        return (0, respond_1.fail)(res, 400, "invalid_clip_generate_payload", "Invalid clip generation payload.", parsed.error.flatten());
    }
    const sessionId = req.params.sessionId;
    const config = parsed.data;
    // Evaluate engagement signals
    const [gifts, paidMessages, trafficEvents] = await Promise.all([
        db
            .collection("giftEvents")
            .where("sessionId", "==", sessionId)
            .orderBy("createdAt", "asc")
            .limit(500)
            .get(),
        db
            .collection("paidMessages")
            .where("sessionId", "==", sessionId)
            .orderBy("createdAt", "asc")
            .limit(500)
            .get(),
        db
            .collection("trafficEvents")
            .where("sessionId", "==", sessionId)
            .orderBy("createdAt", "asc")
            .limit(1000)
            .get(),
    ]);
    const proposedClips = [];
    // Gift spikes → High-value engagement clip
    if (gifts.size > 0) {
        proposedClips.push({
            title: "Gift Spike Moment",
            startOffsetSeconds: 30,
            endOffsetSeconds: Math.min(30 + config.maxDurationSeconds, 180),
            triggerEventType: "gift_spike",
            triggerScore: Math.min(1, gifts.size / 10),
            suggestedPlatforms: ["tiktok", "instagram", "youtube"],
        });
    }
    // Paid messages → Exclusive moment clip
    if (paidMessages.size > 0) {
        proposedClips.push({
            title: "Paid Message Highlight",
            startOffsetSeconds: 60,
            endOffsetSeconds: Math.min(60 + config.maxDurationSeconds, 210),
            triggerEventType: "paid_message",
            triggerScore: Math.min(1, paidMessages.size / 5),
            suggestedPlatforms: ["youtube", "tiktok"],
        });
    }
    // Traffic peak → Peak viewer moment
    if (trafficEvents.size > 50) {
        proposedClips.push({
            title: "Peak Viewer Moment",
            startOffsetSeconds: 120,
            endOffsetSeconds: Math.min(120 + config.maxDurationSeconds, 300),
            triggerEventType: "peak_viewers",
            triggerScore: Math.min(1, trafficEvents.size / 200),
            suggestedPlatforms: ["youtube", "instagram", "facebook", "x"],
        });
    }
    // Always suggest an intro clip
    proposedClips.push({
        title: "Stream Intro Clip",
        startOffsetSeconds: 0,
        endOffsetSeconds: config.minDurationSeconds,
        triggerEventType: "peak_viewers",
        triggerScore: 0.5,
        suggestedPlatforms: ["tiktok", "instagram"],
    });
    const batch = db.batch();
    const created = [];
    for (const clip of proposedClips.slice(0, config.maxClips)) {
        const doc = db.collection("clipSegments").doc();
        const payload = {
            sessionId,
            creatorId: uid,
            status: "proposed",
            ...clip,
            createdAt: firestore_1.FieldValue.serverTimestamp(),
            updatedAt: firestore_1.FieldValue.serverTimestamp(),
            createdBy: uid,
            updatedBy: uid,
        };
        batch.set(doc, payload);
        created.push({ id: doc.id, ...payload });
    }
    await batch.commit();
    return (0, respond_1.ok)(res, {
        generatedCount: created.length,
        clips: created,
    }, 201);
});
exports.clipFactoryRouter.patch("/sessions/:sessionId/clips/:clipId", requireAuth_1.requireAuth, async (req, res) => {
    const uid = req.user?.uid;
    if (!uid)
        return (0, respond_1.fail)(res, 401, "missing_user", "Missing user.");
    const parsed = clipFactory_schema_1.UpdateClipStatusSchema.safeParse(req.body);
    if (!parsed.success) {
        return (0, respond_1.fail)(res, 400, "invalid_clip_status_payload", "Invalid clip status payload.", parsed.error.flatten());
    }
    const ref = db.collection("clipSegments").doc(req.params.clipId);
    const clip = await ref.get();
    if (!clip.exists) {
        return (0, respond_1.fail)(res, 404, "clip_not_found", "Clip segment not found.");
    }
    if (clip.data()?.creatorId !== uid && req.user?.admin !== true) {
        return (0, respond_1.fail)(res, 403, "forbidden", "You cannot update this clip.");
    }
    await ref.update({
        status: parsed.data.status,
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
        updatedBy: uid,
    });
    return (0, respond_1.ok)(res, {
        id: req.params.clipId,
        status: parsed.data.status,
    });
});
exports.clipFactoryRouter.post("/sessions/:sessionId/clips/:clipId/distribute", requireAuth_1.requireAuth, async (req, res) => {
    const uid = req.user?.uid;
    if (!uid)
        return (0, respond_1.fail)(res, 401, "missing_user", "Missing user.");
    const ref = db.collection("clipSegments").doc(req.params.clipId);
    const clip = await ref.get();
    if (!clip.exists) {
        return (0, respond_1.fail)(res, 404, "clip_not_found", "Clip segment not found.");
    }
    if (clip.data()?.creatorId !== uid && req.user?.admin !== true) {
        return (0, respond_1.fail)(res, 403, "forbidden", "You cannot distribute this clip.");
    }
    if (clip.data()?.status !== "approved") {
        return (0, respond_1.fail)(res, 400, "clip_not_approved", "Only approved clips can be distributed.");
    }
    await ref.update({
        status: "distributed",
        distributedAt: firestore_1.FieldValue.serverTimestamp(),
        distributedBy: uid,
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
        updatedBy: uid,
    });
    return (0, respond_1.ok)(res, {
        id: req.params.clipId,
        status: "distributed",
        message: "Clip queued for platform distribution.",
    });
});
//# sourceMappingURL=clipFactory.router.js.map