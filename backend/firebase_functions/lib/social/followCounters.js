"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.onFollowDeleted = exports.onFollowCreated = void 0;
const firestore_1 = require("firebase-functions/v2/firestore");
const firestore_2 = require("firebase-admin/firestore");
const db = () => (0, firestore_2.getFirestore)();
/**
 * Increments creatorProfiles/{creatorUid}.followerCount when a follow doc is created.
 * Admin SDK bypasses Firestore security rules, so the follower does not need
 * write access to the creator's profile document.
 */
exports.onFollowCreated = (0, firestore_1.onDocumentCreated)('follows/{followId}', async (event) => {
    const data = event.data?.data();
    if (!data)
        return;
    const creatorUid = data.creatorUid;
    if (!creatorUid)
        return;
    await db()
        .collection('creatorProfiles')
        .doc(creatorUid)
        .set({
        followerCount: firestore_2.FieldValue.increment(1),
        updatedAt: firestore_2.FieldValue.serverTimestamp(),
    }, { merge: true });
});
/**
 * Decrements creatorProfiles/{creatorUid}.followerCount when a follow doc is deleted.
 * Clamps to 0 so the counter never goes negative from duplicate deletes.
 */
exports.onFollowDeleted = (0, firestore_1.onDocumentDeleted)('follows/{followId}', async (event) => {
    const data = event.data?.data();
    if (!data)
        return;
    const creatorUid = data.creatorUid;
    if (!creatorUid)
        return;
    const ref = db().collection('creatorProfiles').doc(creatorUid);
    await db().runTransaction(async (tx) => {
        const snap = await tx.get(ref);
        const current = snap.data()?.followerCount ?? 0;
        tx.set(ref, {
            followerCount: Math.max(0, current - 1),
            updatedAt: firestore_2.FieldValue.serverTimestamp(),
        }, { merge: true });
    });
});
