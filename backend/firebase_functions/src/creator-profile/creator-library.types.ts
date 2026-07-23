export type CreatorLibraryCategory =
  | "publicVideos"
  | "pinned"
  | "popular"
  | "series"
  | "liveReplays"
  | "drafts"
  | "privateVideos"
  | "scheduled"
  | "pendingReview"
  | "rejected"
  | "saved"
  | "liked"
  | "shared"
  | "viewHistory"
  | "blocked"
  | "archived";

export interface CreatorLibraryRequest {
  creatorId: string;
  requesterId: string;
  category: CreatorLibraryCategory;
  cursor?: string;
  limit: number;
}

export interface CreatorLibraryVideoItem {
  id: string;
  thumbnailUrl: string;
  views: number;
  visibility: string;
  publishedAt: string;
  processingStatus: string;
}

export interface CreatorLibraryResponse {
  videos: CreatorLibraryVideoItem[];
  hasMore: boolean;
  nextCursor?: string;
}
