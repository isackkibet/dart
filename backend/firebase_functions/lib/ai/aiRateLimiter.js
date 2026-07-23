"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.assertAiRateLimit = assertAiRateLimit;
const firebaseAdmin_1 = require("../shared/firebaseAdmin");
async function assertAiRateLimit(userId) {
    const today = new Date().toISOString().slice(0, 10);
    const ref = firebaseAdmin_1.db.collection('aiUsageDaily').doc(`${userId}_${today}`);
    await firebaseAdmin_1.db.runTransaction(async (tx) => {
        const doc = await tx.get(ref);
        const count = doc.exists ? Number(doc.data()?.count ?? 0) : 0;
        const maxDaily = Number(process.env.AI_DAILY_JOB_LIMIT ?? 50);
        if (count >= maxDaily) {
            throw new Error('Daily AI job limit reached');
        }
        tx.set(ref, {
            userId,
            date: today,
            count: firebaseAdmin_1.FieldValue.increment(1),
            updatedAt: firebaseAdmin_1.FieldValue.serverTimestamp(),
        }, { merge: true });
    });
}
