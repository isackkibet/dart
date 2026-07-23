"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.yciosAgentDispatcher = exports.createYciosAgentTask = void 0;
const https_1 = require("firebase-functions/v2/https");
const firestore_1 = require("firebase-functions/v2/firestore");
const firestore_2 = require("firebase-admin/firestore");
const yciosRepository_1 = require("./yciosRepository");
const db = (0, firestore_2.getFirestore)();
exports.createYciosAgentTask = (0, https_1.onCall)({ region: 'europe-west2' }, async (request) => {
    const creatorId = request.auth?.uid;
    if (!creatorId)
        throw new https_1.HttpsError('unauthenticated', 'Sign in required');
    const projectId = String(request.data?.projectId ?? '');
    const agentType = String(request.data?.agentType ?? '');
    const prompt = String(request.data?.prompt ?? '').trim();
    if (!projectId || !agentType || !prompt) {
        throw new https_1.HttpsError('invalid-argument', 'projectId, agentType and prompt required');
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
        createdAt: firestore_2.FieldValue.serverTimestamp(),
        updatedAt: firestore_2.FieldValue.serverTimestamp(),
    });
    return { ok: true, taskId: ref.id };
});
// Triggered whenever a new agent task is created — routes to the correct agent.
exports.yciosAgentDispatcher = (0, firestore_1.onDocumentCreated)({
    document: 'yciosAgentTasks/{taskId}',
    region: 'europe-west2',
    timeoutSeconds: 120,
    memory: '512MiB',
}, async (event) => {
    const taskId = event.params.taskId;
    const task = event.data?.data();
    if (!task || task.status !== 'queued')
        return;
    await db.collection('yciosAgentTasks').doc(taskId).update({
        status: 'processing',
        updatedAt: firestore_2.FieldValue.serverTimestamp(),
    });
    try {
        const result = await _dispatchToAgent(task.agentType, task.prompt, task);
        await (0, yciosRepository_1.updateAgentTaskResult)(taskId, 'completed', result);
    }
    catch (err) {
        const message = err instanceof Error ? err.message : String(err);
        await (0, yciosRepository_1.updateAgentTaskResult)(taskId, 'failed', undefined, message);
    }
});
async function _dispatchToAgent(agentType, prompt, task) {
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
async function _captionAgent(prompt, _task) {
    return { agentType: 'CaptionAgent', captions: [], prompt, status: 'stub' };
}
async function _thumbnailAgent(prompt, _task) {
    return { agentType: 'ThumbnailAgent', thumbnailUrl: null, prompt, status: 'stub' };
}
async function _storyAgent(prompt, _task) {
    return { agentType: 'StoryAgent', script: null, prompt, status: 'stub' };
}
async function _directorAgent(prompt, _task) {
    return { agentType: 'DirectorAgent', shotList: [], prompt, status: 'stub' };
}
async function _editorAgent(prompt, _task) {
    return { agentType: 'EditorAgent', editInstructions: [], prompt, status: 'stub' };
}
async function _commerceAgent(prompt, _task) {
    return { agentType: 'CommerceAgent', products: [], prompt, status: 'stub' };
}
async function _growthAgent(prompt, _task) {
    return { agentType: 'GrowthAgent', growthTips: [], prompt, status: 'stub' };
}
