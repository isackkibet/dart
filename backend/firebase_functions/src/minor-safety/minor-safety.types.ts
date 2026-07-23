export type MinorContentType =
  | "none"
  | "incidental_minor"
  | "minor_participant"
  | "minor_creator"
  | "directed_to_children"
  | "educational_for_minors"
  | "advertising_to_minors";

export interface MinorPublicationEvidence {
  videoId: string;
  creatorId: string;
  classificationCompleted: boolean;
  contentType: MinorContentType;
  ageRating: string;
  containsIdentifiableMinor: boolean;
  creatorVerificationStatus:
    | "not_required"
    | "pending"
    | "approved"
    | "suspended"
    | "rejected"
    | "expired";
  guardianConsentRequired: boolean;
  guardianConsentVerified: boolean;
  manualReviewRequired: boolean;
  manualReviewPassed: boolean;
}

export interface ViewerSafetyContext {
  viewerAge?: number;
  childAccount: boolean;
  allowedRatings: string[];
  blockedCreatorIds: string[];
}

export interface VideoSafetyContext {
  creatorId: string;
  ageRating: string;
  minimumRecommendedAge: number;
  minorDirected: boolean;
  minorCreatorVerified: boolean;
  moderationStatus: "approved" | "pending" | "rejected";
}

export interface MinorAdvertisingInput {
  targetsMinors: boolean;
  advertiserStatus: string;
  market: string;
  ageBand: string;
  approvedMarkets: string[];
  approvedAgeBands: string[];
  creativeReviewPassed: boolean;
  approvalExpiresAt?: string;
}
