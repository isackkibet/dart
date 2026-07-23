import { Router } from "express";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { AuthenticatedRequest, requireAuth } from "../../core/http/requireAuth";
import { fail, ok } from "../../core/http/respond";
import {
  CreateAutoResponseRuleSchema,
  CreateIncidentSchema,
  SetSafeModeSchema,
  UpdateIncidentSchema,
} from "./commandCenter.schema";

export const commandCenterRouter = Router();
const db = getFirestore();

function requireCommandCenterAccess(
  req: AuthenticatedRequest,
): boolean {
  return (
    req.user?.admin === true ||
    req.user?.role === "admin" ||
    req.user?.role === "operator" ||
    req.user?.role === "approver"
  );
}

commandCenterRouter.get("/status", requireAuth, async (_req, res) => {
  return ok(res, {
    module: "command_center",
    status: "ready",
  });
});

commandCenterRouter.get(
  "/health",
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    if (!requireCommandCenterAccess(req)) {
      return fail(res, 403, "forbidden", "Command center access required.");
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

    const status =
      criticalIncidents > 0
        ? "critical"
        : incidents.size > 0
        ? "degraded"
        : "healthy";

    return ok(res, {
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
  },
);

commandCenterRouter.get(
  "/incidents",
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    if (!requireCommandCenterAccess(req)) {
      return fail(res, 403, "forbidden", "Command center access required.");
    }
    const snapshot = await db
      .collection("commandCenterIncidents")
      .orderBy("createdAt", "desc")
      .limit(100)
      .get();
    return ok(res, {
      incidents: snapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      })),
    });
  },
);

commandCenterRouter.post(
  "/incidents",
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    if (!requireCommandCenterAccess(req)) {
      return fail(res, 403, "forbidden", "Command center access required.");
    }
    const parsed = CreateIncidentSchema.safeParse(req.body);
    if (!parsed.success) {
      return fail(
        res,
        400,
        "invalid_incident_payload",
        "Invalid incident payload.",
        parsed.error.flatten(),
      );
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
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
      createdBy: actorId,
      updatedBy: actorId,
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

commandCenterRouter.patch(
  "/incidents/:incidentId",
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    if (!requireCommandCenterAccess(req)) {
      return fail(res, 403, "forbidden", "Command center access required.");
    }
    const parsed = UpdateIncidentSchema.safeParse(req.body);
    if (!parsed.success) {
      return fail(
        res,
        400,
        "invalid_incident_update",
        "Invalid incident update payload.",
        parsed.error.flatten(),
      );
    }
    const actorId = req.user?.uid ?? "system";
    const ref = db.collection("commandCenterIncidents").doc(req.params.incidentId);
    const incident = await ref.get();
    if (!incident.exists) {
      return fail(res, 404, "incident_not_found", "Incident not found.");
    }
    await ref.update({
      status: parsed.data.status,
      updatedAt: FieldValue.serverTimestamp(),
      updatedBy: actorId,
      resolvedAt:
        parsed.data.status === "resolved" ? FieldValue.serverTimestamp() : null,
    });
    return ok(res, {
      id: req.params.incidentId,
      status: parsed.data.status,
    });
  },
);

commandCenterRouter.get(
  "/safe-mode",
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    if (!requireCommandCenterAccess(req)) {
      return fail(res, 403, "forbidden", "Command center access required.");
    }
    const snapshot = await db
      .collection("safeModeToggles")
      .orderBy("key", "asc")
      .get();
    return ok(res, {
      toggles: snapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      })),
    });
  },
);

commandCenterRouter.post(
  "/safe-mode/:key",
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    if (!requireCommandCenterAccess(req)) {
      return fail(res, 403, "forbidden", "Command center access required.");
    }
    const parsed = SetSafeModeSchema.safeParse(req.body);
    if (!parsed.success) {
      return fail(
        res,
        400,
        "invalid_safe_mode_payload",
        "Invalid safe-mode payload.",
        parsed.error.flatten(),
      );
    }
    const actorId = req.user?.uid ?? "system";
    const key = req.params.key;
    await db.collection("safeModeToggles").doc(key).set(
      {
        key,
        label: key
          .split("_")
          .map((part) => part.charAt(0).toUpperCase() + part.slice(part.length > 0 ? 1 : 0))
          .join(" "),
        enabled: parsed.data.enabled,
        reason: parsed.data.reason,
        updatedAt: FieldValue.serverTimestamp(),
        updatedBy: actorId,
      },
      { merge: true },
    );
    return ok(res, {
      key,
      enabled: parsed.data.enabled,
    });
  },
);

commandCenterRouter.get(
  "/auto-response-rules",
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    if (!requireCommandCenterAccess(req)) {
      return fail(res, 403, "forbidden", "Command center access required.");
    }
    const snapshot = await db
      .collection("autoResponseRules")
      .orderBy("createdAt", "desc")
      .limit(100)
      .get();
    return ok(res, {
      rules: snapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      })),
    });
  },
);

commandCenterRouter.post(
  "/auto-response-rules",
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    if (!requireCommandCenterAccess(req)) {
      return fail(res, 403, "forbidden", "Command center access required.");
    }
    const parsed = CreateAutoResponseRuleSchema.safeParse(req.body);
    if (!parsed.success) {
      return fail(
        res,
        400,
        "invalid_auto_response_rule",
        "Invalid auto-response rule payload.",
        parsed.error.flatten(),
      );
    }
    const actorId = req.user?.uid ?? "system";
    const doc = db.collection("autoResponseRules").doc();
    const payload = {
      ...parsed.data,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
      createdBy: actorId,
      updatedBy: actorId,
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

commandCenterRouter.post(
  "/auto-response/evaluate",
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    if (!requireCommandCenterAccess(req)) {
      return fail(res, 403, "forbidden", "Command center access required.");
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
      if (
        data.conditionMetric === "openIncidents" &&
        data.conditionOperator === ">" &&
        incidents.size > Number(data.conditionValue ?? 0)
      ) {
        actions.push({
          ruleId: rule.id,
          actionType: data.actionType,
          proposed: true,
          reason: `openIncidents ${incidents.size} > ${data.conditionValue}`,
        });
      }
    }
    return ok(res, {
      evaluatedRules: rules.size,
      proposedActions: actions,
    });
  },
);
