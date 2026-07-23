import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { updateRenderJobProgress } from './yciosRepository';

// Triggered when a render job enters the queue. Routes to the correct render pipeline.
export const yciosRenderJobProcessor = onDocumentCreated(
  {
    document: 'yciosRenderJobs/{jobId}',
    region: 'europe-west2',
    timeoutSeconds: 300,
    memory: '1GiB',
  },
  async (event) => {
    const jobId = event.params.jobId;
    const job = event.data?.data();
    if (!job || job.status !== 'queued') return;

    try {
      await updateRenderJobProgress(jobId, 10, 'processing');
      await _processRenderJob(job);
      await updateRenderJobProgress(jobId, 100, 'completed', undefined, undefined);
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      await updateRenderJobProgress(jobId, 0, 'failed', undefined, message);
    }
  },
);

async function _processRenderJob(job: Record<string, unknown>): Promise<void> {
  const jobType = String(job.jobType ?? 'render');
  // Phase 2: wire to actual rendering pipelines per jobType.
  // jobTypes: 'caption' | 'thumbnail' | 'trim' | 'film' | 'voiceover' | 'color_grade'
  void jobType;
}
