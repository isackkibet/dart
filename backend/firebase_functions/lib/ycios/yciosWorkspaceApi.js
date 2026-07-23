"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.enqueueYciosRenderJob = exports.duplicateYciosProject = exports.restoreYciosProject = exports.archiveYciosProject = exports.createYciosProject = void 0;
const https_1 = require("firebase-functions/v2/https");
const firestore_1 = require("firebase-admin/firestore");
const yciosRepository_1 = require("./yciosRepository");
const db = (0, firestore_1.getFirestore)();
exports.createYciosProject = (0, https_1.onCall)({ region: 'europe-west2' }, async (request) => {
    const creatorId = request.auth?.uid;
    if (!creatorId)
        throw new https_1.HttpsError('unauthenticated', 'Sign in required');
    const title = String(request.data?.title ?? '').trim();
    if (!title)
        throw new https_1.HttpsError('invalid-argument', 'Project title required');
    const ref = db.collection('yciosProjects').doc();
    await ref.set({
        id: ref.id,
        creatorId,
        title,
        description: String(request.data?.description ?? '').trim(),
        status: 'active',
        createdAt: firestore_1.FieldValue.serverTimestamp(),
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
    });
    // Snapshot initial version
    await db.collection('yciosProjectVersions').add({
        projectId: ref.id,
        creatorId,
        versionNumber: 1,
        snapshot: { title, description: request.data?.description ?? '' },
        createdAt: firestore_1.FieldValue.serverTimestamp(),
    });
    return { ok: true, projectId: ref.id };
});
exports.archiveYciosProject = (0, https_1.onCall)({ region: 'europe-west2' }, async (request) => {
    const creatorId = request.auth?.uid;
    if (!creatorId)
        throw new https_1.HttpsError('unauthenticated', 'Sign in required');
    const projectId = String(request.data?.projectId ?? '');
    const project = await (0, yciosRepository_1.getProject)(projectId);
    if (!project)
        throw new https_1.HttpsError('not-found', 'Project not found');
    if (project.creatorId !== creatorId)
        throw new https_1.HttpsError('permission-denied', 'Not your project');
    await (0, yciosRepository_1.updateProjectStatus)(projectId, 'archived');
    return { ok: true };
});
exports.restoreYciosProject = (0, https_1.onCall)({ region: 'europe-west2' }, async (request) => {
    const creatorId = request.auth?.uid;
    if (!creatorId)
        throw new https_1.HttpsError('unauthenticated', 'Sign in required');
    const projectId = String(request.data?.projectId ?? '');
    const project = await (0, yciosRepository_1.getProject)(projectId);
    if (!project)
        throw new https_1.HttpsError('not-found', 'Project not found');
    if (project.creatorId !== creatorId)
        throw new https_1.HttpsError('permission-denied', 'Not your project');
    await (0, yciosRepository_1.updateProjectStatus)(projectId, 'restored');
    return { ok: true };
});
exports.duplicateYciosProject = (0, https_1.onCall)({ region: 'europe-west2' }, async (request) => {
    const creatorId = request.auth?.uid;
    if (!creatorId)
        throw new https_1.HttpsError('unauthenticated', 'Sign in required');
    const projectId = String(request.data?.projectId ?? '');
    const project = await (0, yciosRepository_1.getProject)(projectId);
    if (!project)
        throw new https_1.HttpsError('not-found', 'Project not found');
    if (project.creatorId !== creatorId)
        throw new https_1.HttpsError('permission-denied', 'Not your project');
    const ref = db.collection('yciosProjects').doc();
    await ref.set({
        id: ref.id,
        creatorId,
        title: `${project.title} (Copy)`,
        description: project.description ?? '',
        status: 'active',
        createdAt: firestore_1.FieldValue.serverTimestamp(),
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
    });
    return { ok: true, projectId: ref.id };
});
exports.enqueueYciosRenderJob = (0, https_1.onCall)({ region: 'europe-west2' }, async (request) => {
    const creatorId = request.auth?.uid;
    if (!creatorId)
        throw new https_1.HttpsError('unauthenticated', 'Sign in required');
    const projectId = String(request.data?.projectId ?? '');
    const jobType = String(request.data?.jobType ?? 'render');
    if (!projectId)
        throw new https_1.HttpsError('invalid-argument', 'projectId required');
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
        createdAt: firestore_1.FieldValue.serverTimestamp(),
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
    });
    return { ok: true, renderJobId: ref.id };
});
