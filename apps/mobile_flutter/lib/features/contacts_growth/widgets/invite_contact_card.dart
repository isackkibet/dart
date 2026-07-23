import 'package:flutter/material.dart';
import '../models/imported_contact_model.dart';

class InviteContactCard extends StatelessWidget {
  final ImportedContactModel contact;
  final VoidCallback onWhatsApp;
  final VoidCallback onSms;
  final VoidCallback onCopy;

  const InviteContactCard({
    super.key,
    required this.contact,
    required this.onWhatsApp,
    required this.onSms,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF101527),
      child: ListTile(
        title: Text(
          contact.name.isEmpty ? contact.phone : contact.name,
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          '${contact.normalizedPhone}\nInvite Score: ${contact.inviteScore}'
          '${contact.existingYohPalUser ? ' · Already on YohPal' : ''}',
          style: const TextStyle(color: Colors.white54),
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'whatsapp') onWhatsApp();
            if (value == 'sms') onSms();
            if (value == 'copy') onCopy();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'whatsapp', child: Text('WhatsApp')),
            PopupMenuItem(value: 'sms', child: Text('SMS')),
            PopupMenuItem(value: 'copy', child: Text('Copy Link')),
          ],
        ),
      ),
    );
  }
}
