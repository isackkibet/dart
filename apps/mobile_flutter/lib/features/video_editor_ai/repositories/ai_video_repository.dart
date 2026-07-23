import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/firebase.dart' as fb;
import '../models/ai_video_job.dart';

class AiVideoRepository {
  final FirebaseFirestore? _firestore;

  AiVideoRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? fb.tryFirebaseFirestore();

  Future<String> createJob({
    required String userId,
    required String videoId,
    required String type,
    required Map<String, dynamic> input,
  }) async {
    final fs = _firestore;
    if (fs == null) throw StateError('Firebase not initialized');
    final ref = fs.collection('aiVideoJobs').doc();
    await ref.set({
      'id': ref.id,
      'userId': userId,
      'videoId': videoId,
      'type': type,
      'status': 'queued',
      'input': input,
      'result': {},
      'error': null,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Stream<AiVideoJob?> watchJob(String jobId) {
    final fs = _firestore;
    if (fs == null) return const Stream.empty();
    return fs
        .collection('aiVideoJobs')
        .doc(jobId)
        .snapshots()
        .map((doc) => doc.exists ? AiVideoJob.fromMap(doc.data()!) : null);
  }

  Stream<List<AiVideoJob>> watchUserJobs(String userId) {
    final fs = _firestore;
    if (fs == null) return const Stream.empty();
    return fs
        .collection('aiVideoJobs')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => AiVideoJob.fromMap(doc.data())).toList());
  }
}