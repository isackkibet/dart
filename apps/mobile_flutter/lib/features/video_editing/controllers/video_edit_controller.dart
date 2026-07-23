import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/edit_project.dart';
import '../models/edit_project_status.dart';
import '../models/video_clip_edit.dart';
import 'editor_history.dart';

/// Owns one in-progress [EditProject]: all timeline edits and undo/redo go
/// through here. Unlike the fuller Creator Studio version this is based on,
/// this controller is in-memory only — no repository, no autosave, no
/// Firestore-lifecycle status tracking. Editing here only ever produces a
/// local rendered file; whatever upload flow sits on top of this feature is
/// responsible for persistence and publishing.
final class VideoEditController extends ChangeNotifier {
  VideoEditController({
    required EditProject initialProject,
    EditorHistory? history,
    Uuid uuid = const Uuid(),
  })  : _project = initialProject,
        _history = history ?? EditorHistory(),
        _uuid = uuid;

  final EditorHistory _history;
  final Uuid _uuid;

  EditProject _project;
  EditProject get project => _project;

  bool get canUndo => _history.canUndo;
  bool get canRedo => _history.canRedo;

  void addClip({required String sourcePath, required int durationMs}) {
    if (durationMs <= 0) {
      throw ArgumentError.value(
        durationMs,
        'durationMs',
        'Clip duration must be positive.',
      );
    }

    _recordCurrent();

    final clip = VideoClipEdit(
      id: _uuid.v4(),
      sourcePath: sourcePath,
      sourceDurationMs: durationMs,
      trimStartMs: 0,
      trimEndMs: durationMs,
      order: _project.clips.length,
      createdAt: DateTime.now(),
    );

    _setProject(
      _project.copyWith(
        clips: [..._project.clips, clip],
        clearRenderedOutput: true,
      ),
    );
  }

  void trimClip({
    required String clipId,
    required int startMs,
    required int endMs,
  }) {
    final index = _findClipIndex(clipId);
    final clip = _project.clips[index];

    if (startMs < 0 || endMs <= startMs || endMs > clip.sourceDurationMs) {
      throw ArgumentError('Invalid trim range: $startMs–$endMs.');
    }

    _recordCurrent();

    final updated = [..._project.clips];
    updated[index] = clip.copyWith(trimStartMs: startMs, trimEndMs: endMs);

    _setProject(
      _project.copyWith(clips: updated, clearRenderedOutput: true),
    );
  }

  void splitClip({required String clipId, required int timelinePositionMs}) {
    final index = _findClipIndex(clipId);
    final clip = _project.clips[index];

    if (timelinePositionMs <= clip.trimStartMs ||
        timelinePositionMs >= clip.trimEndMs) {
      throw ArgumentError('Split must be inside the active trim range.');
    }

    _recordCurrent();

    final first = clip.copyWith(id: _uuid.v4(), trimEndMs: timelinePositionMs);
    final second = clip.copyWith(id: _uuid.v4(), trimStartMs: timelinePositionMs);

    final updated = [..._project.clips]
      ..removeAt(index)
      ..insertAll(index, [first, second]);

    _setProject(
      _project.copyWith(
        clips: _normalizeOrders(updated),
        clearRenderedOutput: true,
      ),
    );
  }

  void deleteClip(String clipId) {
    final index = _findClipIndex(clipId);

    _recordCurrent();

    final updated = [..._project.clips]..removeAt(index);

    _setProject(
      _project.copyWith(
        clips: _normalizeOrders(updated),
        clearRenderedOutput: true,
      ),
    );
  }

  void reorderClip(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _project.clips.length) {
      throw RangeError.index(oldIndex, _project.clips);
    }
    if (newIndex < 0 || newIndex > _project.clips.length) {
      throw RangeError.range(newIndex, 0, _project.clips.length);
    }

    _recordCurrent();

    final updated = [..._project.clips];
    var target = newIndex;
    if (target > oldIndex) target -= 1;
    final clip = updated.removeAt(oldIndex);
    updated.insert(target, clip);

    _setProject(
      _project.copyWith(
        clips: _normalizeOrders(updated),
        clearRenderedOutput: true,
      ),
    );
  }

  void undo() {
    final previous = _history.undo(_project);
    if (previous == null) return;
    _project = previous.copyWith(updatedAt: DateTime.now());
    notifyListeners();
  }

  void redo() {
    final next = _history.redo(_project);
    if (next == null) return;
    _project = next.copyWith(updatedAt: DateTime.now());
    notifyListeners();
  }

  void markRendering() {
    _project = _project.copyWith(
      status: EditProjectStatus.rendering,
      clearLastError: true,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  void markRendered({required String outputPath, required String sha256}) {
    _project = _project.copyWith(
      status: EditProjectStatus.rendered,
      renderedOutputPath: outputPath,
      renderedOutputSha256: sha256,
      clearLastError: true,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  void markFailure(Object error) {
    _project = _project.copyWith(
      status: EditProjectStatus.failed,
      lastError: error.toString(),
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  int _findClipIndex(String clipId) {
    final index = _project.clips.indexWhere((clip) => clip.id == clipId);
    if (index == -1) {
      throw StateError('Clip not found: $clipId.');
    }
    return index;
  }

  void _recordCurrent() {
    _history.record(_project);
  }

  List<VideoClipEdit> _normalizeOrders(List<VideoClipEdit> clips) {
    return clips
        .asMap()
        .entries
        .map((entry) => entry.value.copyWith(order: entry.key))
        .toList(growable: false);
  }

  void _setProject(EditProject project) {
    _project = project.copyWith(updatedAt: DateTime.now());
    notifyListeners();
  }
}
