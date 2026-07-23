class StreamRoutePolicy {
  const StreamRoutePolicy({
    required this.id,
    required this.sessionId,
    required this.destinationId,
    required this.mode,
    required this.enabled,
    required this.delaySeconds,
    required this.previewWindowSeconds,
    required this.ctaOverlayEnabled,
    required this.ctaText,
    required this.ctaUrl,
    required this.watermarkEnabled,
    required this.blurAfterPreview,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String sessionId;
  final String destinationId;
  final String mode; // full, teaser, hybrid
  final bool enabled;
  final int delaySeconds;
  final int previewWindowSeconds;
  final bool ctaOverlayEnabled;
  final String ctaText;
  final String ctaUrl;
  final bool watermarkEnabled;
  final bool blurAfterPreview;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory StreamRoutePolicy.fromMap(String id, Map<String, dynamic> map) {
    return StreamRoutePolicy(
      id: id,
      sessionId: map['sessionId']?.toString() ?? '',
      destinationId: map['destinationId']?.toString() ?? '',
      mode: map['mode']?.toString() ?? 'teaser',
      enabled: map['enabled'] != false,
      delaySeconds: (map['delaySeconds'] as num?)?.toInt() ?? 20,
      previewWindowSeconds:
          (map['previewWindowSeconds'] as num?)?.toInt() ?? 60,
      ctaOverlayEnabled: map['ctaOverlayEnabled'] == true,
      ctaText: map['ctaText']?.toString() ?? 'Join the full live on YohPal',
      ctaUrl: map['ctaUrl']?.toString() ?? '',
      watermarkEnabled: map['watermarkEnabled'] != false,
      blurAfterPreview: map['blurAfterPreview'] == true,
      createdAt: _readDate(map['createdAt']),
      updatedAt: _readDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'destinationId': destinationId,
      'mode': mode,
      'enabled': enabled,
      'delaySeconds': delaySeconds,
      'previewWindowSeconds': previewWindowSeconds,
      'ctaOverlayEnabled': ctaOverlayEnabled,
      'ctaText': ctaText,
      'ctaUrl': ctaUrl,
      'watermarkEnabled': watermarkEnabled,
      'blurAfterPreview': blurAfterPreview,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    };
  }

  static DateTime? _readDate(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
