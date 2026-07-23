import { Router } from "express";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { AuthenticatedRequest, requireAuth } from "../../core/http/requireAuth";
import { fail, ok } from "../../core/http/respond";
import {
  CreateAutonomyPolicySchema,
  ProposeDecisionSchema,
} from "./autonomy.schema";

export const autonomyRouter = Router();
const db = getFirestore();

autonomyRouter.get("/status", requireAuth, async (_req, res) => {
  return ok(res, {
    module: "autonomy",
    status: "ready",
    defaultMode: "recommendation_first",
  });
});

autonomyRouter.get(
  "/policies",
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    const uid = req.user?.uid;
    if (!uid) return fail(res, 401, "missing_user", "Missing user.");
    const snapshot = await db
      .collection("autonomyPolicies")
      .where("creatorId", "==", uid)
      .orderBy("updatedAt", "desc")
      .get();
    return ok(res, {
      policies: snapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      })),
    });
  },
);

autonomyRouter.post(
  "/policies",
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    const uid = req.user?.uid;
    if (!uid) return fail(res, 401, "missing_user", "Missing user.");
    const parsed = CreateAutonomyPolicySchema.safeParse(req.body);
    if (!parsed.success) {
      return fail(
        res,
        400,
        "invalid_autonomy_policy_payload",
        "Invalid autonomy policy payload.",
        parsed.error.flatten(),
      );
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

autonomyRouter.post(
  "/decisions/propose",
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    const actorId = req.user?.uid;
    if (!actorId) return fail(res, 401, "missing_user", "Missing user.");
    const parsed = ProposeDecisionSchema.safeParse(req.body);
    if (!parsed.success) {
      return fail(
        res,
        400,
        "invalid_decision_payload",
        "Invalid autonomy decision payload.",
        parsed.error.flatten(),
      );
    }
    const input = parsed.data;
    if (actorId !== input.creatorId && req.user?.admin !== true) {
      return fail(res, 403, "forbidden", "You cannot propose for this creator.");
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

autonomyRouter.post(
  "/decisions/:decisionId/approve",
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    const actorId = req.user?.uid;
    if (!actorId) return fail(res, 401, "missing_user", "Missing user.");
    const ref = db.collection("autonomyDecisions").doc(req.params.decisionId);
    const decision = await ref.get();
    if (!decision.exists) {
      return fail(res, 404, "decision_not_found", "Decision not found.");
    }
    if (decision.data()?.creatorId !== actorId && req.user?.admin !== true) {
      return fail(res, 403, "forbidden", "You cannot approve this decision.");
    }
    await ref.update({
      status: "approved",
      approvedAt: FieldValue.serverTimestamp(),
      approvedBy: actorId,
      updatedAt: FieldValue.serverTimestamp(),
      updatedBy: actorId,
    });
    return ok(res, {
      id: req.params.decisionId,
      status: "approved",
    });
  },
);

autonomyRouter.post(
  "/decisions/:decisionId/reject",
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    const actorId = req.user?.uid;
    if (!actorId) return fail(res, 401, "missing_user", "Missing user.");
    const ref = db.collection("autonomyDecisions").doc(req.params.decisionId);
    const decision = await ref.get();
    if (!decision.exists) {
      return fail(res, 404, "decision_not_found", "Decision not found.");
    }
    if (decision.data()?.creatorId !== actorId && req.user?.admin !== true) {
      return fail(res, 403, "forbidden", "You cannot reject this decision.");
    }
    await ref.update({
      status: "rejected",
      rejectedAt: FieldValue.serverTimestamp(),
      rejectedBy: actorId,
      updatedAt: FieldValue.serverTimestamp(),
      updatedBy: actorId,
    });
    return ok(res, {
      id: req.params.decisionId,
      status: "rejected",
    });
  },
);
