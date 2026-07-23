class SocialConnector {
  const SocialConnector({
    required this.id,
    required this.creatorId,
    required this.platform,
    required this.status,
    required this.scopes,
    required this.externalUserId,
    required this.externalUsername,
    required this.externalAvatarUrl,
    required this.connectedAt,
    this.expiresAt,
    this.lastHealthCheckAt,
  });

  final String id;
  final String creatorId;

  /// Platform identifier: youtube | tiktok | instagram | facebook | x |
  /// linkedin | twitch | kick
  final String platform;

  /// Connection state: connected | disconnected | expired | revoked
  final String status;

  final List<String> scopes;
  final String externalUserId;
  final String externalUsername;
  final String externalAvatarUrl;
  final DateTime? connectedAt;
  final DateTime? expiresAt;
  final DateTime? lastHealthCheckAt;

  bool get isConnected => status == 'connected';

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  factory SocialConnector.fromMap(String id, Map<String, dynamic> map) {
    return SocialConnector(
      id: id,
      creatorId: map['creatorId']?.toString() ?? '',
      platform: map['platform']?.toString() ?? '',
      status: map['status']?.toString() ?? 'disconnected',
      scopes: List<String>.from(map['scopes'] as List? ?? []),
      externalUserId: map['externalUserId']?.toString() ?? '',
      externalUsername: map['externalUsername']?.toString() ?? '',
      externalAvatarUrl: map['externalAvatarUrl']?.toString() ?? '',
      connectedAt: _readDate(map['connectedAt']),
      expiresAt: _readDate(map['expiresAt']),
      lastHealthCheckAt: _readDate(map['lastHealthCheckAt']),
    );
  }

  static DateTime? _readDate(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
