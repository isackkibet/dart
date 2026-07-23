"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.processAiVideoJob = void 0;
const https_1 = require("firebase-functions/v2/https");
const firebaseAdmin_1 = require("../shared/firebaseAdmin");
const promptTemplates_1 = require("./promptTemplates");
const yohpalBrainClient_1 = require("./yohpalBrainClient");
const aiRateLimiter_1 = require("./aiRateLimiter");
const SUPPORTED_TYPES = [
    'captions',
    'hooks',
    'hashtags',
    'viral_score',
    'thumbnail_ideas',
    'trim_suggestions',
];
exports.processAiVideoJob = (0, https_1.onRequest)({
    region: 'us-central1',
    cors: true,
    timeoutSeconds: 60,
    memory: '512MiB',
}, async (req, res) => {
    if (req.method !== 'POST') {
        res.status(405).json({ error: 'POST required' });
        return;
    }
    const { jobId, userId } = (req.body ?? {});
    if (!jobId || !userId) {
        res.status(400).json({ error: 'jobId and userId are required' });
        return;
    }
    const jobRef = firebaseAdmin_1.db.collection('aiVideoJobs').doc(jobId);
    try {
        const jobDoc = await jobRef.get();
        if (!jobDoc.exists) {
            res.status(404).json({ error: 'AI job not found' });
            return;
        }
        const job = jobDoc.data() ?? {};
        if (job.userId !== userId) {
            res.status(403).json({ error: 'User does not own this AI job' });
            return;
        }
        if (!SUPPORTED_TYPES.includes(job.type)) {
            res.status(400).json({ error: `Unsupported job type: ${job.type}` });
            return;
        }
        await (0, aiRateLimiter_1.assertAiRateLimit)(userId);
        await jobRef.update({
            status: 'processing',
            processingStartedAt: firebaseAdmin_1.FieldValue.serverTimestamp(),
            updatedAt: firebaseAdmin_1.FieldValue.serverTimestamp(),
        });
        await firebaseAdmin_1.db.collection('aiJobLogs').add({
            jobId,
            userId,
            videoId: job.videoId ?? '',
            type: job.type,
            action: 'AI_JOB_PROCESSING_STARTED',
            createdAt: firebaseAdmin_1.FieldValue.serverTimestamp(),
        });
        const prompt = (0, promptTemplates_1.buildPrompt)(job.type, (job.input ?? {}));
        const aiResult = await (0, yohpalBrainClient_1.callYohPalBrain)(prompt);
        const result = normalizeAiResult(job.type, aiResult.text);
        await jobRef.update({
            status: 'completed',
            result,
            provider: aiResult.provider,
            completedAt: firebaseAdmin_1.FieldValue.serverTimestamp(),
            updatedAt: firebaseAdmin_1.FieldValue.serverTimestamp(),
        });
        await firebaseAdmin_1.db.collection('aiJobLogs').add({
            jobId,
            userId,
            videoId: job.videoId ?? '',
            type: job.type,
            action: 'AI_JOB_COMPLETED',
            provider: aiResult.provider,
            createdAt: firebaseAdmin_1.FieldValue.serverTimestamp(),
        });
        res.json({ ok: true, jobId, status: 'completed', result });
    }
    catch (error) {
        const message = error instanceof Error ? error.message : 'AI processing failed';
        await jobRef.set({
            status: 'failed',
            error: message,
            failedAt: firebaseAdmin_1.FieldValue.serverTimestamp(),
            updatedAt: firebaseAdmin_1.FieldValue.serverTimestamp(),
        }, { merge: true });
        await firebaseAdmin_1.db.collection('aiJobLogs').add({
            jobId,
            userId,
            action: 'AI_JOB_FAILED',
            error: message,
            createdAt: firebaseAdmin_1.FieldValue.serverTimestamp(),
        });
        res.status(500).json({ ok: false, error: message });
    }
});
function normalizeAiResult(type, text) {
    if (type === 'viral_score') {
        const scoreMatch = text.match(/\b([0-9]{1,3})\b/);
        const score = scoreMatch ? Math.min(Number(scoreMatch[1]), 100) : null;
        return { score, explanation: text };
    }
    return {
        text,
        items: text
            .split('\n')
            .map((line) => line.replace(/^[-*\d.]+\s*/, '').trim())
            .filter(Boolean),
    };
}
