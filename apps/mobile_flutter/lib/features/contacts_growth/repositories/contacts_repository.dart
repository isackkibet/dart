import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/firebase.dart' as fb;
import '../models/contact_model.dart';
import '../models/imported_contact_model.dart';
import '../services/ai_invite_ranker.dart';

class ContactsRepository {
  final FirebaseFirestore? _firestore;
  final AiInviteRanker ranker;

  ContactsRepository({
    FirebaseFirestore? firestore,
    AiInviteRanker? ranker,
  })  : _firestore = firestore ?? fb.tryFirebaseFirestore(),
        ranker = ranker ?? AiInviteRanker();

  Future<Map<String, dynamic>?> findExistingUser(
      String normalizedPhone) async {
    final fs = _firestore;
    if (fs == null) return null;
    final snap = await fs
        .collection('users')
        .where('normalizedPhone', isEqualTo: normalizedPhone)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return {'id': snap.docs.first.id, ...snap.docs.first.data()};
  }

  Future<List<ImportedContactModel>> saveImportedContacts({
    required String ownerUserId,
    required List<ContactModel> contacts,
  }) async {
    final fs = _firestore;
    if (fs == null) return [];
    final ranked = ranker.rank(contacts);
    final saved = <ImportedContactModel>[];
    final batch = fs.batch();

    for (final contact in ranked.take(500)) {
      final existing = await findExistingUser(contact.normalizedPhone);
      final imported = ImportedContactModel(
        id: '${ownerUserId}_${contact.normalizedPhone}',
        ownerUserId: ownerUserId,
        name: contact.name,
        phone: contact.phone,
        normalizedPhone: contact.normalizedPhone,
        existingYohPalUser: existing != null,
        matchedUserId: existing?['id'],
        inviteScore: ranker.score(contact),
        importedAt: DateTime.now(),
      );
      final ref = fs
          .collection('users')
          .doc(ownerUserId)
          .collection('importedContacts')
          .doc(imported.id);
      batch.set(ref, imported.toMap());
      saved.add(imported);
    }

    await batch.commit();
    return saved;
  }

  Future<String> createReferralLink({
    required String ownerUserId,
    required String channel,
  }) async {
    final fs = _firestore;
    if (fs == null) throw StateError('Firebase not initialized');
    final ref = fs.collection('referralLinks').doc();
    await ref.set({
      'id': ref.id,
      'ownerUserId': ownerUserId,
      'channel': channel,
      'url': 'https://yohpal.com/invite/${ref.id}',
      'clickCount': 0,
      'installCount': 0,
      'registrationCount': 0,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return 'https://yohpal.com/invite/${ref.id}';
  }

  Future<void> trackReferralEvent({
    required String userId,
    required String referralLinkId,
    required String type,
    String? contactPhone,
  }) async {
    final fs = _firestore;
    if (fs == null) return;
    await fs.collection('referralEvents').add({
      'userId': userId,
      'referralLinkId': referralLinkId,
      'type': type,
      'contactPhone': contactPhone,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}