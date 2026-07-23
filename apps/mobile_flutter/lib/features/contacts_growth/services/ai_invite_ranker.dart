import '../models/contact_model.dart';

class AiInviteRanker {
  int score(ContactModel contact) {
    int s = 20;
    if (contact.name.trim().isNotEmpty) s += 15;
    if (contact.normalizedPhone.startsWith('+254')) s += 20;
    if (contact.email != null && contact.email!.isNotEmpty) s += 10;
    final lowerName = contact.name.toLowerCase();
    if (lowerName.contains('mom') ||
        lowerName.contains('dad') ||
        lowerName.contains('bro') ||
        lowerName.contains('sis') ||
        lowerName.contains('manager') ||
        lowerName.contains('client') ||
        lowerName.contains('customer')) {
      s += 20;
    }
    return s.clamp(0, 100);
  }

  List<ContactModel> rank(List<ContactModel> contacts) {
    final ranked = [...contacts];
    ranked.sort((a, b) => score(b).compareTo(score(a)));
    return ranked;
  }
}
