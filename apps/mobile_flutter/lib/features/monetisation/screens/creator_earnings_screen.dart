import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/web_handoff/yohpal_web_handoff.dart';
import '../../../design_system/tokens/yohpal_brand_colors.dart';
import '../models/creator_earning_model.dart';
import '../repositories/creator_earnings_repository.dart';
import 'payout_history_screen.dart';

class CreatorEarningsScreen extends StatelessWidget {
  const CreatorEarningsScreen({super.key});

  static const routeName = '/creator-earnings';

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final repo = context.read<CreatorEarningsRepository>();
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in')),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: const Text('Creator Earnings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () =>
                Navigator.pushNamed(context, PayoutHistoryScreen.routeName),
          ),
        ],
      ),
      body: StreamBuilder<List<CreatorEarningModel>>(
        stream: repo.watchCreatorEarnings(user.uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final earnings = snapshot.data!;
          final summary = _summarise(earnings);

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              _SummaryGrid(summary: summary),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () =>
                    context.read<YohPalWebHandoff>().openWithdrawal(
                          userId: user.uid,
                        ),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Request Payout on YohPal Web'),
              ),
              const SizedBox(height: 24),
              Text('Earnings by Source',
                  style: TextStyle(color: onSurface, fontSize: 20)),
              const SizedBox(height: 8),
              ...earnings.map(
                (e) => Card(
                  color: theme.cardColor,
                  child: ListTile(
                    title: Text(
                      '${e.currency} ${e.amount}',
                      style: const TextStyle(
                          color: YohPalBrandColors.deepGold,
                          fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${e.source} · ${e.status}',
                      style: TextStyle(color: onSurface.withValues(alpha: 0.6)),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Map<String, num> _summarise(List<CreatorEarningModel> earnings) {
    final map = <String, num>{
      'pending': 0,
      'approved': 0,
      'paid': 0,
      'lifetime': 0,
    };
    for (final e in earnings) {
      map['lifetime'] = map['lifetime']! + e.amount;
      if (e.status == 'pending') map['pending'] = map['pending']! + e.amount;
      if (e.status == 'approved') map['approved'] = map['approved']! + e.amount;
      if (e.status == 'paid') map['paid'] = map['paid']! + e.amount;
    }
    return map;
  }
}

class _SummaryGrid extends StatelessWidget {
  final Map<String, num> summary;
  const _SummaryGrid({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    Widget card(String label, num value) => Card(
          color: theme.cardColor,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'KES $value',
                  style:
                      TextStyle(color: onSurface, fontWeight: FontWeight.bold),
                ),
                Text(label,
                    style: TextStyle(color: onSurface.withValues(alpha: 0.6))),
              ],
            ),
          ),
        );

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        card('Pending', summary['pending'] ?? 0),
        card('Approved', summary['approved'] ?? 0),
        card('Paid', summary['paid'] ?? 0),
        card('Lifetime', summary['lifetime'] ?? 0),
      ],
    );
  }
}
