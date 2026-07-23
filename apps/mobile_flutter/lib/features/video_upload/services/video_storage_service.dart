import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:video_thumbnail/video_thumbnail.dart';
import '../../../core/firebase.dart' as fb;

class VideoStorageService {
  final FirebaseStorage? _storage;

  VideoStorageService({FirebaseStorage? storage})
      : _storage = storage ?? fb.tryFirebaseStorage();

  UploadTask uploadRawVideo({
    required File file,
    required String rawPath,
  }) {
    final s = _storage;
    if (s == null) throw StateError('Firebase not available');
    return s.ref(rawPath).putFile(
      file,
      SettableMetadata(contentType: 'video/mp4'),
    );
  }

  /// Extracts the video's first frame (`timeMs: 0`) and uploads it as the
  /// thumbnail. Returns null (never throws) so a thumbnail failure never
  /// blocks the upload itself — callers already treat a null result as
  /// "no thumbnail yet."
  Future<String?> generateAndUploadThumbnail({
    required File file,
    required String videoId,
    required String userId,
  }) async {
    final s = _storage;
    if (s == null) return null;
    try {
      final thumbnailBytes = await VideoThumbnail.thumbnailData(
        video: file.path,
        imageFormat: ImageFormat.PNG,
        timeMs: 0,
        maxHeight: 480,
        quality: 80,
      );

      if (thumbnailBytes == null || thumbnailBytes.isEmpty) {
        debugPrint(
          'generateAndUploadThumbnail: VideoThumbnail returned no bytes for $videoId',
        );
        return null;
      }

      final image = img.decodeImage(thumbnailBytes);
      if (image == null) {
        debugPrint(
          'generateAndUploadThumbnail: failed to decode extracted frame for $videoId',
        );
        return null;
      }

      final resized = img.copyResize(image, width: 480);
      final pngBytes = img.encodePng(resized);
      final thumbFile = File('${file.path}_thumb.png')
        ..writeAsBytesSync(pngBytes, flush: true);

      final ref = s.ref('video-thumbnails/$userId/$videoId.png');
      await ref.putFile(
        thumbFile,
        SettableMetadata(contentType: 'image/png'),
      );

      await thumbFile.delete();
      return await ref.getDownloadURL();
    } catch (error) {
      debugPrint('generateAndUploadThumbnail failed for $videoId: $error');
      return null;
    }
  }
}
