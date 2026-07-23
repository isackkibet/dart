"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.streamOrchestrationRouter = void 0;
const express_1 = require("express");
const firestore_1 = require("firebase-admin/firestore");
const requireAuth_1 = require("../../core/http/requireAuth");
const respond_1 = require("../../core/http/respond");
const streamOrchestration_schema_1 = require("./streamOrchestration.schema");
exports.streamOrchestrationRouter = (0, express_1.Router)();
const db = (0, firestore_1.getFirestore)();
exports.streamOrchestrationRouter.get("/status", requireAuth_1.requireAuth, async (_req, res) => {
    return (0, respond_1.ok)(res, {
        module: "stream_orchestration",
        status: "ready",
    });
});
exports.streamOrchestrationRouter.get("/sessions/:sessionId/policies", requireAuth_1.requireAuth, async (req, res) => {
    const uid = req.user?.uid;
    if (!uid)
        return (0, respond_1.fail)(res, 401, "missing_user", "Missing user.");
    const session = await db.collection("liveSessions").doc(req.params.sessionId).get();
    if (!session.exists) {
        return (0, respond_1.fail)(res, 404, "session_not_found", "Live session not found.");
    }
    if (session.data()?.creatorId !== uid && req.user?.admin !== true) {
        return (0, respond_1.fail)(res, 403, "forbidden", "You cannot view these policies.");
    }
    const snapshot = await db
        .collection("streamRoutePolicies")
        .where("sessionId", "==", req.params.sessionId)
        .orderBy("updatedAt", "desc")
        .get();
    return (0, respond_1.ok)(res, {
        policies: snapshot.docs.map((doc) => ({
            id: doc.id,
            ...doc.data(),
        })),
    });
});
exports.streamOrchestrationRouter.post("/policies", requireAuth_1.requireAuth, async (req, res) => {
    const uid = req.user?.uid;
    if (!uid)
        return (0, respond_1.fail)(res, 401, "missing_user", "Missing user.");
    const parsed = streamOrchestration_schema_1.UpsertRoutePolicySchema.safeParse(req.body);
    if (!parsed.success) {
        return (0, respond_1.fail)(res, 400, "invalid_route_policy_payload", "Invalid stream route policy payload.", parsed.error.flatten());
    }
    const input = parsed.data;
    const session = await db.collection("liveSessions").doc(input.sessionId).get();
    if (!session.exists) {
        return (0, respond_1.fail)(res, 404, "session_not_found", "Live session not found.");
    }
    if (session.data()?.creatorId !== uid && req.user?.admin !== true) {
        return (0, respond_1.fail)(res, 403, "forbidden", "You cannot create this policy.");
    }
    const doc = db.collection("streamRoutePolicies").doc();
    const payload = {
        ...input,
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
exports.streamOrchestrationRouter.post("/mock-ingest/heartbeat", requireAuth_1.requireAuth, async (req, res) => {
    const uid = req.user?.uid;
    if (!uid)
        return (0, respond_1.fail)(res, 401, "missing_user", "Missing user.");
    const parsed = streamOrchestration_schema_1.MockIngestHeartbeatSchema.safeParse(req.body);
    if (!parsed.success) {
        return (0, respond_1.fail)(res, 400, "invalid_mock_ingest_payload", "Invalid mock ingest heartbeat payload.", parsed.error.flatten());
    }
    const input = parsed.data;
    const session = await db.collection("liveSessions").doc(input.sessionId).get();
    if (!session.exists) {
        return (0, respond_1.fail)(res, 404, "session_not_found", "Live session not found.");
    }
    if (session.data()?.creatorId !== uid && req.user?.admin !== true) {
        return (0, respond_1.fail)(res, 403, "forbidden", "You cannot update this stream.");
    }
    await db.collection("streamHealth").doc(input.sessionId).set({
        sessionId: input.sessionId,
        status: "healthy",
        ingestStatus: "mock_ingest_active",
        activeDestinations: input.activeDestinations,
        failedDestinations: input.failedDestinations,
        bitrateKbps: input.bitrateKbps,
        latencyMs: input.latencyMs,
        lastHeartbeatAt: firestore_1.FieldValue.serverTimestamp(),
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
        updatedBy: uid,
    }, { merge: true });
    return (0, respond_1.ok)(res, {
        sessionId: input.sessionId,
        status: "healthy",
        heartbeatAccepted: true,
    });
});
exports.streamOrchestrationRouter.post("/sessions/:sessionId/evaluate-routing", requireAuth_1.requireAuth, async (req, res) => {
    const uid = req.user?.uid;
    if (!uid)
        return (0, respond_1.fail)(res, 401, "missing_user", "Missing user.");
    const session = await db.collection("liveSessions").doc(req.params.sessionId).get();
    if (!session.exists) {
        return (0, respond_1.fail)(res, 404, "session_not_found", "Live session not found.");
    }
    if (session.data()?.creatorId !== uid && req.user?.admin !== true) {
        return (0, respond_1.fail)(res, 403, "forbidden", "You cannot evaluate this routing.");
    }
    const policies = await db
        .collection("streamRoutePolicies")
        .where("sessionId", "==", req.params.sessionId)
        .where("enabled", "==", true)
        .get();
    const routes = policies.docs.map((doc) => {
        const data = doc.data();
        return {
            policyId: doc.id,
            destinationId: data.destinationId,
            mode: data.mode,
            action: data.mode === "full"
                ? "send_full_feed"
                : data.mode === "hybrid"
                    ? "send_hybrid_feed_with_cta"
                    : "send_teaser_feed_with_cta",
            delaySeconds: data.delaySeconds,
            previewWindowSeconds: data.previewWindowSeconds,
            ctaOverlayEnabled: data.ctaOverlayEnabled,
            ctaText: data.ctaText,
            ctaUrl: data.ctaUrl,
            watermarkEnabled: data.watermarkEnabled,
            blurAfterPreview: data.blurAfterPreview,
        };
    });
    return (0, respond_1.ok)(res, {
        sessionId: req.params.sessionId,
        routes,
    });
});
//# sourceMappingURL=streamOrchestration.router.js.map