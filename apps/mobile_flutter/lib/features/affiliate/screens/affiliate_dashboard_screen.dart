import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../design_system/tokens/yohpal_brand_colors.dart';
import '../controllers/affiliate_controller.dart';
import '../repositories/affiliate_repository.dart';

class AffiliateDashboardScreen extends StatelessWidget {
  const AffiliateDashboardScreen({super.key});

  static const routeName = '/affiliate';

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final controller = context.watch<AffiliateController>();
    final repo = context.read<AffiliateRepository>();
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please sign in')));
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: const Text('Affiliate Growth'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text(
            'Earn by helping YohPal grow.',
            style: TextStyle(color: onSurface.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: controller.loading
                ? null
                : () => controller.generateGeneralLink(user.uid),
            icon: const Icon(Icons.link),
            label: Text(
                controller.loading ? 'Generating...' : 'Generate General Link'),
          ),
          if (controller.latestLink != null) ...[
            const SizedBox(height: 12),
            Card(
              color: theme.cardColor,
              child: ListTile(
                title: Text(
                  controller.latestLink!,
                  style: TextStyle(color: onSurface),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.copy, color: onSurface),
                  onPressed: () => Clipboard.setData(
                    ClipboardData(text: controller.latestLink!),
                  ),
                ),
              ),
            ),
          ],
          if (controller.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                controller.error!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          const SizedBox(height: 20),
          _AffiliateSummary(userId: user.uid, repo: repo),
          const SizedBox(height: 20),
          Text(
            'Your Links',
            style: TextStyle(color: onSurface, fontSize: 20),
          ),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: repo.watchUserLinks(user.uid),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final links = snapshot.data!.docs;
              if (links.isEmpty) {
                return Text(
                  'No affiliate links yet.',
                  style: TextStyle(color: onSurface.withValues(alpha: 0.6)),
                );
              }
              return Column(
                children: links.map((doc) {
                  final data = doc.data();
                  return Card(
                    color: theme.cardColor,
                    child: ListTile(
                      title: Text(
                        data['url'] ?? '',
                        style: TextStyle(color: onSurface),
                      ),
                      subtitle: Text(
                        'Type: ${data['type']} · '
                        'Clicks: ${data['clickCount'] ?? 0} · '
                        'Reg: ${data['registrationCount'] ?? 0} · '
                        'Sales: ${data['purchaseCount'] ?? 0}',
                        style: TextStyle(color: onSurface.withValues(alpha: 0.6)),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.copy, color: onSurface),
                        onPressed: () => Clipboard.setData(
                          ClipboardData(text: data['url'] ?? ''),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            'Commissions',
            style: TextStyle(color: onSurface, fontSize: 20),
          ),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: repo.watchUserCommissions(user.uid),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final commissions = snapshot.data!.docs;
              if (commissions.isEmpty) {
                return Text(
                  'No commissions yet.',
                  style: TextStyle(color: onSurface.withValues(alpha: 0.6)),
                );
              }
              return Column(
                children: commissions.map((doc) {
                  final data = doc.data();
                  return Card(
                    color: theme.cardColor,
                    child: ListTile(
                      title: Text(
                        'KES ${data['commissionAmount'] ?? 0}',
                        style: const TextStyle(
                            color: YohPalBrandColors.deepGold,
                            fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Status: ${data['status']} · Source: ${data['source']}',
                        style: TextStyle(color: onSurface.withValues(alpha: 0.6)),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AffiliateSummary extends StatelessWidget {
  final String userId;
  final AffiliateRepository repo;

  const _AffiliateSummary({required this.userId, required this.repo});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: repo.watchUserCommissions(userId),
      builder: (context, snapshot) {
        num pending = 0;
        num approved = 0;
        num paid = 0;

        if (snapshot.hasData) {
          for (final doc in snapshot.data!.docs) {
            final data = doc.data();
            final amount = (data['commissionAmount'] ?? 0) as num;
            if (data['status'] == 'pending') pending += amount;
            if (data['status'] == 'approved') approved += amount;
            if (data['status'] == 'paid') paid += amount;
          }
        }

        final theme = Theme.of(context);
        final onSurface = theme.colorScheme.onSurface;

        Widget box(String label, num value) {
          return Expanded(
            child: Card(
              color: theme.cardColor,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Text(
                      'KES $value',
                      style: TextStyle(
                        color: onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      label,
                      style: TextStyle(color: onSurface.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Row(
          children: [
            box('Pending', pending),
            box('Approved', approved),
            box('Paid', paid),
          ],
        );
      },
    );
  }
}
