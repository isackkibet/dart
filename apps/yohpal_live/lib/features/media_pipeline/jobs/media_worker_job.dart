class MediaWorkerJob {
  final String id;
  final String sessionId;
  final String creatorId;
  final String jobType;
  final String status;
  final String? externalJobId;
  final String? inputUrl;
  final String? outputUrl;
  final String? errorMessage;
  final int retryCount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  const MediaWorkerJob({
    required this.id,
    required this.sessionId,
    required this.creatorId,
    required this.jobType,
    required this.status,
    this.externalJobId,
    this.inputUrl,
    this.outputUrl,
    this.errorMessage,
    this.retryCount = 0,
    required this.createdAt,
    this.updatedAt,
  });
  factory MediaWorkerJob.fromMap(String id, Map<String, dynamic> data) {
    return MediaWorkerJob(
      id: id,
      sessionId: data['sessionId'] ?? '',
      creatorId: data['creatorId'] ?? '',
      jobType: data['jobType'] ?? '',
      status: data['status'] ?? 'pending',
      externalJobId: data['externalJobId'],
      inputUrl: data['inputUrl'],
      outputUrl: data['outputUrl'],
      errorMessage: data['errorMessage'],
      retryCount: data['retryCount'] ?? 0,
      createdAt: DateTime.tryParse(data['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: data['updatedAt'] == null
          ? null
          : DateTime.tryParse(data['updatedAt'].toString()),
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'creatorId': creatorId,
      'jobType': jobType,
      'status': status,
      'externalJobId': externalJobId,
      'inputUrl': inputUrl,
      'outputUrl': outputUrl,
      'errorMessage': errorMessage,
      'retryCount': retryCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
