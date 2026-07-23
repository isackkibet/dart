import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/firebase.dart' as fb;
import '../../video_feed/models/video_model.dart';
import '../models/creator_profile_model.dart';

class CreatorProfileRepository {
  final FirebaseFirestore? _firestore;

  CreatorProfileRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? fb.tryFirebaseFirestore();

  Stream<CreatorProfileModel?> watchCreatorProfile(String uid) {
    final fs = _firestore;
    if (fs == null) return const Stream.empty();
    return fs
        .collection('creatorProfiles')
        .doc(uid)
        .snapshots()
        .asyncMap((doc) async {
      final profileData = doc.exists ? doc.data()! : <String, dynamic>{};
      final needsUserData = !doc.exists ||
          (profileData['displayName'] as String? ?? '').isEmpty;
      if (needsUserData) {
        final userDoc = await fs.collection('users').doc(uid).get();
        if (!doc.exists) {
          if (!userDoc.exists) return null;
          return CreatorProfileModel.fromUserMap(uid, userDoc.data()!);
        }
        if (userDoc.exists) {
          final merged = {...profileData, ...CreatorProfileModel.displayFieldsFromUserMap(userDoc.data()!)};
          return CreatorProfileModel.fromMap(merged);
        }
        return CreatorProfileModel.fromMap(profileData);
      }
      return CreatorProfileModel.fromMap(profileData);
    });
  }

  Future<CreatorProfileModel?> fetchCreatorProfile(String uid) async {
    final fs = _firestore;
    if (fs == null) return null;
    final doc = await fs.collection('creatorProfiles').doc(uid).get();
    if (!doc.exists) {
      final userDoc = await fs.collection('users').doc(uid).get();
      if (!userDoc.exists) return null;
      return CreatorProfileModel.fromUserMap(uid, userDoc.data()!);
    }
    return CreatorProfileModel.fromMap(doc.data()!);
  }

  Future<List<VideoModel>> fetchCreatorVideos(String uid,
      {int limit = 30}) async {
    final fs = _firestore;
    if (fs == null) return [];
    final snap = await fs
        .collection('videos')
        .where('userId', isEqualTo: uid)
        .where('status', isEqualTo: 'live')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => VideoModel.fromMap(d.id, d.data())).toList();
  }

  Stream<List<VideoModel>> watchCreatorVideos(String uid) {
    final fs = _firestore;
    if (fs == null) return const Stream.empty();
    return fs
        .collection('videos')
        .where('userId', isEqualTo: uid)
        .where('status', isEqualTo: 'live')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => VideoModel.fromMap(d.id, d.data())).toList());
  }

  Future<Map<String, num>> getCreatorAnalytics(String uid) async {
    final fs = _firestore;
    if (fs == null) return {};
    final doc = await fs.collection('creatorAnalytics').doc(uid).get();
    if (!doc.exists) return {};
    final data = doc.data()!;
    return data.map((k, v) => MapEntry(k, (v as num?) ?? 0));
  }

  Future<void> updateProfile({
    required String uid,
    required String displayName,
    required String bio,
    required String photoUrl,
  }) async {
    final fs = _firestore;
    if (fs == null) return;
    await fs.collection('creatorProfiles').doc(uid).set({
      'displayName': displayName,
      'bio': bio,
      'photoUrl': photoUrl,
    }, SetOptions(merge: true));
  }

  Future<int> countCreatorVideos(String uid) async {
    final fs = _firestore;
    if (fs == null) return 0;
    final agg = await fs
        .collection('videos')
        .where('userId', isEqualTo: uid)
        .where('status', isEqualTo: 'live')
        .count()
        .get();
    return agg.count ?? 0;
  }
}
