import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'media_worker_job.dart';
class MediaWorkerJobRepository {
  final FirebaseFirestore firestore;
  final FirebaseFunctions functions;
  MediaWorkerJobRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : firestore = firestore ?? FirebaseFirestore.instance,
        functions = functions ?? FirebaseFunctions.instance;
  Stream<List<MediaWorkerJob>> watchSessionJobs(String sessionId) {
    return firestore
        .collection('mediaWorkerJobs')
        .where('sessionId', isEqualTo: sessionId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => MediaWorkerJob.fromMap(doc.id, doc.data()))
            .toList());
  }
  Future<String> dispatchJob({
    required String sessionId,
    required String creatorId,
    required String jobType,
    required String inputUrl,
  }) async {
    final callable = functions.httpsCallable('mediaWorkerDispatch');
    final result = await callable.call({
      'sessionId': sessionId,
      'creatorId': creatorId,
      'jobType': jobType,
      'inputUrl': inputUrl,
    });
    return result.data['jobId'].toString();
  }
  Future<void> retryJob(String jobId) async {
    final callable = functions.httpsCallable('retryMediaWorkerJob');
    await callable.call({'jobId': jobId});
  }
}
