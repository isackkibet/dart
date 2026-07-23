"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.multistreamRouter = void 0;
const express_1 = require("express");
const firestore_1 = require("firebase-admin/firestore");
const requireAuth_1 = require("../../core/http/requireAuth");
const respond_1 = require("../../core/http/respond");
const multistream_schema_1 = require("./multistream.schema");
exports.multistreamRouter = (0, express_1.Router)();
const db = (0, firestore_1.getFirestore)();
exports.multistreamRouter.get("/status", requireAuth_1.requireAuth, async (_req, res) => {
    return (0, respond_1.ok)(res, {
        module: "multistream",
        status: "ready",
    });
});
exports.multistreamRouter.get("/sessions", requireAuth_1.requireAuth, async (req, res) => {
    const uid = req.user?.uid;
    if (!uid)
        return (0, respond_1.fail)(res, 401, "missing_user", "Missing user.");
    const snapshot = await db
        .collection("liveSessions")
        .where("creatorId", "==", uid)
        .orderBy("updatedAt", "desc")
        .limit(100)
        .get();
    return (0, respond_1.ok)(res, {
        sessions: snapshot.docs.map((doc) => ({
            id: doc.id,
            ...doc.data(),
        })),
    });
});
exports.multistreamRouter.post("/sessions", requireAuth_1.requireAuth, async (req, res) => {
    const uid = req.user?.uid;
    if (!uid)
        return (0, respond_1.fail)(res, 401, "missing_user", "Missing user.");
    const parsed = multistream_schema_1.CreateLiveSessionSchema.safeParse(req.body);
    if (!parsed.success) {
        return (0, respond_1.fail)(res, 400, "invalid_live_session_payload", "Invalid live session payload.", parsed.error.flatten());
    }
    const input = parsed.data;
    const doc = db.collection("liveSessions").doc();
    const payload = {
        creatorId: uid,
        title: input.title,
        description: input.description,
        category: input.category,
        status: input.scheduledAt ? "scheduled" : "draft",
        streamMode: input.streamMode,
        scheduledAt: input.scheduledAt,
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
// Route to update a live session's status (start/end/etc)
exports.multistreamRouter.patch("/sessions/:id/status", requireAuth_1.requireAuth, async (req, res) => {
    const uid = req.user?.uid;
    if (!uid)
        return (0, respond_1.fail)(res, 401, "missing_user", "Missing user.");
    const parsed = multistream_schema_1.UpdateLiveSessionStatusSchema.safeParse(req.body);
    if (!parsed.success) {
        return (0, respond_1.fail)(res, 400, "invalid_status_payload", "Invalid status payload.", parsed.error.flatten());
    }
    const { status } = parsed.data;
    const sessionRef = db.collection("liveSessions").doc(req.params.id);
    const doc = await sessionRef.get();
    if (!doc.exists) {
        return (0, respond_1.fail)(res, 404, "session_not_found", "Session not found.");
    }
    const data = doc.data();
    if (data?.creatorId !== uid) {
        return (0, respond_1.fail)(res, 403, "forbidden", "Unauthorized to update this session.");
    }
    const update = {
        status,
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
        updatedBy: uid,
    };
    if (status === "live") {
        update.startedAt = firestore_1.FieldValue.serverTimestamp();
    }
    if (status === "ended") {
        update.endedAt = firestore_1.FieldValue.serverTimestamp();
    }
    await sessionRef.update(update);
    return (0, respond_1.ok)(res, {
        id: req.params.id,
        status,
        ...update,
    });
});
// Route to create a destination for a session
exports.multistreamRouter.post("/sessions/:id/destinations", requireAuth_1.requireAuth, async (req, res) => {
    const uid = req.user?.uid;
    if (!uid)
        return (0, respond_1.fail)(res, 401, "missing_user", "Missing user.");
    const sessionRef = db.collection("liveSessions").doc(req.params.id);
    const sessionDoc = await sessionRef.get();
    if (!sessionDoc.exists) {
        return (0, respond_1.fail)(res, 404, "session_not_found", "Session not found.");
    }
    const sessionData = sessionDoc.data();
    if (sessionData?.creatorId !== uid) {
        return (0, respond_1.fail)(res, 403, "forbidden", "Unauthorized to add destinations to this session.");
    }
    const parsed = multistream_schema_1.CreateDestinationSchema.safeParse(req.body);
    if (!parsed.success) {
        return (0, respond_1.fail)(res, 400, "invalid_destination_payload", "Invalid destination payload.", parsed.error.flatten());
    }
    const input = parsed.data;
    const doc = db.collection("liveDestinations").doc();
    const payload = {
        sessionId: req.params.id,
        creatorId: uid,
        platform: input.platform,
        destinationName: input.destinationName,
        streamMode: input.streamMode,
        ctaEnabled: input.ctaEnabled,
        delaySeconds: input.delaySeconds,
        status: "inactive",
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
// Route to delete a destination
exports.multistreamRouter.delete("/destinations/:id", requireAuth_1.requireAuth, async (req, res) => {
    const uid = req.user?.uid;
    if (!uid)
        return (0, respond_1.fail)(res, 401, "missing_user", "Missing user.");
    const destRef = db.collection("liveDestinations").doc(req.params.id);
    const destDoc = await destRef.get();
    if (!destDoc.exists) {
        return (0, respond_1.fail)(res, 404, "destination_not_found", "Destination not found.");
    }
    const destData = destDoc.data();
    if (destData?.creatorId !== uid) {
        return (0, respond_1.fail)(res, 403, "forbidden", "Unauthorized to delete this destination.");
    }
    await destRef.delete();
    return (0, respond_1.ok)(res, {
        id: req.params.id,
        deleted: true,
    });
});
//# sourceMappingURL=multistream.router.js.map