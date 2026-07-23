export function assertCreatorLibraryAccess(input: {
  requesterId: string;
  creatorId: string;
  category: string;
}): void {
  const ownerOnly = new Set([
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

  if (
    ownerOnly.has(input.category) &&
    input.requesterId !== input.creatorId
  ) {
    throw new Error("PERMISSION_DENIED");
  }
}
