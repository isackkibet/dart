import 'package:flutter_contacts/flutter_contacts.dart';
import '../models/contact_model.dart';

class ContactImportService {
  Future<bool> requestPermission() async {
    return FlutterContacts.requestPermission();
  }

  Future<List<ContactModel>> importContacts() async {
    final allowed = await requestPermission();
    if (!allowed) {
      throw Exception('Contacts permission denied');
    }
    final contacts = await FlutterContacts.getContacts(
      withProperties: true,
      withPhoto: false,
    );
    final output = <ContactModel>[];
    for (final contact in contacts) {
      for (final phone in contact.phones) {
        final normalized = normalizePhone(phone.number);
        if (normalized.isEmpty) continue;
        output.add(
          ContactModel(
            id: '${contact.id}_$normalized',
            name: contact.displayName,
            phone: phone.number,
            normalizedPhone: normalized,
            email:
                contact.emails.isEmpty ? null : contact.emails.first.address,
          ),
        );
      }
    }
    return output;
  }

  String normalizePhone(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.startsWith('+')) return digits;
    if (digits.startsWith('0') && digits.length >= 10) {
      return '+254${digits.substring(1)}';
    }
    if (digits.startsWith('254')) return '+$digits';
    return digits;
  }
}
