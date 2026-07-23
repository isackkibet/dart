import type { ViewerVideoExposure } from "./viewer-video-exposure";

const intentionalReplaySources = new Set([
  "search",
  "creator_profile",
  "shared",
  "saved",
  "liked",
  "history",
  "own_video",
  "swipe_back",
]);

export function canReturnVideo(input: {
  viewerId: string;
  creatorId: string;
  source: string;
  exposure?: ViewerVideoExposure;
}): boolean {
  if (input.viewerId === input.creatorId) {
    return true;
  }

  if (intentionalReplaySources.has(input.source)) {
    return true;
  }

  if (!input.exposure) {
    return true;
  }

  if (
    input.exposure.completedAt ||
    input.exposure.maximumProgressPercent >= 80
  ) {
    return false;
  }

  return input.exposure.automaticFeedEligible;
}
