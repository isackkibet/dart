import 'edit_project_status.dart';
import 'video_clip_edit.dart';
import 'video_metadata.dart';

/// An in-progress editing session: an ordered list of clips plus where the
/// session currently sits in the local edit → render pipeline. In-memory
/// only — nothing here is persisted; the caller is expected to hand the
/// final rendered file off to whatever upload flow it's building on top of.
final class EditProject {
  const EditProject({
    required this.id,
    required this.clips,
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const VideoMetadata.empty(),
    this.status = EditProjectStatus.draft,
    this.renderedOutputPath,
    this.renderedOutputSha256,
    this.lastError,
  });

  final String id;
  final List<VideoClipEdit> clips;
  final VideoMetadata metadata;
  final EditProjectStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? renderedOutputPath;
  final String? renderedOutputSha256;
  final String? lastError;

  int get totalEditedDurationMs {
    return clips.fold<int>(0, (total, clip) => total + clip.editedDurationMs);
  }

  bool get hasValidTimeline =>
      clips.isNotEmpty && clips.every((clip) => clip.isValid);

  bool get canRender => clips.isNotEmpty;

  EditProject copyWith({
    List<VideoClipEdit>? clips,
    VideoMetadata? metadata,
    EditProjectStatus? status,
    DateTime? updatedAt,
    String? renderedOutputPath,
    String? renderedOutputSha256,
    String? lastError,
    bool clearRenderedOutput = false,
    bool clearLastError = false,
  }) {
    return EditProject(
      id: id,
      clips: clips ?? this.clips,
      metadata: metadata ?? this.metadata,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      renderedOutputPath: clearRenderedOutput
          ? null
          : renderedOutputPath ?? this.renderedOutputPath,
      renderedOutputSha256: clearRenderedOutput
          ? null
          : renderedOutputSha256 ?? this.renderedOutputSha256,
      lastError: clearLastError ? null : lastError ?? this.lastError,
    );
  }
}
