import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/web_handoff/yohpal_web_handoff.dart';

class GiftCreatorScreen extends StatelessWidget {
  final String creatorId;

  const GiftCreatorScreen({super.key, required this.creatorId});

  static const routeName = '/creator-gift';

  static const _gifts = [
    _GiftTier(
      icon: Icons.local_florist_outlined,
      label: 'Rose',
      points: 10,
      color: Color(0xFFE91E63),
    ),
    _GiftTier(
      icon: Icons.coffee_outlined,
      label: 'Coffee',
      points: 50,
      color: Color(0xFFFF6E40),
    ),
    _GiftTier(
      icon: Icons.emoji_events_outlined,
      label: 'Trophy',
      points: 200,
      color: Color(0xFFFFD600),
    ),
    _GiftTier(
      icon: Icons.diamond_outlined,
      label: 'Diamond',
      points: 1000,
      color: Color(0xFF00BCD4),
    ),
    _GiftTier(
      icon: Icons.rocket_launch_outlined,
      label: 'Rocket',
      points: 5000,
      color: Color(0xFF7C4DFF),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050510),
      appBar: AppBar(
        backgroundColor: const Color(0xFF050510),
        title: const Text('Gift Creator'),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Send a gift to support this creator. All gifts are processed securely via YohPal Web.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ),
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              padding: const EdgeInsets.all(16),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: _gifts
                  .map((g) => _GiftCard(
                        tier: g,
                        onTap: () => _openWebGift(context, g),
                      ))
                  .toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            child: Column(
              children: [
                const Row(
                  children: [
                    Icon(Icons.lock_outline, color: Colors.white38, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'Gifts are sent securely via YohPal Web Wallet',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C4DFF),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.open_in_new, color: Colors.white),
                    label: const Text('Open Gift Centre on Web',
                        style: TextStyle(color: Colors.white)),
                    onPressed: () => _openWebGiftCentre(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openWebGift(BuildContext context, _GiftTier tier) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sending ${tier.label} gift (${tier.points} pts) — opening web wallet...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    _openWebGiftCentre(context);
  }

  void _openWebGiftCentre(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sign in to send gifts.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    context.read<YohPalWebHandoff>().openWallet(userId: user.uid);
  }
}

class _GiftTier {
  final IconData icon;
  final String label;
  final int points;
  final Color color;

  const _GiftTier({
    required this.icon,
    required this.label,
    required this.points,
    required this.color,
  });
}

class _GiftCard extends StatelessWidget {
  final _GiftTier tier;
  final VoidCallback onTap;

  const _GiftCard({required this.tier, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF101020),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tier.color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(tier.icon, color: tier.color, size: 36),
            const SizedBox(height: 8),
            Text(tier.label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text('${tier.points} pts',
                style: TextStyle(color: tier.color, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
