enum CreatorLibraryCategory {
  publicVideos,
  pinned,
  popular,
  series,
  liveReplays,
  drafts,
  privateVideos,
  scheduled,
  pendingReview,
  rejected,
  saved,
  liked,
  shared,
  viewHistory,
  blocked,
  archived,
}

extension CreatorLibraryCategoryRules on CreatorLibraryCategory {
  String get label => switch (this) {
        CreatorLibraryCategory.publicVideos => 'Public',
        CreatorLibraryCategory.pinned => 'Pinned',
        CreatorLibraryCategory.popular => 'Popular',
        CreatorLibraryCategory.series => 'Series',
        CreatorLibraryCategory.liveReplays => 'Live Replays',
        CreatorLibraryCategory.drafts => 'Drafts',
        CreatorLibraryCategory.privateVideos => 'Private',
        CreatorLibraryCategory.scheduled => 'Scheduled',
        CreatorLibraryCategory.pendingReview => 'Review',
        CreatorLibraryCategory.rejected => 'Rejected',
        CreatorLibraryCategory.saved => 'Saved',
        CreatorLibraryCategory.liked => 'Liked',
        CreatorLibraryCategory.shared => 'Shared',
        CreatorLibraryCategory.viewHistory => 'History',
        CreatorLibraryCategory.blocked => 'Blocked',
        CreatorLibraryCategory.archived => 'Archived',
      };

  bool get ownerOnly => switch (this) {
        CreatorLibraryCategory.drafts ||
        CreatorLibraryCategory.privateVideos ||
        CreatorLibraryCategory.scheduled ||
        CreatorLibraryCategory.pendingReview ||
        CreatorLibraryCategory.rejected ||
        CreatorLibraryCategory.saved ||
        CreatorLibraryCategory.liked ||
        CreatorLibraryCategory.shared ||
        CreatorLibraryCategory.viewHistory ||
        CreatorLibraryCategory.blocked ||
        CreatorLibraryCategory.archived =>
          true,
        _ => false,
      };
}

List<CreatorLibraryCategory> availableCreatorCategories({
  required bool isOwner,
}) {
  if (isOwner) {
    return CreatorLibraryCategory.values;
  }
  return const [
    CreatorLibraryCategory.publicVideos,
    CreatorLibraryCategory.pinned,
    CreatorLibraryCategory.popular,
    CreatorLibraryCategory.series,
    CreatorLibraryCategory.liveReplays,
  ];
}
