class MediaJob {
  const MediaJob({
    required this.id,
    required this.creatorId,
    required this.jobType,
    required this.status,
    required this.inputRef,
    required this.priority,
    required this.retryCount,
    required this.maxRetries,
    required this.createdAt,
    this.sessionId,
    this.clipSegmentId,
    this.outputRef,
    this.progressPercent,
    this.errorMessage,
    this.startedAt,
    this.completedAt,
  });

  final String id;
  final String creatorId;

  /// Job source identifiers (optional)
  final String? sessionId;
  final String? clipSegmentId;

  /// Job type: transcode | thumbnail | clip_export | replay_package | distribute
  final String jobType;

  /// Status: queued | processing | completed | failed | cancelled
  final String status;

  final String inputRef;
  final String? outputRef;

  final int priority;
  final int retryCount;
  final int maxRetries;

  final double? progressPercent;
  final String? errorMessage;

  final DateTime? createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;

  bool get isActive => status == 'queued' || status == 'processing';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get canRetry => isFailed && retryCount < maxRetries;
  bool get canCancel => isActive;

  String get statusLabel => switch (status) {
        'queued' => 'Queued',
        'processing' => 'Processing',
        'completed' => 'Completed',
        'failed' => 'Failed',
        'cancelled' => 'Cancelled',
        _ => status,
      };

  String get jobTypeLabel => switch (jobType) {
        'transcode' => 'Transcode',
        'thumbnail' => 'Thumbnail',
        'clip_export' => 'Clip Export',
        'replay_package' => 'Replay Package',
        'distribute' => 'Distribute',
        _ => jobType,
      };

  factory MediaJob.fromMap(String id, Map<String, dynamic> map) {
    return MediaJob(
      id: id,
      creatorId: map['creatorId']?.toString() ?? '',
      sessionId: map['sessionId']?.toString(),
      clipSegmentId: map['clipSegmentId']?.toString(),
      jobType: map['jobType']?.toString() ?? 'transcode',
      status: map['status']?.toString() ?? 'queued',
      inputRef: map['inputRef']?.toString() ?? '',
      outputRef: map['outputRef']?.toString(),
      priority: (map['priority'] as num?)?.toInt() ?? 5,
      retryCount: (map['retryCount'] as num?)?.toInt() ?? 0,
      maxRetries: (map['maxRetries'] as num?)?.toInt() ?? 3,
      progressPercent: (map['progressPercent'] as num?)?.toDouble(),
      errorMessage: map['errorMessage']?.toString(),
      createdAt: _readDate(map['createdAt']),
      startedAt: _readDate(map['startedAt']),
      completedAt: _readDate(map['completedAt']),
    );
  }

  static DateTime? _readDate(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
