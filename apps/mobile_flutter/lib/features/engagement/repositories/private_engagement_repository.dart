import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/firebase.dart' as fb;

class PrivateEngagementRepository {
  final FirebaseFirestore? _firestore;

  PrivateEngagementRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? fb.tryFirebaseFirestore();

  Future<void> privateLike({
    required String userId,
    required String creatorId,
    required String videoId,
  }) async {
    final fs = _firestore;
    if (fs == null) return;
    final id = '${videoId}_$userId';
    await fs.collection('privateLikes').doc(id).set({
      'id': id,
      'userId': userId,
      'creatorId': creatorId,
      'videoId': videoId,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> privateComment({
    required String userId,
    required String creatorId,
    required String videoId,
    required String text,
  }) async {
    final fs = _firestore;
    if (fs == null) return;
    if (text.trim().isEmpty) return;
    await fs.collection('privateComments').add({
      'userId': userId,
      'creatorId': creatorId,
      'videoId': videoId,
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'visibleToCreatorOnly': true,
    });
  }
}