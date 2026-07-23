import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/web_handoff/yohpal_web_handoff.dart';
import '../repositories/subscription_repository.dart';

class CreatorSubscriptionScreen extends StatefulWidget {
  final String creatorId;

  const CreatorSubscriptionScreen({
    super.key,
    required this.creatorId,
  });

  static const routeName = '/creator-subscriptions';

  @override
  State<CreatorSubscriptionScreen> createState() =>
      _CreatorSubscriptionScreenState();
}

class _CreatorSubscriptionScreenState extends State<CreatorSubscriptionScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final repo = context.read<SubscriptionRepository>();

    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      appBar: AppBar(
        backgroundColor: const Color(0xFF050816),
        title: const Text('Creator Subscriptions'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          if (user?.uid == widget.creatorId) ...[
            TextField(
              controller: _title,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Plan title'),
            ),
            TextField(
              controller: _description,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            TextField(
              controller: _price,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Monthly price'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                repo.createPlan(
                  creatorId: widget.creatorId,
                  title: _title.text.trim(),
                  description: _description.text.trim(),
                  price: num.tryParse(_price.text) ?? 0,
                );
              },
              child: const Text('Create Plan'),
            ),
          ],
          const SizedBox(height: 20),
          StreamBuilder(
            stream: repo.watchCreatorPlans(widget.creatorId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              final plans = snapshot.data!;
              if (plans.isEmpty) {
                return const Text(
                  'No plans yet.',
                  style: TextStyle(color: Colors.white54),
                );
              }
              return Column(
                children: plans
                    .map(
                      (plan) => Card(
                        color: const Color(0xFF101527),
                        child: ListTile(
                          title: Text(
                            plan.title,
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            '${plan.description}\n${plan.currency} ${plan.price}/month',
                            style: const TextStyle(color: Colors.white54),
                          ),
                          trailing: user == null || user.uid == widget.creatorId
                              ? null
                              : ElevatedButton(
                                  onPressed: () async {
                                    await context
                                        .read<YohPalWebHandoff>()
                                        .openSubscriptionCheckout(
                                          creatorId: widget.creatorId,
                                          viewerId: user.uid,
                                          planId: plan.id,
                                        );
                                  },
                                  child: const Text('Subscribe on Web'),
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
