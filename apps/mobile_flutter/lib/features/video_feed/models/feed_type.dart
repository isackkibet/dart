enum FeedType { suggested, following, trending, category }

extension FeedTypeX on FeedType {
  String get label {
    switch (this) {
      case FeedType.suggested:
        return 'Suggested';
      case FeedType.following:
        return 'Following';
      case FeedType.trending:
        return 'Trending';
      case FeedType.category:
        return 'Category';
    }
  }
}
