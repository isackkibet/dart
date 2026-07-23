import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/payout_request_model.dart';
import '../repositories/creator_earnings_repository.dart';

class PayoutHistoryScreen extends StatelessWidget {
  const PayoutHistoryScreen({super.key});

  static const routeName = '/payout-history';

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final repo = context.read<CreatorEarningsRepository>();

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      appBar: AppBar(
        backgroundColor: const Color(0xFF050816),
        title: const Text('Payout History'),
      ),
      body: StreamBuilder<List<PayoutRequestModel>>(
        stream: repo.watchPayoutRequests(user.uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final payouts = snapshot.data!;
          if (payouts.isEmpty) {
            return const Center(
              child: Text('No payout requests yet',
                  style: TextStyle(color: Colors.white54)),
            );
          }
          return ListView.builder(
            itemCount: payouts.length,
            itemBuilder: (context, index) {
              final payout = payouts[index];
              return Card(
                color: const Color(0xFF101527),
                child: ListTile(
                  title: Text(
                    '${payout.currency} ${payout.amount}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    payout.status,
                    style: const TextStyle(color: Colors.white54),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
