enum FeedCategory {
  recommended,
  following,
}

extension FeedCategoryLabel on FeedCategory {
  String get label => switch (this) {
        FeedCategory.recommended => 'Recommended',
        FeedCategory.following => 'Following',
      };
}
