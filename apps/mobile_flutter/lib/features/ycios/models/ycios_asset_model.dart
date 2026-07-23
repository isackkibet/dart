class YciosAssetModel {
  final String id;
  final String creatorId;
  final String projectId;
  final String type;
  final String name;
  final String storageUrl;
  final Map<String, dynamic> metadata;

  const YciosAssetModel({
    required this.id,
    required this.creatorId,
    required this.projectId,
    required this.type,
    required this.name,
    this.storageUrl = '',
    this.metadata = const {},
  });

  factory YciosAssetModel.fromMap(Map<String, dynamic> map) => YciosAssetModel(
        id: map['id'] as String? ?? '',
        creatorId: map['creatorId'] as String? ?? '',
        projectId: map['projectId'] as String? ?? '',
        type: map['type'] as String? ?? 'video',
        name: map['name'] as String? ?? 'Untitled Asset',
        storageUrl: map['storageUrl'] as String? ?? '',
        metadata: Map<String, dynamic>.from(map['metadata'] as Map? ?? {}),
      );
}
