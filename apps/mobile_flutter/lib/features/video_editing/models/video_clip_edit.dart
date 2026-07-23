/// A single clip on the editor timeline: a reference to a local source file
/// plus the trim window and order applied to it. `sourcePath` always points
/// at the untouched capture/pick output — trimming never mutates the source,
/// only the range that gets included when the timeline is rendered.
final class VideoClipEdit {
  const VideoClipEdit({
    required this.id,
    required this.sourcePath,
    required this.sourceDurationMs,
    required this.trimStartMs,
    required this.trimEndMs,
    required this.order,
    required this.createdAt,
  });

  final String id;
  final String sourcePath;
  final int sourceDurationMs;
  final int trimStartMs;
  final int trimEndMs;
  final int order;
  final DateTime createdAt;

  int get editedDurationMs => trimEndMs - trimStartMs;

  bool get isValid =>
      sourcePath.trim().isNotEmpty &&
      sourceDurationMs > 0 &&
      trimStartMs >= 0 &&
      trimEndMs > trimStartMs &&
      trimEndMs <= sourceDurationMs &&
      order >= 0;

  VideoClipEdit copyWith({
    String? id,
    String? sourcePath,
    int? sourceDurationMs,
    int? trimStartMs,
    int? trimEndMs,
    int? order,
    DateTime? createdAt,
  }) {
    return VideoClipEdit(
      id: id ?? this.id,
      sourcePath: sourcePath ?? this.sourcePath,
      sourceDurationMs: sourceDurationMs ?? this.sourceDurationMs,
      trimStartMs: trimStartMs ?? this.trimStartMs,
      trimEndMs: trimEndMs ?? this.trimEndMs,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
