import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';

FirebaseApp? tryFirebaseApp() {
  try { return Firebase.app(); } catch (_) { return null; }
}

FirebaseAuth? tryFirebaseAuth() {
  try { return FirebaseAuth.instance; } catch (_) { return null; }
}

FirebaseFirestore? tryFirebaseFirestore() {
  try { return FirebaseFirestore.instance; } catch (_) { return null; }
}

FirebaseMessaging? tryFirebaseMessaging() {
  try { return FirebaseMessaging.instance; } catch (_) { return null; }
}

FirebaseStorage? tryFirebaseStorage() {
  try { return FirebaseStorage.instance; } catch (_) { return null; }
}

FirebaseFunctions? tryFirebaseFunctions({String region = 'europe-west2'}) {
  try { return FirebaseFunctions.instanceFor(region: region); } catch (_) { return null; }
}
