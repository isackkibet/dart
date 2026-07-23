import { Router } from "express";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { AuthenticatedRequest, requireAuth } from "../../core/http/requireAuth";
import { fail, ok } from "../../core/http/respond";
import { GenerateClipsSchema, UpdateClipStatusSchema } from "./clipFactory.schema";

export const clipFactoryRouter = Router();
const db = getFirestore();

clipFactoryRouter.get("/status", requireAuth, async (_req, res) => {
  return ok(res, {
    module: "clip_factory",
    status: "ready",
  });
});

clipFactoryRouter.get(
  "/sessions/:sessionId/replay",
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    const uid = req.user?.uid;
    if (!uid) return fail(res, 401, "missing_user", "Missing user.");
    const sessionId = req.params.sessionId;
    const snapshot = await db
      .collection("sessionReplays")
      .where("sessionId", "==", sessionId)
      .limit(1)
      .get();
    if (snapshot.empty) {
      return ok(res, { replay: null });
    }
    const doc = snapshot.docs[0];
    const data = doc.data();
    if (data.creatorId !== uid && req.user?.admin !== true) {
      return fail(res, 403, "forbidden", "You cannot view this replay.");
    }
    return ok(res, {
      replay: { id: doc.id, ...data },
    });
  },
);

clipFactoryRouter.get(
  "/sessions/:sessionId/clips",
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    const uid = req.user?.uid;
    if (!uid) return fail(res, 401, "missing_user", "Missing user.");
    const sessionId = req.params.sessionId;
    const snapshot = await db
      .collection("clipSegments")
      .where("sessionId", "==", sessionId)
      .orderBy("startOffsetSeconds", "asc")
      .get();
    const clips = snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
    return ok(res, { clips });
  },
);

clipFactoryRouter.post(
  "/sessions/:sessionId/clips/generate",
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    const uid = req.user?.uid;
    if (!uid) return fail(res, 401, "missing_user", "Missing user.");
    const parsed = GenerateClipsSchema.safeParse(req.body ?? {});
    if (!parsed.success) {
      return fail(
        res,
        400,
        "invalid_clip_generate_payload",
        "Invalid clip generation payload.",
        parsed.error.flatten(),
      );
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

    const proposedClips: Array<{
      title: string;
      startOffsetSeconds: number;
      endOffsetSeconds: number;
      triggerEventType: string;
      triggerScore: number;
      suggestedPlatforms: string[];
    }> = [];

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
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
        createdBy: uid,
        updatedBy: uid,
      };
      batch.set(doc, payload);
      created.push({ id: doc.id, ...payload });
    }
    await batch.commit();
    return ok(
      res,
      {
        generatedCount: created.length,
        clips: created,
      },
      201,
    );
  },
);

clipFactoryRouter.patch(
  "/sessions/:sessionId/clips/:clipId",
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    const uid = req.user?.uid;
    if (!uid) return fail(res, 401, "missing_user", "Missing user.");
    const parsed = UpdateClipStatusSchema.safeParse(req.body);
    if (!parsed.success) {
      return fail(
        res,
        400,
        "invalid_clip_status_payload",
        "Invalid clip status payload.",
        parsed.error.flatten(),
      );
    }
    const ref = db.collection("clipSegments").doc(req.params.clipId);
    const clip = await ref.get();
    if (!clip.exists) {
      return fail(res, 404, "clip_not_found", "Clip segment not found.");
    }
    if (clip.data()?.creatorId !== uid && req.user?.admin !== true) {
      return fail(res, 403, "forbidden", "You cannot update this clip.");
    }
    await ref.update({
      status: parsed.data.status,
      updatedAt: FieldValue.serverTimestamp(),
      updatedBy: uid,
    });
    return ok(res, {
      id: req.params.clipId,
      status: parsed.data.status,
    });
  },
);

clipFactoryRouter.post(
  "/sessions/:sessionId/clips/:clipId/distribute",
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    const uid = req.user?.uid;
    if (!uid) return fail(res, 401, "missing_user", "Missing user.");
    const ref = db.collection("clipSegments").doc(req.params.clipId);
    const clip = await ref.get();
    if (!clip.exists) {
      return fail(res, 404, "clip_not_found", "Clip segment not found.");
    }
    if (clip.data()?.creatorId !== uid && req.user?.admin !== true) {
      return fail(res, 403, "forbidden", "You cannot distribute this clip.");
    }
    if (clip.data()?.status !== "approved") {
      return fail(
        res,
        400,
        "clip_not_approved",
        "Only approved clips can be distributed.",
      );
    }
    await ref.update({
      status: "distributed",
      distributedAt: FieldValue.serverTimestamp(),
      distributedBy: uid,
      updatedAt: FieldValue.serverTimestamp(),
      updatedBy: uid,
    });
    return ok(res, {
      id: req.params.clipId,
      status: "distributed",
      message: "Clip queued for platform distribution.",
    });
  },
);
