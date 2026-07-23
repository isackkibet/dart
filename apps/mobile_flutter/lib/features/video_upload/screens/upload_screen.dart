import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

import '../../video_editing/models/edit_project.dart';
import '../../video_editing/models/edit_project_status.dart';
import '../../video_editing/models/video_clip_edit.dart';
import '../../video_editing/screens/video_edit_screen.dart';
import '../../video_editing/services/video_probe_service.dart';
import '../services/video_draft_service.dart';
import 'video_preview_screen.dart';

enum _CaptureChoice { edit, postAsIs }

enum _Stage { initializing, permissionDenied, error, ready, processing }

/// Combined video-capture entry point: live camera preview to record a new
/// clip, or a button to pick an existing one from the gallery. Either path
/// hands the resulting file to VideoPreviewScreen for review + publishing.
class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  static const routeName = '/upload';

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen>
    with WidgetsBindingObserver {
  final _picker = ImagePicker();
  final _draftService = VideoDraftService();

  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  CameraLensDirection _lensDirection = CameraLensDirection.back;
  _Stage _stage = _Stage.initializing;
  String? _errorMessage;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setup();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      controller.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed && _stage == _Stage.ready) {
      _initializeCamera(_lensDirection);
    }
  }

  Future<void> _setup() async {
    await _maybeOfferDraftResume();
    if (!mounted) return;

    final camera = await Permission.camera.request();
    final mic = await Permission.microphone.request();
    if (!camera.isGranted || !mic.isGranted) {
      if (!mounted) return;
      setState(() => _stage = _Stage.permissionDenied);
      return;
    }

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        if (!mounted) return;
        setState(() {
          _stage = _Stage.error;
          _errorMessage = 'No camera found on this device.';
        });
        return;
      }
      await _initializeCamera(CameraLensDirection.back);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _stage = _Stage.error;
        _errorMessage = 'Could not access the camera: $e';
      });
    }
  }

  Future<void> _maybeOfferDraftResume() async {
    final draft = await _draftService.load();
    if (draft == null) return;
    if (!File(draft.localFilePath).existsSync()) {
      await _draftService.clear();
      return;
    }
    if (!mounted) return;

    final resume = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Resume your draft?'),
        content: const Text(
          'You have an unfinished video from earlier. Continue editing it or start fresh?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Discard'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Resume'),
          ),
        ],
      ),
    );

    if (resume == true) {
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoPreviewScreen(
            file: File(draft.localFilePath),
            initialTitle: draft.title,
            initialCaption: draft.caption,
            initialHashtags: draft.hashtags,
          ),
        ),
      );
    } else {
      await _draftService.clear();
    }
  }

  Future<File> _persistLocally(File source) async {
    final dir = await getApplicationDocumentsDirectory();
    final ext = source.path.contains('.') ? source.path.split('.').last : 'mp4';
    final id = const Uuid().v4();
    final destPath = '${dir.path}/upload_$id.$ext';
    return source.copy(destPath);
  }

  Future<void> _goToPreview(File rawFile) async {
    setState(() => _stage = _Stage.processing);
    File file;
    try {
      file = await _persistLocally(rawFile);
    } catch (_) {
      file = rawFile;
    }
    if (!mounted) return;
    setState(() => _stage = _Stage.ready);

    final choice = await showModalBottomSheet<_CaptureChoice>(
      context: context,
      backgroundColor: const Color(0xFF101527),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _CaptureChoiceSheet(),
    );
    if (!mounted || choice == null) return;

    if (choice == _CaptureChoice.edit) {
      final durationMs = await const VideoProbeService().durationMs(file);
      if (!mounted) return;
      final now = DateTime.now();
      final project = EditProject(
        id: const Uuid().v4(),
        clips: [
          VideoClipEdit(
            id: const Uuid().v4(),
            sourcePath: file.path,
            sourceDurationMs: durationMs,
            trimStartMs: 0,
            trimEndMs: durationMs,
            order: 0,
            createdAt: now,
          ),
        ],
        status: EditProjectStatus.draft,
        createdAt: now,
        updatedAt: now,
      );
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoEditScreen(initialProject: project),
        ),
      );
    } else {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => VideoPreviewScreen(file: file)),
      );
    }
  }

  Future<void> _initializeCamera(CameraLensDirection direction) async {
    final description = _cameras.firstWhere(
      (c) => c.lensDirection == direction,
      orElse: () => _cameras.first,
    );

    final controller = CameraController(
      description,
      ResolutionPreset.high,
      enableAudio: true,
    );

    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _lensDirection = description.lensDirection;
        _stage = _Stage.ready;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _stage = _Stage.error;
        _errorMessage = 'Could not start the camera: $e';
      });
    }
  }

  Future<void> _toggleLens() async {
    if (_cameras.length < 2) return;
    final controller = _controller;
    _controller = null;
    await controller?.dispose();
    final next = _lensDirection == CameraLensDirection.back
        ? CameraLensDirection.front
        : CameraLensDirection.back;
    await _initializeCamera(next);
  }

  Future<void> _startRecording() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    try {
      await controller.startVideoRecording();
      setState(() => _isRecording = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start recording: $e')),
      );
    }
  }

  Future<void> _stopRecording() async {
    final controller = _controller;
    if (controller == null || !controller.value.isRecordingVideo) return;
    try {
      final file = await controller.stopVideoRecording();
      setState(() => _isRecording = false);
      await _goToPreview(File(file.path));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isRecording = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save the recording: $e')),
      );
    }
  }

  Future<void> _pickFromGallery() async {
    final picked = await _picker.pickVideo(source: ImageSource.gallery);
    if (picked == null) return;
    await _goToPreview(File(picked.path));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: _buildBody()),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            if (_stage == _Stage.ready && _cameras.length > 1)
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.cameraswitch, color: Colors.white),
                  onPressed: _toggleLens,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_stage) {
      case _Stage.initializing:
      case _Stage.processing:
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFF00D9FF)),
        );
      case _Stage.permissionDenied:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.no_photography,
                    color: Colors.white70, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Camera and microphone access are required to record video.',
                  style: TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: openAppSettings,
                  child: const Text('Open Settings'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _pickFromGallery,
                  icon: const Icon(Icons.video_library, color: Colors.white),
                  label: const Text('Pick from Gallery instead',
                      style: TextStyle(color: Colors.white)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                  ),
                ),
              ],
            ),
          ),
        );
      case _Stage.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    color: Colors.redAccent, size: 48),
                const SizedBox(height: 16),
                Text(
                  _errorMessage ?? 'Something went wrong.',
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _setup,
                  child: const Text('Retry'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _pickFromGallery,
                  icon: const Icon(Icons.video_library, color: Colors.white),
                  label: const Text('Pick from Gallery instead',
                      style: TextStyle(color: Colors.white)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                  ),
                ),
              ],
            ),
          ),
        );
      case _Stage.ready:
        final controller = _controller;
        if (controller == null || !controller.value.isInitialized) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF00D9FF)),
          );
        }
        return Stack(
          children: [
            Positioned.fill(child: CameraPreview(controller)),
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(width: 56),
                  const Spacer(),
                  GestureDetector(
                    onTap: _isRecording ? _stopRecording : _startRecording,
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      padding: const EdgeInsets.all(6),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          shape: _isRecording
                              ? BoxShape.rectangle
                              : BoxShape.circle,
                          borderRadius:
                              _isRecording ? BorderRadius.circular(6) : null,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _isRecording ? null : _pickFromGallery,
                    icon: const Icon(Icons.video_library,
                        color: Colors.white, size: 32),
                    tooltip: 'Pick from gallery',
                  ),
                ],
              ),
            ),
          ],
        );
    }
  }
}

/// "Edit video" or "Post as is" — shown right after a clip is captured or
/// picked, before either the editor or the existing preview/publish screen.
class _CaptureChoiceSheet extends StatelessWidget {
  const _CaptureChoiceSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () =>
                  Navigator.pop(context, _CaptureChoice.edit),
              icon: const Icon(Icons.content_cut),
              label: const Text('Edit video'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D9FF),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () =>
                  Navigator.pop(context, _CaptureChoice.postAsIs),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white24),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'Post as is',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
