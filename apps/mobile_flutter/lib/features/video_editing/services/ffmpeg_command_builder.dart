import 'package:path/path.dart' as path;

import '../models/edit_project.dart';

/// Builds the FFmpeg argument lists needed to render an [EditProject]:
/// one trim command per clip, then a concat of the trimmed segments. Pure
/// string-building — no process execution here, see [FfmpegLocalRenderer].
final class FfmpegCommandBuilder {
  const FfmpegCommandBuilder();

  List<List<String>> build({
    required EditProject project,
    required String workspaceDirectory,
    required String outputPath,
  }) {
    if (!project.hasValidTimeline) {
      throw StateError('Cannot render an invalid or empty timeline.');
    }

    final ordered = [...project.clips]..sort((a, b) => a.order.compareTo(b.order));

    final commands = <List<String>>[];
    final segmentPaths = <String>[];

    for (var index = 0; index < ordered.length; index++) {
      final clip = ordered[index];
      final segmentPath = path.join(workspaceDirectory, 'segment_$index.mp4');
      segmentPaths.add(segmentPath);

      commands.add([
        '-y',
        '-ss', _seconds(clip.trimStartMs),
        '-to', _seconds(clip.trimEndMs),
        '-i', clip.sourcePath,
        '-map', '0:v:0',
        '-map', '0:a?',
        '-c:v', 'libx264',
        '-preset', 'veryfast',
        '-crf', '23',
        '-c:a', 'aac',
        '-b:a', '128k',
        '-movflags', '+faststart',
        segmentPath,
      ]);
    }

    final concatFile = path.join(workspaceDirectory, 'concat.txt');
    commands.add([
      '-y',
      '-f', 'concat',
      '-safe', '0',
      '-i', concatFile,
      '-c', 'copy',
      '-movflags', '+faststart',
      outputPath,
    ]);

    return commands;
  }

  String concatManifestPath(String workspaceDirectory) {
    return path.join(workspaceDirectory, 'concat.txt');
  }

  String buildConcatManifest(List<String> segmentPaths) {
    return segmentPaths
        .map((segment) => "file '${segment.replaceAll("'", "'\\''")}'")
        .join('\n');
  }

  /// FFmpegKit.execute() takes one command string, tokenized like a shell —
  /// quote any argument containing whitespace so paths with spaces survive.
  String joinArgs(List<String> args) {
    return args.map((arg) {
      if (arg.contains(' ')) {
        return '"${arg.replaceAll('"', '\\"')}"';
      }
      return arg;
    }).join(' ');
  }

  String _seconds(int milliseconds) => (milliseconds / 1000).toStringAsFixed(3);
}
