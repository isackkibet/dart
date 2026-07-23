import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/models/result.dart';
import '../domain/creator_profile.dart';

class CreatorProfileRepository {
  CreatorProfileRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _profiles =>
      _firestore.collection('creatorProfiles');

  Future<Result<CreatorProfile?>> getByUid(String uid) async {
    try {
      final query = await _profiles.where('uid', isEqualTo: uid).limit(1).get();
      if (query.docs.isEmpty) {
        return const Success(null);
      }
      final doc = query.docs.first;
      return Success(CreatorProfile.fromMap(doc.id, doc.data()));
    } catch (error) {
      return Failure(
        AppFailure(
          message: 'Failed to load creator profile.',
          code: 'creator_profile_load_failed',
          details: error,
        ),
      );
    }
  }

  Future<Result<CreatorProfile>> createOrUpdate(CreatorProfile profile) async {
    try {
      final existing = await getByUid(profile.uid);
      if (existing is Failure<CreatorProfile?>) {
        return Failure(existing.failure);
      }
      final existingProfile = existing.dataOrNull;
      if (existingProfile == null) {
        final doc = _profiles.doc();
        final data = {
          ...profile.toMap(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'status': 'active',
        };
        await doc.set(data);
        return Success(
          CreatorProfile.fromMap(doc.id, {
            ...data,
            'createdAt': DateTime.now().toUtc().toIso8601String(),
            'updatedAt': DateTime.now().toUtc().toIso8601String(),
          }),
        );
      }
      await _profiles.doc(existingProfile.id).update({
        ...profile.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return Success(profile);
    } catch (error) {
      return Failure(
        AppFailure(
          message: 'Failed to save creator profile.',
          code: 'creator_profile_save_failed',
          details: error,
        ),
      );
    }
  }
}
