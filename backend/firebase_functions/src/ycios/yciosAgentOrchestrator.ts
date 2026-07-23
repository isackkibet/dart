import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { updateAgentTaskResult } from './yciosRepository';

const db = getFirestore();

export const createYciosAgentTask = onCall(
  { region: 'europe-west2' },
  async (request) => {
    const creatorId = request.auth?.uid;
    if (!creatorId) throw new HttpsError('unauthenticated', 'Sign in required');

    const projectId = String(request.data?.projectId ?? '');
    const agentType = String(request.data?.agentType ?? '');
    const prompt = String(request.data?.prompt ?? '').trim();

    if (!projectId || !agentType || !prompt) {
      throw new HttpsError(
        'invalid-argument',
        'projectId, agentType and prompt required',
      );
    }

    const ref = db.collection('yciosAgentTasks').doc();
    await ref.set({
      id: ref.id,
      creatorId,
      projectId,
      agentType,
      prompt,
      status: 'queued',
      result: null,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    return { ok: true, taskId: ref.id };
  },
);

// Triggered whenever a new agent task is created — routes to the correct agent.
export const yciosAgentDispatcher = onDocumentCreated(
  {
    document: 'yciosAgentTasks/{taskId}',
    region: 'europe-west2',
    timeoutSeconds: 120,
    memory: '512MiB',
  },
  async (event) => {
    const taskId = event.params.taskId;
    const task = event.data?.data();
    if (!task || task.status !== 'queued') return;

    await db.collection('yciosAgentTasks').doc(taskId).update({
      status: 'processing',
      updatedAt: FieldValue.serverTimestamp(),
    });

    try {
      const result = await _dispatchToAgent(task.agentType, task.prompt, task);
      await updateAgentTaskResult(taskId, 'completed', result);
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      await updateAgentTaskResult(taskId, 'failed', undefined, message);
    }
  },
);

async function _dispatchToAgent(
  agentType: string,
  prompt: string,
  task: Record<string, unknown>,
): Promise<Record<string, unknown>> {
  switch (agentType) {
    case 'CaptionAgent':
      return _captionAgent(prompt, task);
    case 'ThumbnailAgent':
      return _thumbnailAgent(prompt, task);
    case 'StoryAgent':
      return _storyAgent(prompt, task);
    case 'DirectorAgent':
      return _directorAgent(prompt, task);
    case 'EditorAgent':
      return _editorAgent(prompt, task);
    case 'CommerceAgent':
      return _commerceAgent(prompt, task);
    case 'GrowthAgent':
      return _growthAgent(prompt, task);
    default:
      throw new Error(`Unknown agentType: ${agentType}`);
  }
}

// ── Agent stubs — connect to YohPal Brain API in Phase 2 ─────────────────────

async function _captionAgent(
  prompt: string,
  _task: Record<string, unknown>,
): Promise<Record<string, unknown>> {
  return { agentType: 'CaptionAgent', captions: [], prompt, status: 'stub' };
}

async function _thumbnailAgent(
  prompt: string,
  _task: Record<string, unknown>,
): Promise<Record<string, unknown>> {
  return { agentType: 'ThumbnailAgent', thumbnailUrl: null, prompt, status: 'stub' };
}

async function _storyAgent(
  prompt: string,
  _task: Record<string, unknown>,
): Promise<Record<string, unknown>> {
  return { agentType: 'StoryAgent', script: null, prompt, status: 'stub' };
}

async function _directorAgent(
  prompt: string,
  _task: Record<string, unknown>,
): Promise<Record<string, unknown>> {
  return { agentType: 'DirectorAgent', shotList: [], prompt, status: 'stub' };
}

async function _editorAgent(
  prompt: string,
  _task: Record<string, unknown>,
): Promise<Record<string, unknown>> {
  return { agentType: 'EditorAgent', editInstructions: [], prompt, status: 'stub' };
}

async function _commerceAgent(
  prompt: string,
  _task: Record<string, unknown>,
): Promise<Record<string, unknown>> {
  return { agentType: 'CommerceAgent', products: [], prompt, status: 'stub' };
}

async function _growthAgent(
  prompt: string,
  _task: Record<string, unknown>,
): Promise<Record<string, unknown>> {
  return { agentType: 'GrowthAgent', growthTips: [], prompt, status: 'stub' };
}
