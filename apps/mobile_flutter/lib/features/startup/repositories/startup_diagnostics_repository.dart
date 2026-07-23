import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/firebase.dart' as fb;
import '../models/startup_diagnostic_model.dart';

class StartupDiagnosticsRepository {
  final FirebaseFirestore? _firestore;

  StartupDiagnosticsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? fb.tryFirebaseFirestore();

  Future<void> record(StartupDiagnosticModel diagnostic) async {
    final fs = _firestore;
    if (fs == null) return;
    try {
      await fs
          .collection('appStartupDiagnostics')
          .add(diagnostic.toMap());
    } catch (_) {
      // Firestore rules may not yet allow writes here; swallow silently.
    }
  }
}