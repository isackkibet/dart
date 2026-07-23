import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/firebase.dart' as fb;
import '../models/playback_diagnostic_model.dart';

class PlaybackDiagnosticsRepository {
  final FirebaseFirestore? _firestore;

  PlaybackDiagnosticsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? fb.tryFirebaseFirestore();

  Future<void> record(PlaybackDiagnosticModel diagnostic) async {
    final fs = _firestore;
    if (fs == null) return;
    try {
      await fs
          .collection('videoPlaybackDiagnostics')
          .add(diagnostic.toMap());
    } catch (_) {
      // Firestore rules may not yet allow writes here; swallow silently.
    }
  }
}