import 'package:cloud_firestore/cloud_firestore.dart';

class PilotAccessService {
  Future<bool> hasPilotAccess(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('pilotUsers')
        .doc(uid)
        .get();
    return doc.exists;
  }
}
