import { Router } from "express";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { AuthenticatedRequest, requireAuth } from "../../core/http/requireAuth";
import { fail, ok } from "../../core/http/respond";
import { DispatchJobSchema, UpdateJobStatusSchema } from "./mediaPipeline.schema";

export const mediaPipelineRouter = Router();
const db = getFirestore();

// ─── Status ───────────────────────────────────────────────────────────────────
mediaPipelineRouter.get("/status", requireAuth, async (_req, res) => {
  return ok(res, { module: "media_pipeline", status: "ready" });
});

// ─── List jobs ─────────────────────────────────────────────────────────────────
mediaPipelineRouter.get(
  "/jobs",
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    const uid = req.user?.uid;
    if (!uid) return fail(res, 401, "missing_user", "Missing user.");

    const statusFilter = req.query.status as string | undefined;

    let query = db
      .collection("mediaJobs")
      .where("creatorId", "==", uid)
      .orderBy("createdAt", "desc")
      .limit(50);

    if (statusFilter) {
      query = db
        .collection("mediaJobs")
        .where("creatorId", "==", uid)
        .where("status", "==", statusFilter)
        .orderBy("createdAt", "desc")
        .limit(50);
    }

    const snap = await query.get();
    const jobs = snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
    return ok(res, { jobs, total: jobs.length });
  },
);

// ─── Get single job ────────────────────────────────────────────────────────────
mediaPipelineRouter.get(
  "/jobs/:jobId",
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    const uid = req.user?.uid;
    if (!uid) return fail(res, 401, "missing_user", "Missing user.");

    const doc = await db.collection("mediaJobs").doc(req.params.jobId).get();
    if (!doc.exists) {
      return fail(res, 404, "job_not_found", "Media job not found.");
    }
    if (doc.data()?.creatorId !== uid && req.user?.admin !== true) {
      return fail(res, 403, "forbidden", "Access denied.");
    }
    return ok(res, { id: doc.id, ...doc.data() });
  },
);

// ─── Dispatch new job ──────────────────────────────────────────────────────────
mediaPipelineRouter.post(
  "/jobs",
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    const uid = req.user?.uid;
    if (!uid) return fail(res, 401, "missing_user", "Missing user.");

    const parsed = DispatchJobSchema.safeParse(req.body);
    if (!parsed.success) {
      return fail(
        res,
        400,
        "invalid_dispatch_payload",
        "Invalid job dispatch payload.",
        parsed.error.flatten(),
      );
    }

    const {
      jobType,
      inputRef,
      sessionId,
      clipSegmentId,
      config,
      priority,
      maxRetries,
    } = parsed.data;

    const jobData = {
      creatorId: uid,
      jobType,
      inputRef,
      ...(sessionId ? { sessionId } : {}),
      ...(clipSegmentId ? { clipSegmentId } : {}),
      config: config ?? {
        outputFormat: "mp4",
        resolution: "720p",
        videoBitrate: 2500,
        fps: 30,
        audioBitrate: 128,
        watermarkEnabled: false,
      },
      priority,
      maxRetries,
      retryCount: 0,
      status: "queued",
      progressPercent: 0,
      outputRef: null,
      errorMessage: null,
      startedAt: null,
      completedAt: null,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
      createdBy: uid,
      updatedBy: uid,
    };

    const ref = await db.collection("mediaJobs").add(jobData);
    return ok(res, { id: ref.id, ...jobData }, 201);
  },
);

// ─── Cancel job ────────────────────────────────────────────────────────────────
mediaPipelineRouter.patch(
  "/jobs/:jobId/cancel",
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    const uid = req.user?.uid;
    if (!uid) return fail(res, 401, "missing_user", "Missing user.");

    const ref = db.collection("mediaJobs").doc(req.params.jobId);
    const doc = await ref.get();

    if (!doc.exists) {
      return fail(res, 404, "job_not_found", "Media job not found.");
    }
    if (doc.data()?.creatorId !== uid && req.user?.admin !== true) {
      return fail(res, 403, "forbidden", "Access denied.");
    }

    const currentStatus = doc.data()?.status;
    if (!["queued", "processing"].includes(currentStatus)) {
      return fail(
        res,
        400,
        "job_not_cancellable",
        `Job with status "${currentStatus}" cannot be cancelled.`,
      );
    }

    await ref.update({
      status: "cancelled",
      updatedAt: FieldValue.serverTimestamp(),
      updatedBy: uid,
    });

    return ok(res, { id: req.params.jobId, status: "cancelled" });
  },
);

// ─── Retry failed job ──────────────────────────────────────────────────────────
mediaPipelineRouter.post(
  "/jobs/:jobId/retry",
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    const uid = req.user?.uid;
    if (!uid) return fail(res, 401, "missing_user", "Missing user.");

    const ref = db.collection("mediaJobs").doc(req.params.jobId);
    const doc = await ref.get();

    if (!doc.exists) {
      return fail(res, 404, "job_not_found", "Media job not found.");
    }
    if (doc.data()?.creatorId !== uid && req.user?.admin !== true) {
      return fail(res, 403, "forbidden", "Access denied.");
    }

    const { status, retryCount, maxRetries } = doc.data() as {
      status: string;
      retryCount: number;
      maxRetries: number;
    };

    if (status !== "failed") {
      return fail(res, 400, "job_not_failed", "Only failed jobs can be retried.");
    }
    if (retryCount >= maxRetries) {
      return fail(
        res,
        400,
        "max_retries_exceeded",
        `Max retries (${maxRetries}) already reached.`,
      );
    }

    await ref.update({
      status: "queued",
      retryCount: retryCount + 1,
      errorMessage: null,
      progressPercent: 0,
      startedAt: null,
      completedAt: null,
      updatedAt: FieldValue.serverTimestamp(),
      updatedBy: uid,
    });

    return ok(res, {
      id: req.params.jobId,
      status: "queued",
      retryCount: retryCount + 1,
    });
  },
);

// ─── Worker status update (internal) ──────────────────────────────────────────
mediaPipelineRouter.patch(
  "/jobs/:jobId/status",
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    const uid = req.user?.uid;
    if (!uid) return fail(res, 401, "missing_user", "Missing user.");

    const parsed = UpdateJobStatusSchema.safeParse(req.body);
    if (!parsed.success) {
      return fail(
        res,
        400,
        "invalid_status_payload",
        "Invalid status update payload.",
        parsed.error.flatten(),
      );
    }

    const ref = db.collection("mediaJobs").doc(req.params.jobId);
    const doc = await ref.get();
    if (!doc.exists) {
      return fail(res, 404, "job_not_found", "Media job not found.");
    }

    const updates: Record<string, unknown> = {
      status: parsed.data.status,
      updatedAt: FieldValue.serverTimestamp(),
      updatedBy: uid,
    };

    if (parsed.data.progressPercent !== undefined) {
      updates.progressPercent = parsed.data.progressPercent;
    }
    if (parsed.data.errorMessage !== undefined) {
      updates.errorMessage = parsed.data.errorMessage;
    }
    if (parsed.data.outputRef !== undefined) {
      updates.outputRef = parsed.data.outputRef;
    }
    if (parsed.data.status === "processing" && !doc.data()?.startedAt) {
      updates.startedAt = FieldValue.serverTimestamp();
    }
    if (["completed", "failed", "cancelled"].includes(parsed.data.status)) {
      updates.completedAt = FieldValue.serverTimestamp();
    }

    await ref.update(updates);
    return ok(res, { id: req.params.jobId, ...updates });
  },
);
