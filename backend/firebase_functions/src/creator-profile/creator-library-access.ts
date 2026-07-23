import type { CreatorLibraryCategory } from "./creator-library.types";

const ownerOnlyCategories = new Set<CreatorLibraryCategory>([
  "drafts",
  "privateVideos",
  "scheduled",
  "pendingReview",
  "rejected",
  "saved",
  "liked",
  "shared",
  "viewHistory",
  "blocked",
  "archived",
]);

export function assertCreatorLibraryAccess(input: {
  requesterId: string;
  creatorId: string;
  category: CreatorLibraryCategory;
}): void {
  if (
    ownerOnlyCategories.has(input.category) &&
    input.requesterId !== input.creatorId
  ) {
    throw new Error("PERMISSION_DENIED");
  }
}
