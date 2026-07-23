import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../video_upload/screens/video_preview_screen.dart';
import '../controllers/video_edit_controller.dart';
import '../models/edit_project.dart';
import '../services/video_probe_service.dart';
import '../widgets/clip_timeline.dart';
import '../widgets/editor_action_bar.dart';
import '../widgets/split_clip_dialog.dart';
import '../widgets/trim_clip_sheet.dart';
import 'video_render_screen.dart';

/// Timeline editor: add/trim/split/delete/reorder clips with undo/redo.
/// "Add clip" pulls another clip from the gallery — this feature doesn't
/// re-enter the camera flow, keeping it independent of whatever capture
/// screen sits in front of it. Rendering hands the final file off to
/// [VideoPreviewScreen] — the same publish path used for an unedited video.
class VideoEditScreen extends StatefulWidget {
  const VideoEditScreen({super.key, required this.initialProject});

  final EditProject initialProject;

  @override
  State<VideoEditScreen> createState() => _VideoEditScreenState();
}

class _VideoEditScreenState extends State<VideoEditScreen> {
  late final VideoEditController _controller;
  final _picker = ImagePicker();
  final _probe = const VideoProbeService();
  VideoPlayerController? _previewController;
  String? _previewingClipId;

  @override
  void initState() {
    super.initState();
    _controller = VideoEditController(initialProject: widget.initialProject);
    _controller.addListener(_onProjectChanged);
    if (widget.initialProject.clips.isNotEmpty) {
      _loadPreview(widget.initialProject.clips.first.id);
    }
  }

  void _onProjectChanged() {
    // Drop the preview if its clip was deleted/split away.
    final stillExists =
        _controller.project.clips.any((clip) => clip.id == _previewingClipId);
    if (!stillExists) {
      _previewController?.dispose();
      _previewController = null;
      _previewingClipId = null;
      if (_controller.project.clips.isNotEmpty) {
        _loadPreview(_controller.project.clips.first.id);
      }
    }
  }

  Future<void> _loadPreview(String clipId) async {
    final clip = _controller.project.clips.firstWhere((c) => c.id == clipId);
    final previous = _previewController;
    _previewingClipId = clipId;

    final next = VideoPlayerController.file(File(clip.sourcePath));
    await next.initialize();
    await previous?.dispose();

    if (!mounted) {
      await next.dispose();
      return;
    }
    setState(() => _previewController = next);
  }

  Future<void> _addClip() async {
    final picked = await _picker.pickVideo(source: ImageSource.gallery);
    if (picked == null || !mounted) return;

    final file = File(picked.path);
    final durationMs = await _probe.durationMs(file);
    if (!mounted) return;
    _controller.addClip(sourcePath: file.path, durationMs: durationMs);
    await _loadPreview(_controller.project.clips.last.id);
  }

  Future<void> _trimSelected(String clipId) async {
    final clip = _controller.project.clips.firstWhere((c) => c.id == clipId);
    final range = await TrimClipSheet.show(context, clip);
    if (range == null) return;
    _controller.trimClip(clipId: clipId, startMs: range.$1, endMs: range.$2);
  }

  Future<void> _splitSelected(String clipId) async {
    final clip = _controller.project.clips.firstWhere((c) => c.id == clipId);
    final position = await SplitClipDialog.show(context, clip);
    if (position == null) return;
    _controller.splitClip(clipId: clipId, timelinePositionMs: position);
  }

  Future<void> _goToRender() async {
    final navigator = Navigator.of(context);
    final renderedFile = await navigator.push<File>(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<VideoEditController>.value(
          value: _controller,
          child: const VideoRenderScreen(),
        ),
      ),
    );
    if (renderedFile == null || !mounted) return;
    navigator.pushReplacement(
      MaterialPageRoute(
        builder: (_) => VideoPreviewScreen(file: renderedFile),
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onProjectChanged);
    _previewController?.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<VideoEditController>.value(
      value: _controller,
      child: Consumer<VideoEditController>(
        builder: (context, controller, _) {
          final project = controller.project;
          final selectedId = _previewingClipId;

          return Scaffold(
            backgroundColor: const Color(0xFF050816),
            appBar: AppBar(
              backgroundColor: const Color(0xFF050816),
              title: const Text('Edit Video'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: _previewController?.value.isInitialized == true
                          ? AspectRatio(
                              aspectRatio: _previewController!.value.aspectRatio,
                              child: VideoPlayer(_previewController!),
                            )
                          : const Text(
                              'Add a clip to preview it here',
                              style: TextStyle(color: Colors.white54),
                            ),
                    ),
                  ),
                  if (selectedId != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton.icon(
                            onPressed: () => _trimSelected(selectedId),
                            icon: const Icon(Icons.content_cut,
                                color: Colors.white70),
                            label: const Text('Trim',
                                style: TextStyle(color: Colors.white70)),
                          ),
                          TextButton.icon(
                            onPressed: () => _splitSelected(selectedId),
                            icon: const Icon(Icons.call_split,
                                color: Colors.white70),
                            label: const Text('Split',
                                style: TextStyle(color: Colors.white70)),
                          ),
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: ClipTimeline(
                      clips: project.clips,
                      selectedClipId: selectedId,
                      onSelect: _loadPreview,
                      onReorder: controller.reorderClip,
                      onDelete: controller.deleteClip,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: EditorActionBar(
                      canUndo: controller.canUndo,
                      canRedo: controller.canRedo,
                      canRender: project.canRender,
                      onUndo: controller.undo,
                      onRedo: controller.redo,
                      onAddClip: _addClip,
                      onRender: _goToRender,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
