class PipelineConfig {
  const PipelineConfig({
    this.outputFormat = 'mp4',
    this.resolution = '720p',
    this.videoBitrate = 2500,
    this.fps = 30,
    this.audioBitrate = 128,
    this.watermarkEnabled = false,
    this.watermarkRef,
  });

  /// Output container format: mp4 | webm | hls
  final String outputFormat;

  /// Target resolution: 1080p | 720p | 480p | 360p
  final String resolution;

  /// Video bitrate in kbps
  final int videoBitrate;

  /// Frames per second
  final int fps;

  /// Audio bitrate in kbps
  final int audioBitrate;

  final bool watermarkEnabled;

  /// Cloud Storage path to watermark image
  final String? watermarkRef;

  Map<String, dynamic> toMap() => {
        'outputFormat': outputFormat,
        'resolution': resolution,
        'videoBitrate': videoBitrate,
        'fps': fps,
        'audioBitrate': audioBitrate,
        'watermarkEnabled': watermarkEnabled,
        if (watermarkRef != null) 'watermarkRef': watermarkRef,
      };

  factory PipelineConfig.fromMap(Map<String, dynamic> map) {
    return PipelineConfig(
      outputFormat: map['outputFormat']?.toString() ?? 'mp4',
      resolution: map['resolution']?.toString() ?? '720p',
      videoBitrate: (map['videoBitrate'] as num?)?.toInt() ?? 2500,
      fps: (map['fps'] as num?)?.toInt() ?? 30,
      audioBitrate: (map['audioBitrate'] as num?)?.toInt() ?? 128,
      watermarkEnabled: map['watermarkEnabled'] as bool? ?? false,
      watermarkRef: map['watermarkRef']?.toString(),
    );
  }

  static const PipelineConfig hd = PipelineConfig(
    outputFormat: 'mp4',
    resolution: '1080p',
    videoBitrate: 5000,
    fps: 30,
    audioBitrate: 192,
  );

  static const PipelineConfig standard = PipelineConfig(
    outputFormat: 'mp4',
    resolution: '720p',
    videoBitrate: 2500,
    fps: 30,
    audioBitrate: 128,
  );

  static const PipelineConfig mobile = PipelineConfig(
    outputFormat: 'mp4',
    resolution: '480p',
    videoBitrate: 1000,
    fps: 25,
    audioBitrate: 96,
  );
}
