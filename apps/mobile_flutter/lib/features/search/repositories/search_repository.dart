import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/firebase.dart' as fb;
import '../models/search_result_model.dart';

class SearchRepository {
  final FirebaseFirestore? _firestore;

  SearchRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? fb.tryFirebaseFirestore();

  Future<List<SearchResultModel>> searchVideos(String query) async {
    final fs = _firestore;
    if (fs == null) return [];
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];
    final snap = await fs
        .collection('videos')
        .where('status', isEqualTo: 'live')
        .where('broken', isEqualTo: false)
        .where('visibility', isEqualTo: 'public')
        .where('searchKeywords', arrayContains: q)
        .limit(30)
        .get();
    return snap.docs
        .map((doc) =>
            SearchResultModel.fromVideo({'id': doc.id, ...doc.data()}))
        .toList();
  }

  Future<List<SearchResultModel>> searchCreators(String query) async {
    final fs = _firestore;
    if (fs == null) return [];
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];
    final snap = await fs
        .collection('creatorProfiles')
        .where('searchKeywords', arrayContains: q)
        .limit(30)
        .get();
    return snap.docs
        .map((doc) =>
            SearchResultModel.fromCreator({'id': doc.id, ...doc.data()}))
        .toList();
  }

  Future<List<SearchResultModel>> searchLive(String query) async {
    final fs = _firestore;
    if (fs == null) return [];
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];
    final snap = await fs
        .collection('liveSessions')
        .where('status', isEqualTo: 'live')
        .where('visibility', isEqualTo: 'public')
        .where('searchKeywords', arrayContains: q)
        .limit(30)
        .get();
    return snap.docs
        .map((doc) =>
            SearchResultModel.fromLive({'id': doc.id, ...doc.data()}))
        .toList();
  }

  Future<List<SearchResultModel>> searchBusinesses(String query) async {
    final fs = _firestore;
    if (fs == null) return [];
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];
    final snap = await fs
        .collection('businessAccounts')
        .where('status', isEqualTo: 'active')
        .where('searchKeywords', arrayContains: q)
        .limit(30)
        .get();
    return snap.docs
        .map((doc) =>
            SearchResultModel.fromBusiness({'id': doc.id, ...doc.data()}))
        .toList();
  }

  Future<void> saveRecentSearch({
    required String userId,
    required String query,
  }) async {
    final fs = _firestore;
    if (fs == null) return;
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return;
    await fs
        .collection('users')
        .doc(userId)
        .collection('recentSearches')
        .doc(q)
        .set({
      'query': q,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<String>> watchRecentSearches(String userId) {
    final fs = _firestore;
    if (fs == null) return const Stream.empty();
    return fs
        .collection('users')
        .doc(userId)
        .collection('recentSearches')
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => doc.data()['query'].toString())
            .toList());
  }

  Stream<List<String>> watchTrendingSearches() {
    final fs = _firestore;
    if (fs == null) return const Stream.empty();
    return fs
        .collection('trendingSearches')
        .orderBy('score', descending: true)
        .limit(10)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => doc.data()['query'].toString())
            .toList());
  }
}