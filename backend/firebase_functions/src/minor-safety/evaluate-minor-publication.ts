import { MinorPublicationEvidence } from "./minor-safety.types";

export function evaluateMinorPublication(
  evidence: MinorPublicationEvidence
): string[] {
  const blockers: string[] = [];

  if (!evidence.classificationCompleted) {
    blockers.push("Minor-content and age classification is incomplete.");
  }

  if (!evidence.ageRating) {
    blockers.push("An age rating is required.");
  }

  const minorDirected =
    evidence.contentType === "minor_creator" ||
    evidence.contentType === "directed_to_children" ||
    evidence.contentType === "educational_for_minors";

  if (minorDirected && evidence.creatorVerificationStatus !== "approved") {
    blockers.push(
      "The creator is not approved to publish content for minors."
    );
  }

  if (
    evidence.containsIdentifiableMinor &&
    evidence.guardianConsentRequired &&
    !evidence.guardianConsentVerified
  ) {
    blockers.push("Required guardian consent has not been verified.");
  }

  if (evidence.manualReviewRequired && !evidence.manualReviewPassed) {
    blockers.push("Mandatory child-safety review is incomplete.");
  }

  return blockers;
}

export function canPublishMinorContent(
  evidence: MinorPublicationEvidence
): boolean {
  return evaluateMinorPublication(evidence).length === 0;
}
