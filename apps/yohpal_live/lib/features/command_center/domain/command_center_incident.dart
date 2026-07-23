class CommandCenterIncident {
  const CommandCenterIncident({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.status,
    required this.source,
    required this.affectedService,
    required this.autoResponseTriggered,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String description;
  final String severity; // p0, p1, p2, p3
  final String status; // open, investigating, resolved, ignored
  final String source;
  final String affectedService;
  final bool autoResponseTriggered;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory CommandCenterIncident.fromMap(String id, Map<String, dynamic> map) {
    return CommandCenterIncident(
      id: id,
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      severity: map['severity']?.toString() ?? 'p3',
      status: map['status']?.toString() ?? 'open',
      source: map['source']?.toString() ?? 'manual',
      affectedService: map['affectedService']?.toString() ?? '',
      autoResponseTriggered: map['autoResponseTriggered'] == true,
      createdAt: _readDate(map['createdAt']),
      updatedAt: _readDate(map['updatedAt']),
    );
  }

  static DateTime? _readDate(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
