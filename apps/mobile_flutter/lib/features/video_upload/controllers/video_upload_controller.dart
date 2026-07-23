import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../repositories/video_upload_repository.dart';
import '../services/video_storage_service.dart';

class VideoUploadController extends ChangeNotifier {
 final VideoUploadRepository repository;
 final VideoStorageService storageService;

 VideoUploadController({
   required this.repository,
   required this.storageService,
 });

 bool uploading = false;
 double progress = 0;
 String? error;
 String? uploadedVideoId;

 /// Clears state left over from a previous attempt. This controller is a
 /// singleton for the app's lifetime, so a fresh VideoPreviewScreen must
 /// call this or it could inherit a stale error/success from an unrelated
 /// earlier upload.
 void reset() {
   if (uploading) return;
   progress = 0;
   error = null;
   uploadedVideoId = null;
   _docCreated = false;
   notifyListeners();
 }

 UploadTask? _task;
 File? _file;
 String? _userId;
 String? _ownerUsername;
 String? _title;
 String? _caption;
 List<String> _hashtags = const [];
 String? _videoId;
 String? _rawPath;
 bool _docCreated = false;

 Future<void> uploadVideo({
   required File file,
   required String userId,
   required String title,
   String caption = '',
   List<String> hashtags = const [],
 }) async {
   uploading = true;
   progress = 0;
   error = null;
   uploadedVideoId = null;
   notifyListeners();

   try {
     final ext = file.path.split('.').last.toLowerCase();
     if (!['mp4', 'mov', 'm4v'].contains(ext)) {
       throw Exception('Only MP4, MOV, and M4V videos are allowed.');
     }

     final size = await file.length();
     const maxBytes = 250 * 1024 * 1024;
     if (size > maxBytes) {
       throw Exception('Video is too large. Maximum allowed size is 250MB.');
     }

     // Look up the user's display name from the users collection
     String ownerUsername = '';
     try {
       final userSnap = await FirebaseFirestore.instance
           .collection('users')
           .doc(userId)
           .get();
       if (userSnap.exists) {
         final u = userSnap.data()!;
         ownerUsername = (u['userName'] as String? ?? '').isNotEmpty
             ? u['userName'] as String
             : (u['username'] as String? ?? '').isNotEmpty
                 ? u['username'] as String
                 : [u['firstName'], u['lastName']]
                     .whereType<String>()
                     .where((s) => s.isNotEmpty)
                     .join(' ');
       }
     } catch (_) {}

     // Pre-generate the doc ID so we can use it as the Storage filename.
     // processVideoUpload CF finds the Firestore doc by videoId from the filename.
     final videoId = repository.generateVideoId();
     final rawPath = 'videos-raw/$userId/$videoId.mp4';

     _file = file;
     _userId = userId;
     _ownerUsername = ownerUsername;
     _title = title;
     _caption = caption;
     _hashtags = hashtags;
     _videoId = videoId;
     _rawPath = rawPath;

     await repository.createVideoDocument(
       userId:        userId,
       ownerUsername: ownerUsername,
       title:         title,
       caption:       caption,
       hashtags:      hashtags,
       rawPath:       rawPath,
       videoId:       videoId,
     );
     _docCreated = true;

     await _runUploadTask(file: file, rawPath: rawPath, videoId: videoId);
   } catch (e) {
     if (e is FirebaseException && e.code == 'canceled') {
       // Handled by cancelUpload(); don't surface as an error.
     } else {
       error = e.toString();
     }
   } finally {
     uploading = false;
     notifyListeners();
   }
 }

 Future<void> _runUploadTask({
   required File file,
   required String rawPath,
   required String videoId,
 }) async {
   final task = storageService.uploadRawVideo(file: file, rawPath: rawPath);
   _task = task;

   task.snapshotEvents.listen((TaskSnapshot snapshot) {
     if (snapshot.totalBytes > 0) {
       progress = snapshot.bytesTransferred / snapshot.totalBytes;
       notifyListeners();
     }
   });

   await task;

   final thumbnailUrl = await storageService.generateAndUploadThumbnail(
     file: file,
     videoId: videoId,
     userId: _userId ?? '',
   );

   if (thumbnailUrl != null && _docCreated) {
     await repository.updateVideoThumbnail(videoId: videoId, thumbnailUrl: thumbnailUrl);
   }

   uploadedVideoId = videoId;
   _task = null;
 }

 /// Cancels the in-flight upload and removes the Firestore doc created for
 /// it, so a cancelled attempt doesn't leave an orphaned `upload_pending`
 /// record behind.
 Future<void> cancelUpload() async {
   await _task?.cancel();
   if (_docCreated && _videoId != null) {
     try {
       await repository.deleteVideoDocument(_videoId!);
     } catch (_) {}
   }
   _docCreated = false;
   uploading = false;
   progress = 0;
   error = null;
   notifyListeners();
 }

 /// Re-attempts the upload using the same file/videoId/rawPath from the
 /// last attempt — the Firestore doc already exists, so this only retries
 /// the Storage transfer.
 Future<void> retryUpload() async {
   final file = _file;
   final rawPath = _rawPath;
   final videoId = _videoId;
   if (file == null || rawPath == null || videoId == null) return;

   uploading = true;
   progress = 0;
   error = null;
   notifyListeners();

   try {
     if (!_docCreated) {
       await repository.createVideoDocument(
         userId:        _userId!,
         ownerUsername: _ownerUsername ?? '',
         title:         _title ?? '',
         caption:       _caption ?? '',
         hashtags:      _hashtags,
         rawPath:       rawPath,
         videoId:       videoId,
       );
       _docCreated = true;
     }
     await _runUploadTask(file: file, rawPath: rawPath, videoId: videoId);
   } catch (e) {
     if (e is FirebaseException && e.code == 'canceled') {
       // Handled by cancelUpload(); don't surface as an error.
     } else {
       error = e.toString();
     }
   } finally {
     uploading = false;
     notifyListeners();
   }
 }
}


