class CreatorGrowthScore {
  const CreatorGrowthScore({
    required this.creatorId,
    required this.reachScore,
    required this.conversionScore,
    required this.retentionScore,
    required this.monetisationScore,
    required this.consistencyScore,
    required this.collaborationScore,
    required this.viralityScore,
    required this.overallScore,
    required this.updatedAt,
  });

  final String creatorId;
  final double reachScore;
  final double conversionScore;
  final double retentionScore;
  final double monetisationScore;
  final double consistencyScore;
  final double collaborationScore;
  final double viralityScore;
  final double overallScore;
  final DateTime? updatedAt;

  factory CreatorGrowthScore.fromMap(Map<String, dynamic> map) {
    return CreatorGrowthScore(
      creatorId: map['creatorId']?.toString() ?? '',
      reachScore: (map['reachScore'] as num?)?.toDouble() ?? 0,
      conversionScore: (map['conversionScore'] as num?)?.toDouble() ?? 0,
      retentionScore: (map['retentionScore'] as num?)?.toDouble() ?? 0,
      monetisationScore: (map['monetisationScore'] as num?)?.toDouble() ?? 0,
      consistencyScore: (map['consistencyScore'] as num?)?.toDouble() ?? 0,
      collaborationScore:
          (map['collaborationScore'] as num?)?.toDouble() ?? 0,
      viralityScore: (map['viralityScore'] as num?)?.toDouble() ?? 0,
      overallScore: (map['overallScore'] as num?)?.toDouble() ?? 0,
      updatedAt: _readDate(map['updatedAt']),
    );
  }

  static DateTime? _readDate(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
