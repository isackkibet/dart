class TrafficCampaign {
  const TrafficCampaign({
    required this.id,
    required this.creatorId,
    required this.sessionId,
    required this.name,
    required this.sourcePlatform,
    required this.campaignCode,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String creatorId;
  final String sessionId;
  final String name;
  final String sourcePlatform;
  final String campaignCode;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory TrafficCampaign.fromMap(String id, Map<String, dynamic> map) {
    return TrafficCampaign(
      id: id,
      creatorId: map['creatorId']?.toString() ?? '',
      sessionId: map['sessionId']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      sourcePlatform: map['sourcePlatform']?.toString() ?? '',
      campaignCode: map['campaignCode']?.toString() ?? '',
      status: map['status']?.toString() ?? 'active',
      createdAt: _readDate(map['createdAt']),
      updatedAt: _readDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'creatorId': creatorId,
      'sessionId': sessionId,
      'name': name,
      'sourcePlatform': sourcePlatform,
      'campaignCode': campaignCode,
      'status': status,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    };
  }

  String buildAttributionUrl({required String baseWatchUrl}) {
    return '$baseWatchUrl/$sessionId'
        '?src=$sourcePlatform'
        '&campaign=$campaignCode';
  }

  static DateTime? _readDate(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
