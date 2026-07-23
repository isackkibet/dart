"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.commandCenterRouter = void 0;
const express_1 = require("express");
const firestore_1 = require("firebase-admin/firestore");
const requireAuth_1 = require("../../core/http/requireAuth");
const respond_1 = require("../../core/http/respond");
const commandCenter_schema_1 = require("./commandCenter.schema");
exports.commandCenterRouter = (0, express_1.Router)();
const db = (0, firestore_1.getFirestore)();
function requireCommandCenterAccess(req) {
    return (req.user?.admin === true ||
        req.user?.role === "admin" ||
        req.user?.role === "operator" ||
        req.user?.role === "approver");
}
exports.commandCenterRouter.get("/status", requireAuth_1.requireAuth, async (_req, res) => {
    return (0, respond_1.ok)(res, {
        module: "command_center",
        status: "ready",
    });
});
exports.commandCenterRouter.get("/health", requireAuth_1.requireAuth, async (req, res) => {
    if (!requireCommandCenterAccess(req)) {
        return (0, respond_1.fail)(res, 403, "forbidden", "Command center access required.");
    }
    const [liveSessions, incidents, safeMode] = await Promise.all([
        db.collection("liveSessions").where("status", "==", "live").limit(500).get(),
        db
            .collection("commandCenterIncidents")
            .where("status", "in", ["open", "investigating"])
            .limit(500)
            .get(),
        db.collection("safeModeToggles").where("enabled", "==", true).limit(100).get(),
    ]);
    const criticalIncidents = incidents.docs.filter((doc) => {
        const severity = doc.data().severity;
        return severity === "p0" || severity === "p1";
    }).length;
    const status = criticalIncidents > 0
        ? "critical"
        : incidents.size > 0
            ? "degraded"
            : "healthy";
    return (0, respond_1.ok)(res, {
        status,
        apiStatus: "healthy",
        firestoreStatus: "healthy",
        functionsStatus: "healthy",
        authStatus: "healthy",
        activeLiveSessions: liveSessions.size,
        openIncidents: incidents.size,
        criticalIncidents,
        safeModeEnabled: safeMode.size > 0,
        updatedAt: new Date().toISOString(),
    });
});
exports.commandCenterRouter.get("/incidents", requireAuth_1.requireAuth, async (req, res) => {
    if (!requireCommandCenterAccess(req)) {
        return (0, respond_1.fail)(res, 403, "forbidden", "Command center access required.");
    }
    const snapshot = await db
        .collection("commandCenterIncidents")
        .orderBy("createdAt", "desc")
        .limit(100)
        .get();
    return (0, respond_1.ok)(res, {
        incidents: snapshot.docs.map((doc) => ({
            id: doc.id,
            ...doc.data(),
        })),
    });
});
exports.commandCenterRouter.post("/incidents", requireAuth_1.requireAuth, async (req, res) => {
    if (!requireCommandCenterAccess(req)) {
        return (0, respond_1.fail)(res, 403, "forbidden", "Command center access required.");
    }
    const parsed = commandCenter_schema_1.CreateIncidentSchema.safeParse(req.body);
    if (!parsed.success) {
        return (0, respond_1.fail)(res, 400, "invalid_incident_payload", "Invalid incident payload.", parsed.error.flatten());
    }
    const actorId = req.user?.uid ?? "system";
    const doc = db.collection("commandCenterIncidents").doc();
    const input = parsed.data;
    const payload = {
        title: input.title,
        description: input.description,
        severity: input.severity,
        status: "open",
        source: "manual",
        affectedService: input.affectedService,
        autoResponseTriggered: false,
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
exports.commandCenterRouter.patch("/incidents/:incidentId", requireAuth_1.requireAuth, async (req, res) => {
    if (!requireCommandCenterAccess(req)) {
        return (0, respond_1.fail)(res, 403, "forbidden", "Command center access required.");
    }
    const parsed = commandCenter_schema_1.UpdateIncidentSchema.safeParse(req.body);
    if (!parsed.success) {
        return (0, respond_1.fail)(res, 400, "invalid_incident_update", "Invalid incident update payload.", parsed.error.flatten());
    }
    const actorId = req.user?.uid ?? "system";
    const ref = db.collection("commandCenterIncidents").doc(req.params.incidentId);
    const incident = await ref.get();
    if (!incident.exists) {
        return (0, respond_1.fail)(res, 404, "incident_not_found", "Incident not found.");
    }
    await ref.update({
        status: parsed.data.status,
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
        updatedBy: actorId,
        resolvedAt: parsed.data.status === "resolved" ? firestore_1.FieldValue.serverTimestamp() : null,
    });
    return (0, respond_1.ok)(res, {
        id: req.params.incidentId,
        status: parsed.data.status,
    });
});
exports.commandCenterRouter.get("/safe-mode", requireAuth_1.requireAuth, async (req, res) => {
    if (!requireCommandCenterAccess(req)) {
        return (0, respond_1.fail)(res, 403, "forbidden", "Command center access required.");
    }
    const snapshot = await db
        .collection("safeModeToggles")
        .orderBy("key", "asc")
        .get();
    return (0, respond_1.ok)(res, {
        toggles: snapshot.docs.map((doc) => ({
            id: doc.id,
            ...doc.data(),
        })),
    });
});
exports.commandCenterRouter.post("/safe-mode/:key", requireAuth_1.requireAuth, async (req, res) => {
    if (!requireCommandCenterAccess(req)) {
        return (0, respond_1.fail)(res, 403, "forbidden", "Command center access required.");
    }
    const parsed = commandCenter_schema_1.SetSafeModeSchema.safeParse(req.body);
    if (!parsed.success) {
        return (0, respond_1.fail)(res, 400, "invalid_safe_mode_payload", "Invalid safe-mode payload.", parsed.error.flatten());
    }
    const actorId = req.user?.uid ?? "system";
    const key = req.params.key;
    await db.collection("safeModeToggles").doc(key).set({
        key,
        label: key
            .split("_")
            .map((part) => part.charAt(0).toUpperCase() + part.slice(part.length > 0 ? 1 : 0))
            .join(" "),
        enabled: parsed.data.enabled,
        reason: parsed.data.reason,
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
        updatedBy: actorId,
    }, { merge: true });
    return (0, respond_1.ok)(res, {
        key,
        enabled: parsed.data.enabled,
    });
});
exports.commandCenterRouter.get("/auto-response-rules", requireAuth_1.requireAuth, async (req, res) => {
    if (!requireCommandCenterAccess(req)) {
        return (0, respond_1.fail)(res, 403, "forbidden", "Command center access required.");
    }
    const snapshot = await db
        .collection("autoResponseRules")
        .orderBy("createdAt", "desc")
        .limit(100)
        .get();
    return (0, respond_1.ok)(res, {
        rules: snapshot.docs.map((doc) => ({
            id: doc.id,
            ...doc.data(),
        })),
    });
});
exports.commandCenterRouter.post("/auto-response-rules", requireAuth_1.requireAuth, async (req, res) => {
    if (!requireCommandCenterAccess(req)) {
        return (0, respond_1.fail)(res, 403, "forbidden", "Command center access required.");
    }
    const parsed = commandCenter_schema_1.CreateAutoResponseRuleSchema.safeParse(req.body);
    if (!parsed.success) {
        return (0, respond_1.fail)(res, 400, "invalid_auto_response_rule", "Invalid auto-response rule payload.", parsed.error.flatten());
    }
    const actorId = req.user?.uid ?? "system";
    const doc = db.collection("autoResponseRules").doc();
    const payload = {
        ...parsed.data,
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
exports.commandCenterRouter.post("/auto-response/evaluate", requireAuth_1.requireAuth, async (req, res) => {
    if (!requireCommandCenterAccess(req)) {
        return (0, respond_1.fail)(res, 403, "forbidden", "Command center access required.");
    }
    const [rules, incidents] = await Promise.all([
        db.collection("autoResponseRules").where("enabled", "==", true).get(),
        db
            .collection("commandCenterIncidents")
            .where("status", "in", ["open", "investigating"])
            .get(),
    ]);
    const actions = [];
    for (const rule of rules.docs) {
        const data = rule.data();
        if (data.conditionMetric === "openIncidents" &&
            data.conditionOperator === ">" &&
            incidents.size > Number(data.conditionValue ?? 0)) {
            actions.push({
                ruleId: rule.id,
                actionType: data.actionType,
                proposed: true,
                reason: `openIncidents ${incidents.size} > ${data.conditionValue}`,
            });
        }
    }
    return (0, respond_1.ok)(res, {
        evaluatedRules: rules.size,
        proposedActions: actions,
    });
});
//# sourceMappingURL=commandCenter.router.js.map