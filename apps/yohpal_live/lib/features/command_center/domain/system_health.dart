class SystemHealth {
  const SystemHealth({
    required this.status,
    required this.apiStatus,
    required this.firestoreStatus,
    required this.functionsStatus,
    required this.authStatus,
    required this.activeLiveSessions,
    required this.openIncidents,
    required this.criticalIncidents,
    required this.safeModeEnabled,
    required this.updatedAt,
  });

  final String status;
  final String apiStatus;
  final String firestoreStatus;
  final String functionsStatus;
  final String authStatus;
  final int activeLiveSessions;
  final int openIncidents;
  final int criticalIncidents;
  final bool safeModeEnabled;
  final DateTime? updatedAt;

  factory SystemHealth.fromMap(Map<String, dynamic> map) {
    return SystemHealth(
      status: map['status']?.toString() ?? 'unknown',
      apiStatus: map['apiStatus']?.toString() ?? 'unknown',
      firestoreStatus: map['firestoreStatus']?.toString() ?? 'unknown',
      functionsStatus: map['functionsStatus']?.toString() ?? 'unknown',
      authStatus: map['authStatus']?.toString() ?? 'unknown',
      activeLiveSessions: (map['activeLiveSessions'] as num?)?.toInt() ?? 0,
      openIncidents: (map['openIncidents'] as num?)?.toInt() ?? 0,
      criticalIncidents: (map['criticalIncidents'] as num?)?.toInt() ?? 0,
      safeModeEnabled: map['safeModeEnabled'] == true,
      updatedAt: _readDate(map['updatedAt']),
    );
  }

  static DateTime? _readDate(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
