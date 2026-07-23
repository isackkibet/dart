import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../core/firebase.dart' as fb;
import '../models/ycios_project_model.dart';
import '../models/ycios_asset_model.dart';
import '../models/ycios_render_job_model.dart';

class YciosRepository {
  final FirebaseFirestore? _firestore;
  final FirebaseFunctions? _functions;

  YciosRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? fb.tryFirebaseFirestore(),
        _functions = functions ?? fb.tryFirebaseFunctions(region: 'europe-west2');

  Stream<List<YciosProjectModel>> watchProjects(String creatorId) {
    final fs = _firestore;
    if (fs == null) return const Stream.empty();
    return fs
        .collection('yciosProjects')
        .where('creatorId', isEqualTo: creatorId)
        .where('status', whereIn: ['active', 'restored'])
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => YciosProjectModel.fromMap({'id': doc.id, ...doc.data()}))
            .toList());
  }

  Stream<List<YciosProjectModel>> watchArchivedProjects(String creatorId) {
    final fs = _firestore;
    if (fs == null) return const Stream.empty();
    return fs
        .collection('yciosProjects')
        .where('creatorId', isEqualTo: creatorId)
        .where('status', isEqualTo: 'archived')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => YciosProjectModel.fromMap({'id': doc.id, ...doc.data()}))
            .toList());
  }

  Future<String> createProject(String title, String description) async {
    final fn = _functions;
    if (fn == null) throw StateError('Firebase not available');
    final callable = fn.httpsCallable('createYciosProject');
    final result = await callable.call({'title': title, 'description': description});
    return result.data['projectId'] as String;
  }

  Future<void> archiveProject(String projectId) async {
    final fn = _functions;
    if (fn == null) return;
    final callable = fn.httpsCallable('archiveYciosProject');
    await callable.call({'projectId': projectId});
  }

  Future<void> restoreProject(String projectId) async {
    final fn = _functions;
    if (fn == null) return;
    final callable = fn.httpsCallable('restoreYciosProject');
    await callable.call({'projectId': projectId});
  }

  Future<String> duplicateProject(String projectId) async {
    final fn = _functions;
    if (fn == null) throw StateError('Firebase not available');
    final callable = fn.httpsCallable('duplicateYciosProject');
    final result = await callable.call({'projectId': projectId});
    return result.data['projectId'] as String;
  }

  // ── Assets ────────────────────────────────────────────────────────────────

  Stream<List<YciosAssetModel>> watchProjectAssets({
    required String creatorId,
    required String projectId,
  }) {
    final fs = _firestore;
    if (fs == null) return const Stream.empty();
    return fs
        .collection('yciosAssets')
        .where('creatorId', isEqualTo: creatorId)
        .where('projectId', isEqualTo: projectId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => YciosAssetModel.fromMap({'id': doc.id, ...doc.data()}))
            .toList());
  }

  // ── Render Queue ──────────────────────────────────────────────────────────

  Stream<List<YciosRenderJobModel>> watchRenderJobs(String creatorId) {
    final fs = _firestore;
    if (fs == null) return const Stream.empty();
    return fs
        .collection('yciosRenderJobs')
        .where('creatorId', isEqualTo: creatorId)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => YciosRenderJobModel.fromMap({'id': doc.id, ...doc.data()}))
            .toList());
  }

  Future<String> enqueueRenderJob(
      {required String projectId, required String jobType}) async {
    final fn = _functions;
    if (fn == null) throw StateError('Firebase not available');
    final callable = fn.httpsCallable('enqueueYciosRenderJob');
    final result = await callable.call({'projectId': projectId, 'jobType': jobType});
    return result.data['renderJobId'] as String;
  }

  // ── Agent Orchestrator ────────────────────────────────────────────────────

  Future<String> createAgentTask({
    required String projectId,
    required String agentType,
    required String prompt,
  }) async {
    final fn = _functions;
    if (fn == null) throw StateError('Firebase not available');
    final callable = fn.httpsCallable('createYciosAgentTask');
    final result = await callable.call({
      'projectId': projectId,
      'agentType': agentType,
      'prompt': prompt,
    });
    return result.data['taskId'] as String;
  }
}
