import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../models/edit_project.dart';
import '../models/render_result.dart';
import 'ffmpeg_command_builder.dart';
import 'local_video_renderer.dart';

final class RenderCancelledException implements Exception {
  const RenderCancelledException();

  @override
  String toString() => 'Video rendering was cancelled.';
}

final class FfmpegLocalRenderer implements LocalVideoRenderer {
  FfmpegLocalRenderer({
    FfmpegCommandBuilder builder = const FfmpegCommandBuilder(),
  }) : _builder = builder;

  final FfmpegCommandBuilder _builder;

  int? _activeSessionId;
  bool _cancelled = false;

  @override
  Future<RenderResult> render({
    required EditProject project,
    required String outputPath,
    RenderProgressCallback? onProgress,
  }) async {
    _cancelled = false;

    final temporaryRoot = await getTemporaryDirectory();
    final workspace = Directory(
      path.join(temporaryRoot.path, 'video_edit_render_${project.id}'),
    );

    if (await workspace.exists()) {
      await workspace.delete(recursive: true);
    }
    await workspace.create(recursive: true);

    try {
      final commands = _builder.build(
        project: project,
        workspaceDirectory: workspace.path,
        outputPath: outputPath,
      );
      final concatManifestPath = _builder.concatManifestPath(workspace.path);
      final segmentPaths = List<String>.generate(
        commands.length - 1,
        (index) => path.join(workspace.path, 'segment_$index.mp4'),
      );
      await File(concatManifestPath).writeAsString(
        _builder.buildConcatManifest(segmentPaths),
      );

      // Last command is the concat step; everything before it is one
      // per-clip trim, run in order so progress reflects clip count.
      final trimCommands = commands.sublist(0, commands.length - 1);
      final concatCommand = commands.last;

      for (var index = 0; index < trimCommands.length; index++) {
        await _execute(_builder.joinArgs(trimCommands[index]));
        onProgress?.call(((index + 1) / (trimCommands.length + 1)) * 0.85);
      }

      await _execute(_builder.joinArgs(concatCommand));
      onProgress?.call(0.95);

      final output = File(outputPath);
      if (!await output.exists()) {
        throw StateError('FFmpeg completed without creating output.');
      }

      final bytes = await output.readAsBytes();
      final digest = sha256.convert(bytes).toString();

      onProgress?.call(1);

      return RenderResult(
        outputPath: output.path,
        durationMs: project.totalEditedDurationMs,
        sizeBytes: bytes.length,
        sha256: digest,
      );
    } finally {
      _activeSessionId = null;
      if (await workspace.exists()) {
        await workspace.delete(recursive: true);
      }
    }
  }

  Future<void> _execute(String command) async {
    if (_cancelled) {
      throw const RenderCancelledException();
    }

    final session = await FFmpegKit.execute(command);
    _activeSessionId = session.getSessionId();

    final returnCode = await session.getReturnCode();

    if (_cancelled) {
      throw const RenderCancelledException();
    }

    if (!ReturnCode.isSuccess(returnCode)) {
      final logs = await session.getAllLogsAsString();
      throw StateError('FFmpeg failed: ${logs ?? 'No logs returned.'}');
    }
  }

  @override
  Future<void> cancel() async {
    _cancelled = true;
    final sessionId = _activeSessionId;
    if (sessionId != null) {
      await FFmpegKit.cancel(sessionId);
    }
  }
}
