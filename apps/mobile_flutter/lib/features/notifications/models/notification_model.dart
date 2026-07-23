import 'package:cloud_firestore/cloud_firestore.dart';

class YohPalNotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type;
  final String targetId;
  final bool read;
  final DateTime createdAt;

  const YohPalNotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.targetId,
    required this.read,
    required this.createdAt,
  });

  factory YohPalNotificationModel.fromMap(Map<String, dynamic> map) {
    return YohPalNotificationModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: map['type'] ?? '',
      targetId: map['targetId'] ?? '',
      read: map['read'] ?? false,
      createdAt: _parseDate(map['createdAt']),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
