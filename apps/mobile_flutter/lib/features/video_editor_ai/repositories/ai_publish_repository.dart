import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/firebase.dart' as fb;
import '../models/ai_publish_status.dart';

class AiPublishRepository {
  final FirebaseFirestore? _db;

  AiPublishRepository({FirebaseFirestore? db})
      : _db = db ?? fb.tryFirebaseFirestore();

  /// Backs PublishEligibility with the persisted status instead of
  /// screen-local widget state, so the AI checklist gate survives
  /// navigating away from and back to the editor screen.
  Stream<AiPublishStatus> watchAiPublishStatus(String videoId) {
    final fs = _db;
    if (fs == null) return const Stream.empty();
    return fs.collection('videos').doc(videoId).snapshots().map((doc) {
      return doc.data()?['aiPublishStatus'] == 'ready'
          ? AiPublishStatus.ready
          : AiPublishStatus.notReady;
    });
  }

  Future<void> applyCaption({
    required String videoId,
    required String caption,
  }) async {
    final fs = _db;
    if (fs == null) return;
    await fs.collection('videos').doc(videoId).set(
      {'caption': caption, 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  Future<void> applyHashtags({
    required String videoId,
    required List<String> hashtags,
  }) async {
    final fs = _db;
    if (fs == null) return;
    await fs.collection('videos').doc(videoId).set(
      {'hashtags': hashtags, 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  Future<void> applyViralScore({
    required String videoId,
    required int score,
    required String explanation,
  }) async {
    final fs = _db;
    if (fs == null) return;
    await fs.collection('videos').doc(videoId).set(
      {
        'aiViralScore': score,
        'aiViralExplanation': explanation,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> applyThumbnailIdea({
    required String videoId,
    required Map<String, dynamic> thumbnailIdea,
  }) async {
    final fs = _db;
    if (fs == null) return;
    await fs.collection('videos').doc(videoId).set(
      {
        'aiThumbnailIdea': thumbnailIdea,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> markAiReadyForPublishing(String videoId) async {
    final fs = _db;
    if (fs == null) return;
    await fs.collection('videos').doc(videoId).set(
      {'aiPublishStatus': 'ready', 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }
}
