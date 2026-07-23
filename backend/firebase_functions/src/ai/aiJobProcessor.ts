import { onRequest } from 'firebase-functions/v2/https';
import { db, FieldValue } from '../shared/firebaseAdmin';
import { buildPrompt } from './promptTemplates';
import { callYohPalBrain } from './yohpalBrainClient';
import { assertAiRateLimit } from './aiRateLimiter';

const SUPPORTED_TYPES = [
  'captions',
  'hooks',
  'hashtags',
  'viral_score',
  'thumbnail_ideas',
  'trim_suggestions',
];

export const processAiVideoJob = onRequest(
  {
    region: 'us-central1',
    cors: true,
    timeoutSeconds: 60,
    memory: '512MiB',
  },
  async (req, res) => {
    if (req.method !== 'POST') {
      res.status(405).json({ error: 'POST required' });
      return;
    }

    const { jobId, userId } = (req.body ?? {}) as { jobId?: string; userId?: string };

    if (!jobId || !userId) {
      res.status(400).json({ error: 'jobId and userId are required' });
      return;
    }

    const jobRef = db.collection('aiVideoJobs').doc(jobId);

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

      await assertAiRateLimit(userId);

      await jobRef.update({
        status: 'processing',
        processingStartedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });

      await db.collection('aiJobLogs').add({
        jobId,
        userId,
        videoId: job.videoId ?? '',
        type: job.type,
        action: 'AI_JOB_PROCESSING_STARTED',
        createdAt: FieldValue.serverTimestamp(),
      });

      const prompt = buildPrompt(job.type, (job.input ?? {}) as Record<string, unknown>);
      const aiResult = await callYohPalBrain(prompt);
      const result = normalizeAiResult(job.type, aiResult.text);

      await jobRef.update({
        status: 'completed',
        result,
        provider: aiResult.provider,
        completedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });

      await db.collection('aiJobLogs').add({
        jobId,
        userId,
        videoId: job.videoId ?? '',
        type: job.type,
        action: 'AI_JOB_COMPLETED',
        provider: aiResult.provider,
        createdAt: FieldValue.serverTimestamp(),
      });

      res.json({ ok: true, jobId, status: 'completed', result });
    } catch (error: unknown) {
      const message = error instanceof Error ? error.message : 'AI processing failed';

      await jobRef.set(
        {
          status: 'failed',
          error: message,
          failedAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );

      await db.collection('aiJobLogs').add({
        jobId,
        userId,
        action: 'AI_JOB_FAILED',
        error: message,
        createdAt: FieldValue.serverTimestamp(),
      });

      res.status(500).json({ ok: false, error: message });
    }
  },
);

function normalizeAiResult(type: string, text: string): Record<string, unknown> {
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
