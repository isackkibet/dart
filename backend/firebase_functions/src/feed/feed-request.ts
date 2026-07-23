export interface FeedRequest {
  viewerId: string;
  category: "recommended" | "following";
  cursor?: string;
  excludedVideoIds: string[];
  limit: number;
}
