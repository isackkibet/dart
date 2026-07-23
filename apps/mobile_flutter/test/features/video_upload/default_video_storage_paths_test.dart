import 'package:flutter_test/flutter_test.dart';
import 'package:yohpal_live_v2/features/video_upload/services/default_video_storage_paths.dart';

void main() {
  group('DefaultVideoStoragePaths', () {
    test('builds a raw-video path under the app documents raw_videos folder', () {
      final path = DefaultVideoStoragePaths.rawVideoPath(
        baseDirectory: '/tmp/app-docs',
        fileName: 'clip.mp4',
      );

      expect(path, '/tmp/app-docs/raw_videos/clip.mp4');
    });
  });
}
