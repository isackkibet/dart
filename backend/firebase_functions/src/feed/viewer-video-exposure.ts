export interface ViewerVideoExposure {
  viewerId: string;
  videoId: string;
  firstShownAt: string;
  lastShownAt: string;
  completedAt?: string;
  maximumProgressPercent: number;
  source:
    | "recommended"
    | "following"
    | "search"
    | "creator_profile"
    | "shared"
    | "saved"
    | "liked"
    | "history"
    | "own_video"
    | "swipe_back";
  automaticFeedEligible: boolean;
}
