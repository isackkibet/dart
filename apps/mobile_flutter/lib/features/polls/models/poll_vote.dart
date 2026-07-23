import 'package:cloud_firestore/cloud_firestore.dart';

class PollVote {
  final String userId;
  final int optionIndex;
  final DateTime createdAt;

  const PollVote({
    required this.userId,
    required this.optionIndex,
    required this.createdAt,
  });

  factory PollVote.fromMap(Map<String, dynamic> map) {
    return PollVote(
      userId: map['userId'] ?? '',
      optionIndex: (map['optionIndex'] as num?)?.toInt() ?? 0,
      createdAt: _parseDate(map['createdAt']),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
