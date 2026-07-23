enum VideoAgeRating {
  earlyChildhood,
  children,
  preTeen,
  teen,
  general,
  mature,
  adultsOnly,
}

extension VideoAgeRatingRules on VideoAgeRating {
  String get label => switch (this) {
        VideoAgeRating.earlyChildhood => 'Early Childhood',
        VideoAgeRating.children => 'Children',
        VideoAgeRating.preTeen => 'Pre-Teen',
        VideoAgeRating.teen => 'Teen',
        VideoAgeRating.general => 'General Audience',
        VideoAgeRating.mature => 'Mature',
        VideoAgeRating.adultsOnly => 'Adults Only',
      };

  int get minimumRecommendedAge => switch (this) {
        VideoAgeRating.earlyChildhood => 0,
        VideoAgeRating.children => 6,
        VideoAgeRating.preTeen => 10,
        VideoAgeRating.teen => 13,
        VideoAgeRating.general => 0,
        VideoAgeRating.mature => 16,
        VideoAgeRating.adultsOnly => 18,
      };
}
