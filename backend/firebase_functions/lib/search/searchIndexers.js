"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.businessSearchIndexer = exports.liveSearchIndexer = exports.creatorSearchIndexer = exports.videoSearchIndexer = void 0;
const firestore_1 = require("firebase-functions/v2/firestore");
const firebaseAdmin_1 = require("../shared/firebaseAdmin");
const searchKeywordsGenerator_1 = require("./searchKeywordsGenerator");
async function indexDocument(collection, docId, data) {
    const searchKeywords = (0, searchKeywordsGenerator_1.generateSearchKeywords)(data);
    await firebaseAdmin_1.db.collection(collection).doc(docId).set({ searchKeywords, searchIndexedAt: firebaseAdmin_1.FieldValue.serverTimestamp() }, { merge: true });
    await firebaseAdmin_1.db.collection('searchIndexAuditLogs').add({
        collection,
        docId,
        keywordCount: searchKeywords.length,
        action: 'indexed',
        createdAt: firebaseAdmin_1.FieldValue.serverTimestamp(),
    });
}
function shouldSkip(change) {
    if (!change.after.exists)
        return true;
    const after = change.after.data();
    if (!after)
        return true;
    if (!change.before.exists)
        return false;
    const before = change.before.data();
    // Strip indexing fields before comparing — prevents infinite write loop
    // when our own set({ searchKeywords }) re-triggers this function.
    const strip = (d) => {
        const { searchKeywords: _k, searchIndexedAt: _i, ...rest } = d;
        return rest;
    };
    return JSON.stringify(strip(before)) === JSON.stringify(strip(after));
}
exports.videoSearchIndexer = (0, firestore_1.onDocumentWritten)('videos/{videoId}', async (event) => {
    if (shouldSkip(event.data))
        return;
    await indexDocument('videos', event.params.videoId, event.data?.after.data() ?? {});
});
exports.creatorSearchIndexer = (0, firestore_1.onDocumentWritten)('creatorProfiles/{creatorId}', async (event) => {
    if (shouldSkip(event.data))
        return;
    await indexDocument('creatorProfiles', event.params.creatorId, event.data?.after.data() ?? {});
});
exports.liveSearchIndexer = (0, firestore_1.onDocumentWritten)('liveSessions/{sessionId}', async (event) => {
    if (shouldSkip(event.data))
        return;
    await indexDocument('liveSessions', event.params.sessionId, event.data?.after.data() ?? {});
});
exports.businessSearchIndexer = (0, firestore_1.onDocumentWritten)('businessAccounts/{businessId}', async (event) => {
    if (shouldSkip(event.data))
        return;
    await indexDocument('businessAccounts', event.params.businessId, event.data?.after.data() ?? {});
});
