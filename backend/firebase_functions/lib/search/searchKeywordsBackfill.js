"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.searchKeywordsBackfill = void 0;
const https_1 = require("firebase-functions/v2/https");
const firebaseAdmin_1 = require("../shared/firebaseAdmin");
const searchKeywordsGenerator_1 = require("./searchKeywordsGenerator");
const TARGETS = ['videos', 'creatorProfiles', 'liveSessions', 'businessAccounts'];
exports.searchKeywordsBackfill = (0, https_1.onRequest)({ region: 'us-central1', timeoutSeconds: 540, memory: '1GiB' }, async (req, res) => {
    if (req.method !== 'POST') {
        res.status(405).json({ error: 'POST required' });
        return;
    }
    const statusRef = firebaseAdmin_1.db.collection('searchBackfillStatus').doc();
    await statusRef.set({
        id: statusRef.id,
        status: 'running',
        processed: 0,
        failed: 0,
        skipped: 0,
        startedAt: firebaseAdmin_1.FieldValue.serverTimestamp(),
    });
    let processed = 0;
    let failed = 0;
    let skipped = 0;
    for (const collection of TARGETS) {
        const snap = await firebaseAdmin_1.db.collection(collection).get();
        for (const doc of snap.docs) {
            try {
                const data = doc.data();
                const searchKeywords = (0, searchKeywordsGenerator_1.generateSearchKeywords)(data);
                if (searchKeywords.length === 0) {
                    skipped++;
                    continue;
                }
                await doc.ref.set({ searchKeywords, searchIndexedAt: firebaseAdmin_1.FieldValue.serverTimestamp() }, { merge: true });
                processed++;
            }
            catch (error) {
                failed++;
                await firebaseAdmin_1.db.collection('searchIndexAuditLogs').add({
                    collection,
                    docId: doc.id,
                    action: 'failed',
                    error: error instanceof Error ? error.message : String(error),
                    createdAt: firebaseAdmin_1.FieldValue.serverTimestamp(),
                });
            }
        }
    }
    await statusRef.update({
        status: 'completed',
        processed,
        failed,
        skipped,
        completedAt: firebaseAdmin_1.FieldValue.serverTimestamp(),
    });
    res.json({ ok: true, processed, failed, skipped });
});
