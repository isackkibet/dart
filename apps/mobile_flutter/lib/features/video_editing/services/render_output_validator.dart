import 'dart:io';

import '../models/edit_project.dart';
import '../models/render_result.dart';

final class RenderValidationResult {
  const RenderValidationResult({required this.valid, required this.blockers});

  final bool valid;
  final List<String> blockers;
}

final class RenderOutputValidator {
  const RenderOutputValidator({
    this.maximumSizeBytes = 250 * 1024 * 1024,
    this.durationToleranceMs = 1000,
  });

  final int maximumSizeBytes;
  final int durationToleranceMs;

  Future<RenderValidationResult> validate({
    required EditProject project,
    required RenderResult result,
  }) async {
    final blockers = <String>[];
    final file = File(result.outputPath);

    if (!await file.exists()) {
      blockers.add('Rendered output file does not exist.');
    } else {
      final actualSize = await file.length();

      if (actualSize <= 0) {
        blockers.add('Rendered output is empty.');
      }
      if (actualSize > maximumSizeBytes) {
        blockers.add('Rendered output exceeds the 250 MB limit.');
      }
      if (actualSize != result.sizeBytes) {
        blockers.add('Rendered output size does not match render result.');
      }
    }

    final difference = (project.totalEditedDurationMs - result.durationMs).abs();
    if (difference > durationToleranceMs) {
      blockers.add('Rendered duration differs from the timeline.');
    }

    if (result.sha256.trim().isEmpty) {
      blockers.add('Rendered output checksum is missing.');
    }

    return RenderValidationResult(valid: blockers.isEmpty, blockers: blockers);
  }
}
