class YciosProjectModel {
  final String id;
  final String creatorId;
  final String title;
  final String description;
  final String status;

  const YciosProjectModel({
    required this.id,
    required this.creatorId,
    required this.title,
    required this.description,
    required this.status,
  });

  factory YciosProjectModel.fromMap(Map<String, dynamic> map) =>
      YciosProjectModel(
        id: map['id'] as String? ?? '',
        creatorId: map['creatorId'] as String? ?? '',
        title: map['title'] as String? ?? 'Untitled Project',
        description: map['description'] as String? ?? '',
        status: map['status'] as String? ?? 'active',
      );

  bool get isActive => status == 'active' || status == 'restored';
  bool get isArchived => status == 'archived';
}
