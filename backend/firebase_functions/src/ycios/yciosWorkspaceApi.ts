import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { getProject, updateProjectStatus } from './yciosRepository';

const db = getFirestore();

export const createYciosProject = onCall(
  { region: 'europe-west2' },
  async (request) => {
    const creatorId = request.auth?.uid;
    if (!creatorId) throw new HttpsError('unauthenticated', 'Sign in required');

    const title = String(request.data?.title ?? '').trim();
    if (!title) throw new HttpsError('invalid-argument', 'Project title required');

    const ref = db.collection('yciosProjects').doc();
    await ref.set({
      id: ref.id,
      creatorId,
      title,
      description: String(request.data?.description ?? '').trim(),
      status: 'active',
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    // Snapshot initial version
    await db.collection('yciosProjectVersions').add({
      projectId: ref.id,
      creatorId,
      versionNumber: 1,
      snapshot: { title, description: request.data?.description ?? '' },
      createdAt: FieldValue.serverTimestamp(),
    });

    return { ok: true, projectId: ref.id };
  },
);

export const archiveYciosProject = onCall(
  { region: 'europe-west2' },
  async (request) => {
    const creatorId = request.auth?.uid;
    if (!creatorId) throw new HttpsError('unauthenticated', 'Sign in required');

    const projectId = String(request.data?.projectId ?? '');
    const project = await getProject(projectId);
    if (!project) throw new HttpsError('not-found', 'Project not found');
    if (project.creatorId !== creatorId)
      throw new HttpsError('permission-denied', 'Not your project');

    await updateProjectStatus(projectId, 'archived');
    return { ok: true };
  },
);

export const restoreYciosProject = onCall(
  { region: 'europe-west2' },
  async (request) => {
    const creatorId = request.auth?.uid;
    if (!creatorId) throw new HttpsError('unauthenticated', 'Sign in required');

    const projectId = String(request.data?.projectId ?? '');
    const project = await getProject(projectId);
    if (!project) throw new HttpsError('not-found', 'Project not found');
    if (project.creatorId !== creatorId)
      throw new HttpsError('permission-denied', 'Not your project');

    await updateProjectStatus(projectId, 'restored');
    return { ok: true };
  },
);

export const duplicateYciosProject = onCall(
  { region: 'europe-west2' },
  async (request) => {
    const creatorId = request.auth?.uid;
    if (!creatorId) throw new HttpsError('unauthenticated', 'Sign in required');

    const projectId = String(request.data?.projectId ?? '');
    const project = await getProject(projectId);
    if (!project) throw new HttpsError('not-found', 'Project not found');
    if (project.creatorId !== creatorId)
      throw new HttpsError('permission-denied', 'Not your project');

    const ref = db.collection('yciosProjects').doc();
    await ref.set({
      id: ref.id,
      creatorId,
      title: `${project.title} (Copy)`,
      description: project.description ?? '',
      status: 'active',
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    return { ok: true, projectId: ref.id };
  },
);

export const enqueueYciosRenderJob = onCall(
  { region: 'europe-west2' },
  async (request) => {
    const creatorId = request.auth?.uid;
    if (!creatorId) throw new HttpsError('unauthenticated', 'Sign in required');

    const projectId = String(request.data?.projectId ?? '');
    const jobType = String(request.data?.jobType ?? 'render');
    if (!projectId) throw new HttpsError('invalid-argument', 'projectId required');

    const ref = db.collection('yciosRenderJobs').doc();
    await ref.set({
      id: ref.id,
      creatorId,
      projectId,
      jobType,
      status: 'queued',
      progress: 0,
      outputUrl: null,
      error: null,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    return { ok: true, renderJobId: ref.id };
  },
);
