import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { YciosProject, YciosAsset, YciosRenderJob, YciosAgentTask } from './yciosTypes';

const db = getFirestore();

export async function getProject(projectId: string): Promise<YciosProject | null> {
  const snap = await db.collection('yciosProjects').doc(projectId).get();
  return snap.exists ? ({ id: snap.id, ...snap.data() } as YciosProject) : null;
}

export async function createProjectRecord(
  creatorId: string,
  title: string,
  description: string,
): Promise<string> {
  const ref = db.collection('yciosProjects').doc();
  await ref.set({
    id: ref.id,
    creatorId,
    title,
    description,
    status: 'active',
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });
  return ref.id;
}

export async function updateProjectStatus(
  projectId: string,
  status: YciosProject['status'],
): Promise<void> {
  await db.collection('yciosProjects').doc(projectId).update({
    status,
    updatedAt: FieldValue.serverTimestamp(),
  });
}

export async function createAssetRecord(asset: Omit<YciosAsset, 'id'>): Promise<string> {
  const ref = db.collection('yciosAssets').doc();
  await ref.set({ id: ref.id, ...asset, createdAt: FieldValue.serverTimestamp() });
  return ref.id;
}

export async function createRenderJobRecord(
  job: Omit<YciosRenderJob, 'id' | 'status' | 'progress'>,
): Promise<string> {
  const ref = db.collection('yciosRenderJobs').doc();
  await ref.set({
    id: ref.id,
    ...job,
    status: 'queued',
    progress: 0,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });
  return ref.id;
}

export async function updateRenderJobProgress(
  jobId: string,
  progress: number,
  status: YciosRenderJob['status'],
  outputUrl?: string,
  error?: string,
): Promise<void> {
  await db.collection('yciosRenderJobs').doc(jobId).update({
    progress,
    status,
    ...(outputUrl ? { outputUrl } : {}),
    ...(error ? { error } : {}),
    updatedAt: FieldValue.serverTimestamp(),
    ...(status === 'completed' || status === 'failed'
      ? { completedAt: FieldValue.serverTimestamp() }
      : {}),
  });
}

export async function createAgentTaskRecord(
  task: Omit<YciosAgentTask, 'id' | 'status' | 'result'>,
): Promise<string> {
  const ref = db.collection('yciosAgentTasks').doc();
  await ref.set({
    id: ref.id,
    ...task,
    status: 'queued',
    result: null,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });
  return ref.id;
}

export async function updateAgentTaskResult(
  taskId: string,
  status: YciosAgentTask['status'],
  result?: Record<string, unknown>,
  error?: string,
): Promise<void> {
  await db.collection('yciosAgentTasks').doc(taskId).update({
    status,
    result: result ?? null,
    ...(error ? { error } : {}),
    updatedAt: FieldValue.serverTimestamp(),
    ...(status === 'completed' || status === 'failed'
      ? { completedAt: FieldValue.serverTimestamp() }
      : {}),
  });
}
