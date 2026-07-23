import { MinorAdvertisingInput } from "./minor-safety.types";

export function evaluateMinorAdvertising(
  input: MinorAdvertisingInput
): string[] {
  if (!input.targetsMinors) return [];

  const blockers: string[] = [];

  if (input.advertiserStatus !== "approved") {
    blockers.push("The advertiser is not approved to target minors.");
  }

  if (!input.approvedMarkets.includes(input.market)) {
    blockers.push("Minor targeting is not approved in this market.");
  }

  if (!input.approvedAgeBands.includes(input.ageBand)) {
    blockers.push("The selected age band is not approved.");
  }

  if (!input.creativeReviewPassed) {
    blockers.push("The advertisement has not passed child-safety review.");
  }

  if (
    input.approvalExpiresAt &&
    new Date(input.approvalExpiresAt) <= new Date()
  ) {
    blockers.push("The advertiser approval has expired.");
  }

  return blockers;
}

export function canTargetMinors(input: MinorAdvertisingInput): boolean {
  return evaluateMinorAdvertising(input).length === 0;
}

export function canDisplayVideo(input: {
  viewer: {
    viewerAge?: number;
    childAccount: boolean;
    allowedRatings: string[];
    blockedCreatorIds: string[];
  };
  video: {
    creatorId: string;
    ageRating: string;
    minimumRecommendedAge: number;
    minorDirected: boolean;
    minorCreatorVerified: boolean;
    moderationStatus: "approved" | "pending" | "rejected";
  };
}): boolean {
  if (input.viewer.blockedCreatorIds.includes(input.video.creatorId)) {
    return false;
  }
  if (input.video.moderationStatus !== "approved") return false;
  if (input.video.minorDirected && !input.video.minorCreatorVerified) {
    return false;
  }
  if (!input.viewer.allowedRatings.includes(input.video.ageRating)) {
    return false;
  }
  if (
    typeof input.viewer.viewerAge === "number" &&
    input.viewer.viewerAge < input.video.minimumRecommendedAge
  ) {
    return false;
  }
  return true;
}
