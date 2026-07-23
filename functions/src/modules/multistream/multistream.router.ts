import { Router } from "express";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { requireAuth, AuthenticatedRequest } from "../../core/http/requireAuth";
import { fail, ok } from "../../core/http/respond";
import {
  CreateDestinationSchema,
  CreateLiveSessionSchema,
  UpdateLiveSessionStatusSchema,
} from "./multistream.schema";

export const multistreamRouter = Router();
const db = getFirestore();

multistreamRouter.get("/status", requireAuth, async (_req, res) => {
  return ok(res, {
    module: "multistream",
    status: "ready",
  });
});

multistreamRouter.get(
  "/sessions",
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    const uid = req.user?.uid;
    if (!uid) return fail(res, 401, "missing_user", "Missing user.");

    const snapshot = await db
      .collection("liveSessions")
      .where("creatorId", "==", uid)
      .orderBy("updatedAt", "desc")
      .limit(100)
      .get();

    return ok(res, {
      sessions: snapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      })),
    });
  },
);

multistreamRouter.post(
  "/sessions",
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    const uid = req.user?.uid;
    if (!uid) return fail(res, 401, "missing_user", "Missing user.");

    const parsed = CreateLiveSessionSchema.safeParse(req.body);

    if (!parsed.success) {
      return fail(
        res,
        400,
        "invalid_live_session_payload",
        "Invalid live session payload.",
        parsed.error.flatten(),
      );
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

// Route to update a live session's status (start/end/etc)
multistreamRouter.patch(
  "/sessions/:id/status",
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    const uid = req.user?.uid;
    if (!uid) return fail(res, 401, "missing_user", "Missing user.");

    const parsed = UpdateLiveSessionStatusSchema.safeParse(req.body);
    if (!parsed.success) {
      return fail(
        res,
        400,
        "invalid_status_payload",
        "Invalid status payload.",
        parsed.error.flatten(),
      );
    }

    const { status } = parsed.data;
    const sessionRef = db.collection("liveSessions").doc(req.params.id);
    const doc = await sessionRef.get();

    if (!doc.exists) {
      return fail(res, 404, "session_not_found", "Session not found.");
    }

    const data = doc.data();
    if (data?.creatorId !== uid) {
      return fail(res, 403, "forbidden", "Unauthorized to update this session.");
    }

    const update: any = {
      status,
      updatedAt: FieldValue.serverTimestamp(),
      updatedBy: uid,
    };

    if (status === "live") {
      update.startedAt = FieldValue.serverTimestamp();
    }
    if (status === "ended") {
      update.endedAt = FieldValue.serverTimestamp();
    }

    await sessionRef.update(update);

    return ok(res, {
      id: req.params.id,
      status,
      ...update,
    });
  },
);

// Route to create a destination for a session
multistreamRouter.post(
  "/sessions/:id/destinations",
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    const uid = req.user?.uid;
    if (!uid) return fail(res, 401, "missing_user", "Missing user.");

    const sessionRef = db.collection("liveSessions").doc(req.params.id);
    const sessionDoc = await sessionRef.get();

    if (!sessionDoc.exists) {
      return fail(res, 404, "session_not_found", "Session not found.");
    }

    const sessionData = sessionDoc.data();
    if (sessionData?.creatorId !== uid) {
      return fail(res, 403, "forbidden", "Unauthorized to add destinations to this session.");
    }

    const parsed = CreateDestinationSchema.safeParse(req.body);
    if (!parsed.success) {
      return fail(
        res,
        400,
        "invalid_destination_payload",
        "Invalid destination payload.",
        parsed.error.flatten(),
      );
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

// Route to delete a destination
multistreamRouter.delete(
  "/destinations/:id",
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    const uid = req.user?.uid;
    if (!uid) return fail(res, 401, "missing_user", "Missing user.");

    const destRef = db.collection("liveDestinations").doc(req.params.id);
    const destDoc = await destRef.get();

    if (!destDoc.exists) {
      return fail(res, 404, "destination_not_found", "Destination not found.");
    }

    const destData = destDoc.data();
    if (destData?.creatorId !== uid) {
      return fail(res, 403, "forbidden", "Unauthorized to delete this destination.");
    }

    await destRef.delete();

    return ok(res, {
      id: req.params.id,
      deleted: true,
    });
  },
);
