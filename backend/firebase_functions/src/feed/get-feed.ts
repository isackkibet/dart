import * as admin from "firebase-admin";
import { onCall } from "firebase-functions/v2/https";
import { canReturnVideo } from "./feed-eligibility";
import { loadExcludedVideoIds } from "./exposure-repository";
import type { FeedRequest, FeedResponse, FeedVideoItem } from "./feed.types";
import { decodeCursor, encodeCursor } from "../shared/pagination";

const db = admin.firestore();

export const getFeed = onCall<FeedRequest>(
  { region: "us-central1" },
  async (request) => {
    const data = request.data;
    const viewerId = request.auth?.uid ?? data.viewerId;
    const limit = Math.min(data.limit ?? 30, 50);

    // Merge client-supplied exclusions with server-side exposure history.
    const serverExcluded = await loadExcludedVideoIds(viewerId);
    const excluded = new Set([
      ...data.excludedVideoIds,
      ...serverExcluded,
    ]);

    let query = db
      .collection("videos")
      .where("visibility", "==", "public")
      .orderBy("createdAt", "desc")
      .limit(limit + 1);

    if (data.category === "following") {
      const followSnap = await db
        .collection("follows")
        .where("followerId", "==", viewerId)
        .select("creatorId")
        .get();
      const followedIds = followSnap.docs.map((d) => d.data().creatorId as string);
      if (followedIds.length === 0) {
        return { videos: [], hasMore: false } as FeedResponse;
      }
      query = query.where("ownerId", "in", followedIds.slice(0, 10)) as typeof query;
    }

    if (data.cursor) {
      const startAfterTs = decodeCursor(data.cursor);
      query = query.startAfter(startAfterTs) as typeof query;
    }

    const snap = await query.get();
    const eligible = snap.docs.filter((doc) => {
      if (excluded.has(doc.id)) return false;
      return canReturnVideo({
        viewerId,
        creatorId: doc.data().ownerId,
        source: data.category,
      });
    });

    const hasMore = eligible.length > limit;
    const docs = hasMore ? eligible.slice(0, limit) : eligible;

    const videos: FeedVideoItem[] = docs.map((doc) => {
      const d = doc.data();
      return {
        id: doc.id,
        creatorId: d.ownerId ?? "",
        creatorDisplayName: d.ownerDisplayName ?? d.ownerUsername ?? "YohPal Creator",
        creatorUsername: d.ownerUsername ?? "",
        creatorVerified: d.ownerVerified ?? false,
        caption: d.caption ?? "",
        videoUrl: d.hlsUrl ?? d.storageUrl ?? "",
        thumbnailUrl: d.thumbnailUrl ?? "",
        publishedAt: d.createdAt?.toDate()?.toISOString() ?? new Date().toISOString(),
      };
    });

    const response: FeedResponse = {
      videos,
      hasMore,
      nextCursor: hasMore ? encodeCursor(docs[docs.length - 1].data().createdAt) : undefined,
    };

    return response;
  }
);
