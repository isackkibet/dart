import { canReturnVideo } from "./feed-eligibility";
import type { ViewerVideoExposure } from "./viewer-video-exposure";

const baseExposure: ViewerVideoExposure = {
  viewerId: "viewer-001",
  videoId: "video-001",
  firstShownAt: "2026-07-15T10:00:00Z",
  lastShownAt: "2026-07-15T10:01:00Z",
  maximumProgressPercent: 0,
  source: "recommended",
  automaticFeedEligible: true,
};

describe("canReturnVideo — FEED-NR-01 through FEED-NR-04", () => {
  // FEED-NR-01: completed video excluded from recommendations
  it("excludes a completed video from automatic recommendations", () => {
    const result = canReturnVideo({
      viewerId: "viewer-001",
      creatorId: "creator-001",
      source: "recommended",
      exposure: {
        ...baseExposure,
        completedAt: "2026-07-15T10:01:30Z",
        maximumProgressPercent: 100,
        automaticFeedEligible: false,
      },
    });
    expect(result).toBe(false);
  });

  it("excludes a video watched past 80% from automatic recommendations", () => {
    const result = canReturnVideo({
      viewerId: "viewer-001",
      creatorId: "creator-001",
      source: "recommended",
      exposure: {
        ...baseExposure,
        maximumProgressPercent: 85,
        automaticFeedEligible: false,
      },
    });
    expect(result).toBe(false);
  });

  // FEED-NR-02: search permits intentional replay
  it("allows search to replay a completed video", () => {
    const result = canReturnVideo({
      viewerId: "viewer-001",
      creatorId: "creator-001",
      source: "search",
      exposure: {
        ...baseExposure,
        completedAt: "2026-07-15T10:01:30Z",
        automaticFeedEligible: false,
      },
    });
    expect(result).toBe(true);
  });

  it("allows creator_profile access to replay a completed video", () => {
    const result = canReturnVideo({
      viewerId: "viewer-001",
      creatorId: "creator-001",
      source: "creator_profile",
      exposure: {
        ...baseExposure,
        completedAt: "2026-07-15T10:01:30Z",
        automaticFeedEligible: false,
      },
    });
    expect(result).toBe(true);
  });

  it("allows own_video source to replay a watched video", () => {
    const result = canReturnVideo({
      viewerId: "viewer-001",
      creatorId: "creator-001",
      source: "own_video",
      exposure: {
        ...baseExposure,
        maximumProgressPercent: 95,
        automaticFeedEligible: false,
      },
    });
    expect(result).toBe(true);
  });

  it("allows saved source to replay a watched video", () => {
    const result = canReturnVideo({
      viewerId: "viewer-001",
      creatorId: "creator-001",
      source: "saved",
      exposure: {
        ...baseExposure,
        maximumProgressPercent: 95,
        automaticFeedEligible: false,
      },
    });
    expect(result).toBe(true);
  });

  // FEED-NR-03: swipe-back permits replay
  it("allows swipe_back to return to a previously watched video", () => {
    const result = canReturnVideo({
      viewerId: "viewer-001",
      creatorId: "creator-001",
      source: "swipe_back",
      exposure: {
        ...baseExposure,
        completedAt: "2026-07-15T10:01:30Z",
        automaticFeedEligible: false,
      },
    });
    expect(result).toBe(true);
  });

  // FEED-NR-04: no-exposure means eligible (new content)
  it("returns true when there is no prior exposure", () => {
    const result = canReturnVideo({
      viewerId: "viewer-001",
      creatorId: "creator-001",
      source: "recommended",
      exposure: undefined,
    });
    expect(result).toBe(true);
  });

  it("allows own creator to see their own video in any feed", () => {
    const result = canReturnVideo({
      viewerId: "creator-001",
      creatorId: "creator-001",
      source: "recommended",
      exposure: {
        ...baseExposure,
        completedAt: "2026-07-15T10:01:30Z",
        automaticFeedEligible: false,
      },
    });
    expect(result).toBe(true);
  });

  it("allows a partially watched video that is still feed eligible", () => {
    const result = canReturnVideo({
      viewerId: "viewer-001",
      creatorId: "creator-001",
      source: "recommended",
      exposure: {
        ...baseExposure,
        maximumProgressPercent: 40,
        automaticFeedEligible: true,
      },
    });
    expect(result).toBe(true);
  });
});
