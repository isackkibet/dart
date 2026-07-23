import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/firebase.dart' as fb;

class VideoSafetyService {
  final FirebaseFirestore? _firestore;

  VideoSafetyService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? fb.tryFirebaseFirestore();

  Future<void> reportVideo({
    required String userId,
    required String videoId,
    required String creatorId,
    required String reason,
  }) async {
    final fs = _firestore;
    if (fs == null) return;
    await fs.collection('videoReports').add({
      'reportedBy': userId,
      'videoId': videoId,
      'creatorId': creatorId,
      'reason': reason,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markNotInterested({
    required String userId,
    required String creatorId,
    required String videoId,
  }) async {
    final fs = _firestore;
    if (fs == null) return;
    await fs
        .collection('userNotInterested')
        .doc('${userId}_$creatorId')
        .set({
      'userId': userId,
      'creatorId': creatorId,
      'videoId': videoId,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> blockCreator({
    required String userId,
    required String creatorId,
  }) async {
    final fs = _firestore;
    if (fs == null) return;
    if (userId == creatorId) return;
    await fs
        .collection('userBlocks')
        .doc('${userId}_$creatorId')
        .set({
      'userId': userId,
      'blockedUid': creatorId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<bool> isBlocked({
    required String userId,
    required String creatorId,
  }) async {
    final fs = _firestore;
    if (fs == null) return false;
    final doc = await fs
        .collection('userBlocks')
        .doc('${userId}_$creatorId')
        .get();
    return doc.exists;
  }
}