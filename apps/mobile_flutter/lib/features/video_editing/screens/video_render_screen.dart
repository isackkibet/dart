import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../controllers/video_edit_controller.dart';
import '../services/ffmpeg_local_renderer.dart';
import '../services/render_output_validator.dart';

enum _RenderState { rendering, failed, cancelled }

/// Runs the local FFmpeg render for the current edit session, with progress
/// and cancellation, then validates the output. Pops with the rendered
/// [File] on success — the caller decides what to do with it (this feature
/// doesn't upload or publish anything itself).
class VideoRenderScreen extends StatefulWidget {
  const VideoRenderScreen({super.key});

  @override
  State<VideoRenderScreen> createState() => _VideoRenderScreenState();
}

class _VideoRenderScreenState extends State<VideoRenderScreen> {
  final _renderer = FfmpegLocalRenderer();
  final _validator = const RenderOutputValidator();

  _RenderState _state = _RenderState.rendering;
  double _progress = 0;
  String? _errorMessage;
  List<String> _validationBlockers = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startRender());
  }

  Future<void> _startRender() async {
    final controller = context.read<VideoEditController>();
    setState(() {
      _state = _RenderState.rendering;
      _progress = 0;
      _errorMessage = null;
      _validationBlockers = const [];
    });
    controller.markRendering();

    try {
      final dir = await getApplicationDocumentsDirectory();
      final outputPath =
          path.join(dir.path, 'edit_render_${const Uuid().v4()}.mp4');

      final result = await _renderer.render(
        project: controller.project,
        outputPath: outputPath,
        onProgress: (value) {
          if (!mounted) return;
          setState(() => _progress = value);
        },
      );

      final validation = await _validator.validate(
        project: controller.project,
        result: result,
      );

      if (!validation.valid) {
        if (!mounted) return;
        setState(() {
          _state = _RenderState.failed;
          _validationBlockers = validation.blockers;
        });
        controller.markFailure(
          'Render validation failed: ${validation.blockers.join('; ')}',
        );
        return;
      }

      controller.markRendered(
        outputPath: result.outputPath,
        sha256: result.sha256,
      );

      if (!mounted) return;
      Navigator.of(context).pop(File(result.outputPath));
    } on RenderCancelledException {
      if (!mounted) return;
      setState(() => _state = _RenderState.cancelled);
    } catch (error) {
      controller.markFailure(error);
      if (!mounted) return;
      setState(() {
        _state = _RenderState.failed;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _cancel() async {
    await _renderer.cancel();
  }

  @override
  void dispose() {
    _renderer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      appBar: AppBar(
        backgroundColor: const Color(0xFF050816),
        title: const Text('Rendering'),
        automaticallyImplyLeading: _state != _RenderState.rendering,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _buildContent(),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildContent() {
    switch (_state) {
      case _RenderState.rendering:
        return [
          const CircularProgressIndicator(color: Color(0xFF00D9FF)),
          const SizedBox(height: 20),
          LinearProgressIndicator(value: _progress, minHeight: 6),
          const SizedBox(height: 8),
          Text(
            '${(_progress * 100).toStringAsFixed(0)}% rendering…',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: _cancel,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white24),
            ),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
        ];
      case _RenderState.cancelled:
        return [
          const Icon(Icons.cancel_outlined, color: Colors.white54, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Render cancelled.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _startRender,
            child: const Text('Retry'),
          ),
        ];
      case _RenderState.failed:
        return [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
          const SizedBox(height: 16),
          Text(
            _errorMessage ??
                (_validationBlockers.isNotEmpty
                    ? _validationBlockers.join('\n')
                    : 'Rendering failed.'),
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _startRender,
            child: const Text('Retry'),
          ),
        ];
    }
  }
}
