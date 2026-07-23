import { Router } from "express";
import { getFirestore } from "firebase-admin/firestore";
import { AuthenticatedRequest, requireAuth } from "../../core/http/requireAuth";
import { fail, ok } from "../../core/http/respond";
import { SearchQuerySchema } from "./search.schema";

export const searchRouter = Router();
const db = getFirestore();

searchRouter.get(
  "/",
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    const uid = req.user?.uid;
    if (!uid) return fail(res, 401, "missing_user", "Missing user.");

    const parsed = SearchQuerySchema.safeParse(req.query);
    if (!parsed.success) {
      return fail(
        res,
        400,
        "invalid_search_query",
        "Invalid search query parameters.",
        parsed.error.flatten(),
      );
    }

    const { q, type, limit } = parsed.data;
    const searchToken = q.toLowerCase().trim();

    try {
      const videosPromise =
        type === "all" || type === "videos"
          ? db
              .collection("videos")
              .where("searchTokens", "array-contains", searchToken)
              .limit(limit)
              .get()
          : Promise.resolve(null);

      const creatorsPromise =
        type === "all" || type === "creators"
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

      return ok(res, {
        videos,
        creators,
      });
    } catch (error) {
      return fail(
        res,
        500,
        "search_execution_failed",
        "An error occurred while executing search.",
        error instanceof Error ? error.message : String(error),
      );
    }
  },
);
