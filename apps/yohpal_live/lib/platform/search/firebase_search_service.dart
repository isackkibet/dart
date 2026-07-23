import 'package:cloud_firestore/cloud_firestore.dart';
import 'yohpal_search_service.dart';

class FirebaseSearchService implements YohPalSearchService {
  final FirebaseFirestore firestore;
  FirebaseSearchService({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;
  @override
  Future<List<YohPalSearchResult>> search(String query) async {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return [];
    final snap = await firestore
        .collection('searchIndex')
        .where('keywords', arrayContains: normalized)
        .limit(25)
        .get();
    return snap.docs.map((doc) {
      final data = doc.data();
      return YohPalSearchResult(
        id: doc.id,
        type: data['type'] ?? 'unknown',
        title: data['title'] ?? '',
        subtitle: data['subtitle'] ?? '',
        route: data['route'] ?? '/',
      );
    }).toList();
  }
}
