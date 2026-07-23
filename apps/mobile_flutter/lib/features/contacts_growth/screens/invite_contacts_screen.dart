import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/contacts_controller.dart';
import '../widgets/invite_contact_card.dart';

class InviteContactsScreen extends StatelessWidget {
  const InviteContactsScreen({super.key});

  static const routeName = '/invite';

  Future<void> _inviteViaWhatsApp({
    required String phone,
    required String link,
  }) async {
    final message = Uri.encodeComponent(
      'Join me on YohPal Live — the future of short videos, live streaming, '
      'business live commerce, and AI creator tools: $link',
    );
    final url = Uri.parse(
        'https://wa.me/${phone.replaceAll('+', '')}?text=$message');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _inviteViaSms({
    required String phone,
    required String link,
  }) async {
    final message = Uri.encodeComponent('Join me on YohPal Live: $link');
    final url = Uri.parse('sms:$phone?body=$message');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final controller = context.watch<ContactsController>();

    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      appBar: AppBar(
        backgroundColor: const Color(0xFF050816),
        title: const Text('Invite Contacts'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            'Turn your network into your YohPal growth engine.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: controller.loading || user == null
                ? null
                : () => controller.importAndRankContacts(user.uid),
            icon: const Icon(Icons.contacts),
            label:
                Text(controller.loading ? 'Importing...' : 'Import Contacts'),
          ),
          if (controller.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                controller.error!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          const SizedBox(height: 20),
          if (controller.contacts.isEmpty)
            const Text(
              'No contacts imported yet.',
              style: TextStyle(color: Colors.white54),
            )
          else
            ...controller.contacts.map(
              (contact) => InviteContactCard(
                contact: contact,
                onWhatsApp: () async {
                  if (user == null) return;
                  final link = await controller.createReferralLink(
                    ownerUserId: user.uid,
                    channel: 'whatsapp',
                  );
                  await _inviteViaWhatsApp(
                    phone: contact.normalizedPhone,
                    link: link,
                  );
                },
                onSms: () async {
                  if (user == null) return;
                  final link = await controller.createReferralLink(
                    ownerUserId: user.uid,
                    channel: 'sms',
                  );
                  await _inviteViaSms(
                    phone: contact.normalizedPhone,
                    link: link,
                  );
                },
                onCopy: () async {
                  if (user == null) return;
                  final link = await controller.createReferralLink(
                    ownerUserId: user.uid,
                    channel: 'copy',
                  );
                  await Clipboard.setData(ClipboardData(text: link));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Referral link copied')),
                    );
                  }
                },
              ),
            ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () async {
              if (user == null) return;
              final link = await controller.createReferralLink(
                ownerUserId: user.uid,
                channel: 'share_sheet',
              );
              await SharePlus.instance.share(ShareParams(
                text:
                    'Join me on YohPal Live — AI short videos, live streaming, '
                    'and live commerce: $link',
              ));
            },
            icon: const Icon(Icons.share),
            label: const Text('Share General Invite'),
          ),
        ],
      ),
    );
  }
}
