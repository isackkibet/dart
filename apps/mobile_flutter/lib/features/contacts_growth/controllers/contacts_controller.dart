import 'package:flutter/foundation.dart';
import '../models/imported_contact_model.dart';
import '../repositories/contacts_repository.dart';
import '../services/contact_import_service.dart';

class ContactsController extends ChangeNotifier {
  final ContactImportService importService;
  final ContactsRepository repository;

  ContactsController({
    required this.importService,
    required this.repository,
  });

  bool loading = false;
  String? error;
  List<ImportedContactModel> contacts = [];

  Future<void> importAndRankContacts(String ownerUserId) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final rawContacts = await importService.importContacts();
      contacts = await repository.saveImportedContacts(
        ownerUserId: ownerUserId,
        contacts: rawContacts,
      );
      contacts.sort((a, b) => b.inviteScore.compareTo(a.inviteScore));
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<String> createReferralLink({
    required String ownerUserId,
    required String channel,
  }) {
    return repository.createReferralLink(
      ownerUserId: ownerUserId,
      channel: channel,
    );
  }
}
