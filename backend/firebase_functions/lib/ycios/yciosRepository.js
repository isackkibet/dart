"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getProject = getProject;
exports.createProjectRecord = createProjectRecord;
exports.updateProjectStatus = updateProjectStatus;
exports.createAssetRecord = createAssetRecord;
exports.createRenderJobRecord = createRenderJobRecord;
exports.updateRenderJobProgress = updateRenderJobProgress;
exports.createAgentTaskRecord = createAgentTaskRecord;
exports.updateAgentTaskResult = updateAgentTaskResult;
const firestore_1 = require("firebase-admin/firestore");
const db = (0, firestore_1.getFirestore)();
async function getProject(projectId) {
    const snap = await db.collection('yciosProjects').doc(projectId).get();
    return snap.exists ? { id: snap.id, ...snap.data() } : null;
}
async function createProjectRecord(creatorId, title, description) {
    const ref = db.collection('yciosProjects').doc();
    await ref.set({
        id: ref.id,
        creatorId,
        title,
        description,
        status: 'active',
        createdAt: firestore_1.FieldValue.serverTimestamp(),
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
    });
    return ref.id;
}
async function updateProjectStatus(projectId, status) {
    await db.collection('yciosProjects').doc(projectId).update({
        status,
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
    });
}
async function createAssetRecord(asset) {
    const ref = db.collection('yciosAssets').doc();
    await ref.set({ id: ref.id, ...asset, createdAt: firestore_1.FieldValue.serverTimestamp() });
    return ref.id;
}
async function createRenderJobRecord(job) {
    const ref = db.collection('yciosRenderJobs').doc();
    await ref.set({
        id: ref.id,
        ...job,
        status: 'queued',
        progress: 0,
        createdAt: firestore_1.FieldValue.serverTimestamp(),
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
    });
    return ref.id;
}
async function updateRenderJobProgress(jobId, progress, status, outputUrl, error) {
    await db.collection('yciosRenderJobs').doc(jobId).update({
        progress,
        status,
        ...(outputUrl ? { outputUrl } : {}),
        ...(error ? { error } : {}),
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
        ...(status === 'completed' || status === 'failed'
            ? { completedAt: firestore_1.FieldValue.serverTimestamp() }
            : {}),
    });
}
async function createAgentTaskRecord(task) {
    const ref = db.collection('yciosAgentTasks').doc();
    await ref.set({
        id: ref.id,
        ...task,
        status: 'queued',
        result: null,
        createdAt: firestore_1.FieldValue.serverTimestamp(),
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
    });
    return ref.id;
}
async function updateAgentTaskResult(taskId, status, result, error) {
    await db.collection('yciosAgentTasks').doc(taskId).update({
        status,
        result: result ?? null,
        ...(error ? { error } : {}),
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
        ...(status === 'completed' || status === 'failed'
            ? { completedAt: firestore_1.FieldValue.serverTimestamp() }
            : {}),
    });
}
