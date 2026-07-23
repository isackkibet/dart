"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.autonomyRouter = void 0;
const express_1 = require("express");
const firestore_1 = require("firebase-admin/firestore");
const requireAuth_1 = require("../../core/http/requireAuth");
const respond_1 = require("../../core/http/respond");
const autonomy_schema_1 = require("./autonomy.schema");
exports.autonomyRouter = (0, express_1.Router)();
const db = (0, firestore_1.getFirestore)();
exports.autonomyRouter.get("/status", requireAuth_1.requireAuth, async (_req, res) => {
    return (0, respond_1.ok)(res, {
        module: "autonomy",
        status: "ready",
        defaultMode: "recommendation_first",
    });
});
exports.autonomyRouter.get("/policies", requireAuth_1.requireAuth, async (req, res) => {
    const uid = req.user?.uid;
    if (!uid)
        return (0, respond_1.fail)(res, 401, "missing_user", "Missing user.");
    const snapshot = await db
        .collection("autonomyPolicies")
        .where("creatorId", "==", uid)
        .orderBy("updatedAt", "desc")
        .get();
    return (0, respond_1.ok)(res, {
        policies: snapshot.docs.map((doc) => ({
            id: doc.id,
            ...doc.data(),
        })),
    });
});
exports.autonomyRouter.post("/policies", requireAuth_1.requireAuth, async (req, res) => {
    const uid = req.user?.uid;
    if (!uid)
        return (0, respond_1.fail)(res, 401, "missing_user", "Missing user.");
    const parsed = autonomy_schema_1.CreateAutonomyPolicySchema.safeParse(req.body);
    if (!parsed.success) {
        return (0, respond_1.fail)(res, 400, "invalid_autonomy_policy_payload", "Invalid autonomy policy payload.", parsed.error.flatten());
    }
    const doc = db.collection("autonomyPolicies").doc();
    const input = parsed.data;
    const payload = {
        creatorId: uid,
        domain: input.domain,
        name: input.name,
        description: input.description,
        mode: input.mode,
        enabled: input.enabled,
        maxActionsPerHour: input.maxActionsPerHour,
        requiresApproval: input.requiresApproval,
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
exports.autonomyRouter.post("/decisions/propose", requireAuth_1.requireAuth, async (req, res) => {
    const actorId = req.user?.uid;
    if (!actorId)
        return (0, respond_1.fail)(res, 401, "missing_user", "Missing user.");
    const parsed = autonomy_schema_1.ProposeDecisionSchema.safeParse(req.body);
    if (!parsed.success) {
        return (0, respond_1.fail)(res, 400, "invalid_decision_payload", "Invalid autonomy decision payload.", parsed.error.flatten());
    }
    const input = parsed.data;
    if (actorId !== input.creatorId && req.user?.admin !== true) {
        return (0, respond_1.fail)(res, 403, "forbidden", "You cannot propose for this creator.");
    }
    const doc = db.collection("autonomyDecisions").doc();
    const payload = {
        creatorId: input.creatorId,
        sessionId: input.sessionId ?? null,
        domain: input.domain,
        recommendation: input.recommendation,
        reason: input.reason,
        confidence: input.confidence,
        status: "proposed",
        actionType: input.actionType,
        payload: input.payload,
        createdAt: firestore_1.FieldValue.serverTimestamp(),
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
        createdBy: actorId,
        updatedBy: actorId,
    };
    await doc.set(payload);
    return (0, respond_1.ok)(res, {
        id: doc.id,
        ...payload,
    }, 201);
});
exports.autonomyRouter.post("/decisions/:decisionId/approve", requireAuth_1.requireAuth, async (req, res) => {
    const actorId = req.user?.uid;
    if (!actorId)
        return (0, respond_1.fail)(res, 401, "missing_user", "Missing user.");
    const ref = db.collection("autonomyDecisions").doc(req.params.decisionId);
    const decision = await ref.get();
    if (!decision.exists) {
        return (0, respond_1.fail)(res, 404, "decision_not_found", "Decision not found.");
    }
    if (decision.data()?.creatorId !== actorId && req.user?.admin !== true) {
        return (0, respond_1.fail)(res, 403, "forbidden", "You cannot approve this decision.");
    }
    await ref.update({
        status: "approved",
        approvedAt: firestore_1.FieldValue.serverTimestamp(),
        approvedBy: actorId,
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
        updatedBy: actorId,
    });
    return (0, respond_1.ok)(res, {
        id: req.params.decisionId,
        status: "approved",
    });
});
exports.autonomyRouter.post("/decisions/:decisionId/reject", requireAuth_1.requireAuth, async (req, res) => {
    const actorId = req.user?.uid;
    if (!actorId)
        return (0, respond_1.fail)(res, 401, "missing_user", "Missing user.");
    const ref = db.collection("autonomyDecisions").doc(req.params.decisionId);
    const decision = await ref.get();
    if (!decision.exists) {
        return (0, respond_1.fail)(res, 404, "decision_not_found", "Decision not found.");
    }
    if (decision.data()?.creatorId !== actorId && req.user?.admin !== true) {
        return (0, respond_1.fail)(res, 403, "forbidden", "You cannot reject this decision.");
    }
    await ref.update({
        status: "rejected",
        rejectedAt: firestore_1.FieldValue.serverTimestamp(),
        rejectedBy: actorId,
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
        updatedBy: actorId,
    });
    return (0, respond_1.ok)(res, {
        id: req.params.decisionId,
        status: "rejected",
    });
});
//# sourceMappingURL=autonomy.router.js.map