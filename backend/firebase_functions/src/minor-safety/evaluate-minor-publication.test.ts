import { evaluateMinorPublication } from "./evaluate-minor-publication";
import type { MinorPublicationEvidence } from "./minor-safety.types";

const base: MinorPublicationEvidence = {
  videoId: "video-001",
  creatorId: "creator-001",
  classificationCompleted: true,
  contentType: "none",
  ageRating: "general",
  containsIdentifiableMinor: false,
  creatorVerificationStatus: "not_required",
  guardianConsentRequired: false,
  guardianConsentVerified: false,
  manualReviewRequired: false,
  manualReviewPassed: false,
};

describe("evaluateMinorPublication", () => {
  it("returns no blockers for general content with no minor involvement", () => {
    expect(evaluateMinorPublication(base)).toHaveLength(0);
  });

  it("blocks when classification is incomplete", () => {
    const blockers = evaluateMinorPublication({
      ...base,
      classificationCompleted: false,
    });
    expect(blockers).toContain(
      "Minor-content and age classification is incomplete."
    );
  });

  it("blocks when age rating is missing", () => {
    const blockers = evaluateMinorPublication({ ...base, ageRating: "" });
    expect(blockers).toContain("An age rating is required.");
  });

  it("blocks unverified creators from minor-directed publication", () => {
    const blockers = evaluateMinorPublication({
      ...base,
      contentType: "directed_to_children",
      ageRating: "children",
      containsIdentifiableMinor: true,
      creatorVerificationStatus: "pending",
      guardianConsentRequired: true,
      guardianConsentVerified: true,
      manualReviewRequired: true,
      manualReviewPassed: true,
    });
    expect(blockers).toContain(
      "The creator is not approved to publish content for minors."
    );
  });

  it("blocks when guardian consent is required but not verified", () => {
    const blockers = evaluateMinorPublication({
      ...base,
      containsIdentifiableMinor: true,
      guardianConsentRequired: true,
      guardianConsentVerified: false,
    });
    expect(blockers).toContain(
      "Required guardian consent has not been verified."
    );
  });

  it("blocks when manual review is required but not passed", () => {
    const blockers = evaluateMinorPublication({
      ...base,
      manualReviewRequired: true,
      manualReviewPassed: false,
    });
    expect(blockers).toContain("Mandatory child-safety review is incomplete.");
  });

  it("allows approved minor-creator after all gates pass", () => {
    const blockers = evaluateMinorPublication({
      ...base,
      contentType: "minor_creator",
      ageRating: "teen",
      containsIdentifiableMinor: true,
      creatorVerificationStatus: "approved",
      guardianConsentRequired: true,
      guardianConsentVerified: true,
      manualReviewRequired: true,
      manualReviewPassed: true,
    });
    expect(blockers).toHaveLength(0);
  });
});
