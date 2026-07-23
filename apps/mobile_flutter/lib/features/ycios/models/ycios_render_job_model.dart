class YciosRenderJobModel {
  final String id;
  final String creatorId;
  final String projectId;
  final String status;
  final int progress;
  final String outputUrl;
  final String error;

  const YciosRenderJobModel({
    required this.id,
    required this.creatorId,
    required this.projectId,
    required this.status,
    this.progress = 0,
    this.outputUrl = '',
    this.error = '',
  });

  factory YciosRenderJobModel.fromMap(Map<String, dynamic> map) =>
      YciosRenderJobModel(
        id: map['id'] as String? ?? '',
        creatorId: map['creatorId'] as String? ?? '',
        projectId: map['projectId'] as String? ?? '',
        status: map['status'] as String? ?? 'queued',
        progress: (map['progress'] as num?)?.toInt() ?? 0,
        outputUrl: map['outputUrl'] as String? ?? '',
        error: map['error'] as String? ?? '',
      );

  bool get isActive => status == 'queued' || status == 'processing';
  bool get isComplete => status == 'completed';
  bool get hasFailed => status == 'failed';
}
