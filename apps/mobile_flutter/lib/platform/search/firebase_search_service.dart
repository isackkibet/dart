import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/firebase.dart' as fb;
import 'yohpal_search_service.dart';

class FirebaseSearchService implements YohPalSearchService {
  final FirebaseFirestore? _firestore;

  FirebaseSearchService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? fb.tryFirebaseFirestore();

  @override
  Future<List<YohPalSearchResult>> search(String query) async {
    final fs = _firestore;
    if (fs == null) return [];
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return [];
    final snap = await fs
        .collection('searchIndex')
        .where('keywords', arrayContains: normalized)
        .limit(25)
        .get();
    return snap.docs.map((doc) {
      final data = doc.data();
      return YohPalSearchResult(
        id: doc.id,
        type: data['type'] as String? ?? 'unknown',
        title: data['title'] as String? ?? '',
        subtitle: data['subtitle'] as String? ?? '',
        route: data['route'] as String? ?? '/',
      );
    }).toList();
  }
}