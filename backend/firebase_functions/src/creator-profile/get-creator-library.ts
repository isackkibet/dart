import * as admin from "firebase-admin";
import { onCall } from "firebase-functions/v2/https";
import { assertCreatorLibraryAccess } from "./creator-library-access";
import type {
  CreatorLibraryCategory,
  CreatorLibraryRequest,
  CreatorLibraryResponse,
  CreatorLibraryVideoItem,
} from "./creator-library.types";
import { decodeCursor, encodeCursor } from "../shared/pagination";

const db = admin.firestore();

function visibilityFilter(category: CreatorLibraryCategory): string[] {
  switch (category) {
    case "publicVideos":
    case "pinned":
    case "popular":
    case "series":
    case "liveReplays":
      return ["public"];
    case "privateVideos":
      return ["private"];
    case "drafts":
      return ["draft"];
    case "archived":
      return ["archived"];
    default:
      return [];
  }
}

export const getCreatorLibrary = onCall<CreatorLibraryRequest>(
  { region: "us-central1" },
  async (request) => {
    const data = request.data;
    const requesterId = request.auth?.uid ?? data.requesterId;

    assertCreatorLibraryAccess({
      requesterId,
      creatorId: data.creatorId,
      category: data.category,
    });

    const limit = Math.min(data.limit ?? 24, 48);
    const allowedVisibilities = visibilityFilter(data.category);
    let query = db
      .collection("videos")
      .where("ownerId", "==", data.creatorId)
      .orderBy("createdAt", "desc")
      .limit(limit + 1);

    if (allowedVisibilities.length > 0) {
      query = query.where("visibility", "in", allowedVisibilities) as typeof query;
    }

    if (data.cursor) {
      const startAfterTs = decodeCursor(data.cursor);
      query = query.startAfter(startAfterTs) as typeof query;
    }

    const snap = await query.get();
    const hasMore = snap.docs.length > limit;
    const docs = hasMore ? snap.docs.slice(0, limit) : snap.docs;

    const videos: CreatorLibraryVideoItem[] = docs.map((doc) => {
      const d = doc.data();
      return {
        id: doc.id,
        thumbnailUrl: d.thumbnailUrl ?? "",
        views: d.views ?? 0,
        visibility: d.visibility ?? "public",
        publishedAt: d.createdAt?.toDate()?.toISOString() ?? new Date().toISOString(),
        processingStatus: d.moderationStatus ?? "published",
      };
    });

    const response: CreatorLibraryResponse = {
      videos,
      hasMore,
      nextCursor: hasMore ? encodeCursor(docs[docs.length - 1].data().createdAt) : undefined,
    };

    return response;
  }
);
