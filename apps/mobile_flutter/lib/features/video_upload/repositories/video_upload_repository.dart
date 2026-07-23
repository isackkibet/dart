import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/firebase.dart' as fb;
import '../models/video_upload_model.dart';

class VideoUploadRepository {
  final FirebaseFirestore? _firestore;

  VideoUploadRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? fb.tryFirebaseFirestore();

  String generateVideoId() {
    final fs = _firestore;
    return fs != null ? fs.collection('videos').doc().id : '';
  }

  Future<String> createVideoDocument({
    required String userId,
    required String ownerUsername,
    required String title,
    String caption = '',
    List<String> hashtags = const [],
    required String rawPath,
    String? videoId,
  }) async {
    final fs = _firestore;
    if (fs == null) return '';
    final ref = videoId != null
        ? fs.collection('videos').doc(videoId)
        : fs.collection('videos').doc();
    final model = VideoUploadModel(
      videoId: ref.id,
      userId: userId,
      ownerUsername: ownerUsername,
      title: title,
      caption: caption,
      hashtags: hashtags,
      rawPath: rawPath,
      status: 'uploading',
      createdAt: DateTime.now(),
    );
    await ref.set(model.toMap());
    return ref.id;
  }

  Future<void> updateVideoStatus({
    required String videoId,
    required String status,
    String? hlsUrl,
    String? hlsStandardUrl,
    String? hlsLowUrl,
    String? posterUrl,
    String? errorMessage,
    double? durationSeconds,
  }) async {
    final fs = _firestore;
    if (fs == null) return;
    final data = <String, dynamic>{
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (hlsUrl != null)          data['hlsUrl'] = hlsUrl;
    if (hlsStandardUrl != null)  data['hlsStandardUrl'] = hlsStandardUrl;
    if (hlsLowUrl != null)       data['hlsLowUrl'] = hlsLowUrl;
    if (posterUrl != null)       data['posterUrl'] = posterUrl;
    if (errorMessage != null)    data['errorMessage'] = errorMessage;
    if (durationSeconds != null) data['durationSeconds'] = durationSeconds;
    await fs.collection('videos').doc(videoId).update(data);
  }

  Future<void> updateVideoThumbnail({
    required String videoId,
    required String thumbnailUrl,
  }) async {
    final fs = _firestore;
    if (fs == null) return;
    await fs.collection('videos').doc(videoId).update({
      'thumbnailUrl': thumbnailUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteVideoDocument(String videoId) async {
    final fs = _firestore;
    if (fs == null) return;
    await fs.collection('videos').doc(videoId).delete();
  }

  Stream<DocumentSnapshot> watchVideo(String videoId) {
    final fs = _firestore;
    if (fs == null) return const Stream.empty();
    return fs.collection('videos').doc(videoId).snapshots();
  }
}
