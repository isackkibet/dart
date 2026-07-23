import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/firebase.dart' as fb;
import '../health/enterprise_health.dart';
import '../digital_twin/yohpal_digital_twin.dart';
import '../predictive/predictive_risk.dart';
import 'mission_control_service.dart';

class FirestoreMissionControlService implements MissionControlService {
  final FirebaseFirestore? _firestore;

  FirestoreMissionControlService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? fb.tryFirebaseFirestore();

  @override
  Stream<YohPalDigitalTwin> watchEcosystem() {
    final fs = _firestore;
    if (fs == null) return const Stream.empty();
    return fs
        .collection('missionControlHealth')
        .snapshots()
        .map((snap) {
      final modules = snap.docs.map((doc) {
        final d = doc.data();
        return EnterpriseHealth(
          module: doc.id,
          status: _parseStatus(d['status'] as String? ?? 'healthy'),
          availability: (d['availability'] as num? ?? 100).toDouble(),
          latencyMs: (d['latencyMs'] as num? ?? 0).toDouble(),
          activeUsers: (d['activeUsers'] as int? ?? 0),
          incidents: (d['incidents'] as int? ?? 0),
        );
      }).toList();
      return YohPalDigitalTwin(modules: modules, lastUpdated: DateTime.now());
    });
  }

  @override
  Future<List<PredictiveRisk>> getPredictiveRisks() async {
    final fs = _firestore;
    if (fs == null) return [];
    final snap =
        await fs.collection('missionControlHealth').get();
    final risks = <PredictiveRisk>[];
    for (final doc in snap.docs) {
      final d = doc.data();
      final latency = (d['latencyMs'] as num? ?? 0).toDouble();
      final failureRate = (d['walletFailureRate'] as num? ?? 0).toDouble();
      final ffmpegQueue = (d['ffmpegQueueDepth'] as int? ?? 0);
      final firestoreReads = (d['firestoreReadsPerSecond'] as int? ?? 0);

      final candidates = [
        if (doc.id == 'live') PredictiveRiskDetector.liveLatencyRising(latency),
        if (doc.id == 'wallet')
          PredictiveRiskDetector.walletFailuresRising(failureRate),
        if (doc.id == 'brain') PredictiveRiskDetector.aiLatencyRising(latency),
        if (doc.id == 'live')
          PredictiveRiskDetector.ffmpegQueueBuilding(ffmpegQueue),
        if (doc.id == 'platform')
          PredictiveRiskDetector.firestoreReadsSpike(firestoreReads),
      ];
      risks.addAll(candidates.whereType<PredictiveRisk>());
    }
    risks.sort((a, b) => b.probability.compareTo(a.probability));
    return risks;
  }

  @override
  Future<void> acknowledgeIncident(String incidentId) async {
    final fs = _firestore;
    if (fs == null) return;
    await fs
        .collection('missionControlIncidents')
        .doc(incidentId)
        .update({'acknowledgedAt': FieldValue.serverTimestamp()});
  }

  @override
  Future<void> triggerRollback(String release) async {
    final fs = _firestore;
    if (fs == null) return;
    await fs.collection('missionControlCommands').add({
      'command': 'rollback',
      'release': release,
      'issuedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> pauseRollout(String module) async {
    final fs = _firestore;
    if (fs == null) return;
    await fs.collection('missionControlCommands').add({
      'command': 'pauseRollout',
      'module': module,
      'issuedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> resumeRollout(String module) async {
    final fs = _firestore;
    if (fs == null) return;
    await fs.collection('missionControlCommands').add({
      'command': 'resumeRollout',
      'module': module,
      'issuedAt': FieldValue.serverTimestamp(),
    });
  }

  HealthStatus _parseStatus(String raw) {
    switch (raw) {
      case 'warning':
        return HealthStatus.warning;
      case 'critical':
        return HealthStatus.critical;
      default:
        return HealthStatus.healthy;
    }
  }
}