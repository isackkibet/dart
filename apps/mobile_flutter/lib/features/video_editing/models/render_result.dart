/// Output of a successful local FFmpeg render.
final class RenderResult {
  const RenderResult({
    required this.outputPath,
    required this.durationMs,
    required this.sizeBytes,
    required this.sha256,
  });

  final String outputPath;
  final int durationMs;
  final int sizeBytes;
  final String sha256;
}
