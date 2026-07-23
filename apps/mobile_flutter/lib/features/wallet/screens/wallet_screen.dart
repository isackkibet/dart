import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/wallet_controller.dart';
import '../models/wallet_transaction_model.dart';
import '../repositories/wallet_repository.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  static const routeName = '/wallet';

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final repo = context.read<WalletRepository>();
    final controller = context.watch<WalletController>();
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please sign in')));
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: const Text('Wallet'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          StreamBuilder(
            stream: repo.watchBalance(user.uid),
            builder: (context, snapshot) {
              final balance = snapshot.data;
              return Card(
                color: theme.cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    balance == null
                        ? 'Available: KES 0\nPending: KES 0\nLifetime: KES 0'
                        : 'Available: ${balance.currency} ${balance.available}\n'
                            'Pending: ${balance.currency} ${balance.pending}\n'
                            'Lifetime: ${balance.currency} ${balance.lifetime}',
                    style: TextStyle(color: onSurface, fontSize: 18),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: controller.loading
                ? null
                : () => controller.openWithdrawalWeb(userId: user.uid),
            icon: const Icon(Icons.open_in_new),
            label: Text(
              controller.loading
                  ? 'Opening YohPal Web...'
                  : 'Withdraw on YohPal Web',
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: controller.loading
                ? null
                : () => controller.openWalletWeb(userId: user.uid),
            icon: const Icon(Icons.account_balance_wallet),
            label: const Text('Open Web Wallet'),
          ),
          if (controller.error != null)
            Text(
              controller.error!,
              style: const TextStyle(color: Colors.redAccent),
            ),
          const SizedBox(height: 24),
          Text(
            'Transactions',
            style: TextStyle(color: onSurface, fontSize: 20),
          ),
          StreamBuilder<List<WalletTransactionModel>>(
            stream: repo.watchTransactions(user.uid),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const CircularProgressIndicator();
              }
              final txs = snapshot.data!;
              if (txs.isEmpty) {
                return Text(
                  'No wallet transactions yet.',
                  style: TextStyle(color: onSurface.withValues(alpha: 0.6)),
                );
              }
              return Column(
                children: txs
                    .map(
                      (tx) => Card(
                        color: theme.cardColor,
                        child: ListTile(
                          title: Text(
                            '${tx.currency} ${tx.amount}',
                            style: TextStyle(color: onSurface),
                          ),
                          subtitle: Text(
                            '${tx.type} · ${tx.status}',
                            style: TextStyle(
                                color: onSurface.withValues(alpha: 0.6)),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
