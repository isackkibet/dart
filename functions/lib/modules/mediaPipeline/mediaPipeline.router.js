"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.mediaPipelineRouter = void 0;
const express_1 = require("express");
const firestore_1 = require("firebase-admin/firestore");
const requireAuth_1 = require("../../core/http/requireAuth");
const respond_1 = require("../../core/http/respond");
const mediaPipeline_schema_1 = require("./mediaPipeline.schema");
exports.mediaPipelineRouter = (0, express_1.Router)();
const db = (0, firestore_1.getFirestore)();
// ─── Status ───────────────────────────────────────────────────────────────────
exports.mediaPipelineRouter.get("/status", requireAuth_1.requireAuth, async (_req, res) => {
    return (0, respond_1.ok)(res, { module: "media_pipeline", status: "ready" });
});
// ─── List jobs ─────────────────────────────────────────────────────────────────
exports.mediaPipelineRouter.get("/jobs", requireAuth_1.requireAuth, async (req, res) => {
    const uid = req.user?.uid;
    if (!uid)
        return (0, respond_1.fail)(res, 401, "missing_user", "Missing user.");
    const statusFilter = req.query.status;
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
    return (0, respond_1.ok)(res, { jobs, total: jobs.length });
});
// ─── Get single job ────────────────────────────────────────────────────────────
exports.mediaPipelineRouter.get("/jobs/:jobId", requireAuth_1.requireAuth, async (req, res) => {
    const uid = req.user?.uid;
    if (!uid)
        return (0, respond_1.fail)(res, 401, "missing_user", "Missing user.");
    const doc = await db.collection("mediaJobs").doc(req.params.jobId).get();
    if (!doc.exists) {
        return (0, respond_1.fail)(res, 404, "job_not_found", "Media job not found.");
    }
    if (doc.data()?.creatorId !== uid && req.user?.admin !== true) {
        return (0, respond_1.fail)(res, 403, "forbidden", "Access denied.");
    }
    return (0, respond_1.ok)(res, { id: doc.id, ...doc.data() });
});
// ─── Dispatch new job ──────────────────────────────────────────────────────────
exports.mediaPipelineRouter.post("/jobs", requireAuth_1.requireAuth, async (req, res) => {
    const uid = req.user?.uid;
    if (!uid)
        return (0, respond_1.fail)(res, 401, "missing_user", "Missing user.");
    const parsed = mediaPipeline_schema_1.DispatchJobSchema.safeParse(req.body);
    if (!parsed.success) {
        return (0, respond_1.fail)(res, 400, "invalid_dispatch_payload", "Invalid job dispatch payload.", parsed.error.flatten());
    }
    const { jobType, inputRef, sessionId, clipSegmentId, config, priority, maxRetries, } = parsed.data;
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
        createdAt: firestore_1.FieldValue.serverTimestamp(),
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
        createdBy: uid,
        updatedBy: uid,
    };
    const ref = await db.collection("mediaJobs").add(jobData);
    return (0, respond_1.ok)(res, { id: ref.id, ...jobData }, 201);
});
// ─── Cancel job ────────────────────────────────────────────────────────────────
exports.mediaPipelineRouter.patch("/jobs/:jobId/cancel", requireAuth_1.requireAuth, async (req, res) => {
    const uid = req.user?.uid;
    if (!uid)
        return (0, respond_1.fail)(res, 401, "missing_user", "Missing user.");
    const ref = db.collection("mediaJobs").doc(req.params.jobId);
    const doc = await ref.get();
    if (!doc.exists) {
        return (0, respond_1.fail)(res, 404, "job_not_found", "Media job not found.");
    }
    if (doc.data()?.creatorId !== uid && req.user?.admin !== true) {
        return (0, respond_1.fail)(res, 403, "forbidden", "Access denied.");
    }
    const currentStatus = doc.data()?.status;
    if (!["queued", "processing"].includes(currentStatus)) {
        return (0, respond_1.fail)(res, 400, "job_not_cancellable", `Job with status "${currentStatus}" cannot be cancelled.`);
    }
    await ref.update({
        status: "cancelled",
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
        updatedBy: uid,
    });
    return (0, respond_1.ok)(res, { id: req.params.jobId, status: "cancelled" });
});
// ─── Retry failed job ──────────────────────────────────────────────────────────
exports.mediaPipelineRouter.post("/jobs/:jobId/retry", requireAuth_1.requireAuth, async (req, res) => {
    const uid = req.user?.uid;
    if (!uid)
        return (0, respond_1.fail)(res, 401, "missing_user", "Missing user.");
    const ref = db.collection("mediaJobs").doc(req.params.jobId);
    const doc = await ref.get();
    if (!doc.exists) {
        return (0, respond_1.fail)(res, 404, "job_not_found", "Media job not found.");
    }
    if (doc.data()?.creatorId !== uid && req.user?.admin !== true) {
        return (0, respond_1.fail)(res, 403, "forbidden", "Access denied.");
    }
    const { status, retryCount, maxRetries } = doc.data();
    if (status !== "failed") {
        return (0, respond_1.fail)(res, 400, "job_not_failed", "Only failed jobs can be retried.");
    }
    if (retryCount >= maxRetries) {
        return (0, respond_1.fail)(res, 400, "max_retries_exceeded", `Max retries (${maxRetries}) already reached.`);
    }
    await ref.update({
        status: "queued",
        retryCount: retryCount + 1,
        errorMessage: null,
        progressPercent: 0,
        startedAt: null,
        completedAt: null,
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
        updatedBy: uid,
    });
    return (0, respond_1.ok)(res, {
        id: req.params.jobId,
        status: "queued",
        retryCount: retryCount + 1,
    });
});
// ─── Worker status update (internal) ──────────────────────────────────────────
exports.mediaPipelineRouter.patch("/jobs/:jobId/status", requireAuth_1.requireAuth, async (req, res) => {
    const uid = req.user?.uid;
    if (!uid)
        return (0, respond_1.fail)(res, 401, "missing_user", "Missing user.");
    const parsed = mediaPipeline_schema_1.UpdateJobStatusSchema.safeParse(req.body);
    if (!parsed.success) {
        return (0, respond_1.fail)(res, 400, "invalid_status_payload", "Invalid status update payload.", parsed.error.flatten());
    }
    const ref = db.collection("mediaJobs").doc(req.params.jobId);
    const doc = await ref.get();
    if (!doc.exists) {
        return (0, respond_1.fail)(res, 404, "job_not_found", "Media job not found.");
    }
    const updates = {
        status: parsed.data.status,
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
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
        updates.startedAt = firestore_1.FieldValue.serverTimestamp();
    }
    if (["completed", "failed", "cancelled"].includes(parsed.data.status)) {
        updates.completedAt = firestore_1.FieldValue.serverTimestamp();
    }
    await ref.update(updates);
    return (0, respond_1.ok)(res, { id: req.params.jobId, ...updates });
});
//# sourceMappingURL=mediaPipeline.router.js.map