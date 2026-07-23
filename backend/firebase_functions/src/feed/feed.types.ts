export interface FeedRequest {
  viewerId: string;
  category: "recommended" | "following";
  cursor?: string;
  excludedVideoIds: string[];
  limit: number;
}

export interface FeedVideoItem {
  id: string;
  creatorId: string;
  creatorDisplayName: string;
  creatorUsername: string;
  creatorVerified: boolean;
  caption: string;
  videoUrl: string;
  thumbnailUrl: string;
  publishedAt: string;
}

export interface FeedResponse {
  videos: FeedVideoItem[];
  hasMore: boolean;
  nextCursor?: string;
}
