import '../models/edit_project.dart';

/// Bounded undo/redo stack over full project snapshots. Snapshotting the
/// whole project (rather than diffing individual clip operations) keeps this
/// simple and correct at the cost of some memory — acceptable given
/// [maximumSnapshots] caps it and a project's clip list is small.
final class EditorHistory {
  EditorHistory({this.maximumSnapshots = 50});

  final int maximumSnapshots;

  final List<EditProject> _undo = [];
  final List<EditProject> _redo = [];

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  void record(EditProject snapshot) {
    _undo.add(snapshot);
    if (_undo.length > maximumSnapshots) {
      _undo.removeAt(0);
    }
    _redo.clear();
  }

  EditProject? undo(EditProject current) {
    if (_undo.isEmpty) return null;
    _redo.add(current);
    return _undo.removeLast();
  }

  EditProject? redo(EditProject current) {
    if (_redo.isEmpty) return null;
    _undo.add(current);
    return _redo.removeLast();
  }

  void clear() {
    _undo.clear();
    _redo.clear();
  }
}
