import { Router } from "express";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { AuthenticatedRequest, requireAuth } from "../../core/http/requireAuth";
import { fail, ok } from "../../core/http/respond";
import {
  MockIngestHeartbeatSchema,
  UpsertRoutePolicySchema,
} from "./streamOrchestration.schema";

export const streamOrchestrationRouter = Router();
const db = getFirestore();

streamOrchestrationRouter.get("/status", requireAuth, async (_req, res) => {
  return ok(res, {
    module: "stream_orchestration",
    status: "ready",
  });
});

streamOrchestrationRouter.get(
  "/sessions/:sessionId/policies",
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    const uid = req.user?.uid;
    if (!uid) return fail(res, 401, "missing_user", "Missing user.");
    const session = await db.collection("liveSessions").doc(req.params.sessionId).get();
    if (!session.exists) {
      return fail(res, 404, "session_not_found", "Live session not found.");
    }
    if (session.data()?.creatorId !== uid && req.user?.admin !== true) {
      return fail(res, 403, "forbidden", "You cannot view these policies.");
    }
    const snapshot = await db
      .collection("streamRoutePolicies")
      .where("sessionId", "==", req.params.sessionId)
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

streamOrchestrationRouter.post(
  "/policies",
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    const uid = req.user?.uid;
    if (!uid) return fail(res, 401, "missing_user", "Missing user.");
    const parsed = UpsertRoutePolicySchema.safeParse(req.body);
    if (!parsed.success) {
      return fail(
        res,
        400,
        "invalid_route_policy_payload",
        "Invalid stream route policy payload.",
        parsed.error.flatten(),
      );
    }
    const input = parsed.data;
    const session = await db.collection("liveSessions").doc(input.sessionId).get();
    if (!session.exists) {
      return fail(res, 404, "session_not_found", "Live session not found.");
    }
    if (session.data()?.creatorId !== uid && req.user?.admin !== true) {
      return fail(res, 403, "forbidden", "You cannot create this policy.");
    }
    const doc = db.collection("streamRoutePolicies").doc();
    const payload = {
      ...input,
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

streamOrchestrationRouter.post(
  "/mock-ingest/heartbeat",
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    const uid = req.user?.uid;
    if (!uid) return fail(res, 401, "missing_user", "Missing user.");
    const parsed = MockIngestHeartbeatSchema.safeParse(req.body);
    if (!parsed.success) {
      return fail(
        res,
        400,
        "invalid_mock_ingest_payload",
        "Invalid mock ingest heartbeat payload.",
        parsed.error.flatten(),
      );
    }
    const input = parsed.data;
    const session = await db.collection("liveSessions").doc(input.sessionId).get();
    if (!session.exists) {
      return fail(res, 404, "session_not_found", "Live session not found.");
    }
    if (session.data()?.creatorId !== uid && req.user?.admin !== true) {
      return fail(res, 403, "forbidden", "You cannot update this stream.");
    }
    await db.collection("streamHealth").doc(input.sessionId).set(
      {
        sessionId: input.sessionId,
        status: "healthy",
        ingestStatus: "mock_ingest_active",
        activeDestinations: input.activeDestinations,
        failedDestinations: input.failedDestinations,
        bitrateKbps: input.bitrateKbps,
        latencyMs: input.latencyMs,
        lastHeartbeatAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
        updatedBy: uid,
      },
      { merge: true },
    );
    return ok(res, {
      sessionId: input.sessionId,
      status: "healthy",
      heartbeatAccepted: true,
    });
  },
);

streamOrchestrationRouter.post(
  "/sessions/:sessionId/evaluate-routing",
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    const uid = req.user?.uid;
    if (!uid) return fail(res, 401, "missing_user", "Missing user.");
    const session = await db.collection("liveSessions").doc(req.params.sessionId).get();
    if (!session.exists) {
      return fail(res, 404, "session_not_found", "Live session not found.");
    }
    if (session.data()?.creatorId !== uid && req.user?.admin !== true) {
      return fail(res, 403, "forbidden", "You cannot evaluate this routing.");
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
        action:
          data.mode === "full"
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
    return ok(res, {
      sessionId: req.params.sessionId,
      routes,
    });
  },
);
