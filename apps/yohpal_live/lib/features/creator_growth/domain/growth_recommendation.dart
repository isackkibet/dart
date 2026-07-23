class GrowthRecommendation {
  const GrowthRecommendation({
    required this.id,
    required this.creatorId,
    required this.title,
    required this.description,
    required this.priority,
    required this.category,
    required this.expectedImpact,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String creatorId;
  final String title;
  final String description;
  final String priority;
  final String category;
  final String expectedImpact;
  final String status;
  final DateTime? createdAt;

  factory GrowthRecommendation.fromMap(String id, Map<String, dynamic> map) {
    return GrowthRecommendation(
      id: id,
      creatorId: map['creatorId']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      priority: map['priority']?.toString() ?? 'medium',
      category: map['category']?.toString() ?? 'growth',
      expectedImpact: map['expectedImpact']?.toString() ?? '',
      status: map['status']?.toString() ?? 'open',
      createdAt: _readDate(map['createdAt']),
    );
  }

  static DateTime? _readDate(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
