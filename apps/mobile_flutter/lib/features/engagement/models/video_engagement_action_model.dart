import 'package:flutter/material.dart';

class VideoEngagementActionModel {
  final String id;
  final String label;
  final IconData icon;
  final String type;
  final bool isPrimary;

  const VideoEngagementActionModel({
    required this.id,
    required this.label,
    required this.icon,
    required this.type,
    this.isPrimary = false,
  });
}
