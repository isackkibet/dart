"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.yciosRenderJobProcessor = void 0;
const firestore_1 = require("firebase-functions/v2/firestore");
const yciosRepository_1 = require("./yciosRepository");
// Triggered when a render job enters the queue. Routes to the correct render pipeline.
exports.yciosRenderJobProcessor = (0, firestore_1.onDocumentCreated)({
    document: 'yciosRenderJobs/{jobId}',
    region: 'europe-west2',
    timeoutSeconds: 300,
    memory: '1GiB',
}, async (event) => {
    const jobId = event.params.jobId;
    const job = event.data?.data();
    if (!job || job.status !== 'queued')
        return;
    try {
        await (0, yciosRepository_1.updateRenderJobProgress)(jobId, 10, 'processing');
        await _processRenderJob(job);
        await (0, yciosRepository_1.updateRenderJobProgress)(jobId, 100, 'completed', undefined, undefined);
    }
    catch (err) {
        const message = err instanceof Error ? err.message : String(err);
        await (0, yciosRepository_1.updateRenderJobProgress)(jobId, 0, 'failed', undefined, message);
    }
});
async function _processRenderJob(job) {
    const jobType = String(job.jobType ?? 'render');
    // Phase 2: wire to actual rendering pipelines per jobType.
    // jobTypes: 'caption' | 'thumbnail' | 'trim' | 'film' | 'voiceover' | 'color_grade'
    void jobType;
}
