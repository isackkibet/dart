"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.creatorProfileRouter = void 0;
const express_1 = require("express");
const firestore_1 = require("firebase-admin/firestore");
const requireAuth_1 = require("../../core/http/requireAuth");
const respond_1 = require("../../core/http/respond");
const creatorProfile_schema_1 = require("./creatorProfile.schema");
exports.creatorProfileRouter = (0, express_1.Router)();
const db = (0, firestore_1.getFirestore)();
exports.creatorProfileRouter.get("/me", requireAuth_1.requireAuth, async (req, res) => {
    const uid = req.user?.uid;
    if (!uid) {
        return (0, respond_1.fail)(res, 401, "missing_user", "Missing authenticated user.");
    }
    const snapshot = await db
        .collection("creatorProfiles")
        .where("uid", "==", uid)
        .limit(1)
        .get();
    if (snapshot.empty) {
        return (0, respond_1.ok)(res, {
            profile: null,
        });
    }
    const doc = snapshot.docs[0];
    return (0, respond_1.ok)(res, {
        profile: {
            id: doc.id,
            ...doc.data(),
        },
    });
});
exports.creatorProfileRouter.post("/me", requireAuth_1.requireAuth, async (req, res) => {
    const uid = req.user?.uid;
    if (!uid) {
        return (0, respond_1.fail)(res, 401, "missing_user", "Missing authenticated user.");
    }
    const parsed = creatorProfile_schema_1.UpsertCreatorProfileSchema.safeParse(req.body);
    if (!parsed.success) {
        return (0, respond_1.fail)(res, 400, "invalid_creator_profile_payload", "Invalid creator profile payload.", parsed.error.flatten());
    }
    const input = parsed.data;
    const existing = await db
        .collection("creatorProfiles")
        .where("uid", "==", uid)
        .limit(1)
        .get();
    const payload = {
        uid,
        displayName: input.displayName,
        handle: input.handle.toLowerCase(),
        category: input.category ?? "",
        bio: input.bio ?? "",
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
        updatedBy: uid,
        status: "active",
    };
    if (existing.empty) {
        const doc = db.collection("creatorProfiles").doc();
        await doc.set({
            ...payload,
            verificationStatus: "pending",
            monetisationEnabled: false,
            riskScore: 0,
            createdAt: firestore_1.FieldValue.serverTimestamp(),
            createdBy: uid,
        });
        return (0, respond_1.ok)(res, {
            id: doc.id,
            ...payload,
        }, 201);
    }
    const doc = existing.docs[0];
    await doc.ref.update(payload);
    return (0, respond_1.ok)(res, {
        id: doc.id,
        ...payload,
    });
});
//# sourceMappingURL=creatorProfile.router.js.map