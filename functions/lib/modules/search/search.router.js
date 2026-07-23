"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.searchRouter = void 0;
const express_1 = require("express");
const firestore_1 = require("firebase-admin/firestore");
const requireAuth_1 = require("../../core/http/requireAuth");
const respond_1 = require("../../core/http/respond");
const search_schema_1 = require("./search.schema");
exports.searchRouter = (0, express_1.Router)();
const db = (0, firestore_1.getFirestore)();
exports.searchRouter.get("/", requireAuth_1.requireAuth, async (req, res) => {
    const uid = req.user?.uid;
    if (!uid)
        return (0, respond_1.fail)(res, 401, "missing_user", "Missing user.");
    const parsed = search_schema_1.SearchQuerySchema.safeParse(req.query);
    if (!parsed.success) {
        return (0, respond_1.fail)(res, 400, "invalid_search_query", "Invalid search query parameters.", parsed.error.flatten());
    }
    const { q, type, limit } = parsed.data;
    const searchToken = q.toLowerCase().trim();
    try {
        const videosPromise = type === "all" || type === "videos"
            ? db
                .collection("liveVideos")
                .where("searchTokens", "array-contains", searchToken)
                .limit(limit)
                .get()
            : Promise.resolve(null);
        const creatorsPromise = type === "all" || type === "creators"
            ? db
                .collection("creatorProfiles")
                .where("searchTokens", "array-contains", searchToken)
                .limit(limit)
                .get()
            : Promise.resolve(null);
        const [videosSnap, creatorsSnap] = await Promise.all([
            videosPromise,
            creatorsPromise,
        ]);
        const videos = videosSnap
            ? videosSnap.docs.map((doc) => {
                const data = doc.data();
                return {
                    id: doc.id,
                    videoId: doc.id,
                    title: data.title || "",
                    creatorName: data.creatorName || "",
                    thumbnailUrl: data.thumbnailUrl || "",
                    viewCount: data.viewCount || 0,
                    durationSeconds: data.durationSeconds || 0,
                };
            })
            : [];
        const creators = creatorsSnap
            ? creatorsSnap.docs.map((doc) => {
                const data = doc.data();
                return {
                    id: doc.id,
                    creatorId: data.uid || doc.id,
                    displayName: data.displayName || "",
                    username: data.handle || "",
                    avatarUrl: data.avatarUrl || "",
                    followerCount: data.followerCount || 0,
                    isVerified: data.verificationStatus === "verified",
                };
            })
            : [];
        return (0, respond_1.ok)(res, {
            videos,
            creators,
        });
    }
    catch (error) {
        return (0, respond_1.fail)(res, 500, "search_execution_failed", "An error occurred while executing search.", error instanceof Error ? error.message : String(error));
    }
});
//# sourceMappingURL=search.router.js.map