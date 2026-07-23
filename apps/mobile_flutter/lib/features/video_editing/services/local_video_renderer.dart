import '../models/edit_project.dart';
import '../models/render_result.dart';

typedef RenderProgressCallback = void Function(double progress);

abstract interface class LocalVideoRenderer {
  Future<RenderResult> render({
    required EditProject project,
    required String outputPath,
    RenderProgressCallback? onProgress,
  });

  Future<void> cancel();
}
