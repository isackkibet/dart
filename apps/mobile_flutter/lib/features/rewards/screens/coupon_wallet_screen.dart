import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../design_system/tokens/yohpal_brand_colors.dart';

class CouponWalletScreen extends StatelessWidget {
  const CouponWalletScreen({super.key});

  static const routeName = '/coupon-wallet';

  Stream<QuerySnapshot<Map<String, dynamic>>> _stream(String uid) {
    return FirebaseFirestore.instance
        .collection('smartCoupons')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    if (user == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          title: const Text('Coupon Wallet'),
        ),
        body: Center(
          child: Text('Sign in to view your coupons.',
              style: TextStyle(color: onSurface.withValues(alpha: 0.7))),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: const Text('Coupon Wallet'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/ads-arena'),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Earn More'),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _stream(user.uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Text('Could not load coupons.\n${snap.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent)),
            );
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.confirmation_number_outlined,
                      color: onSurface.withValues(alpha: 0.24), size: 64),
                  const SizedBox(height: 16),
                  Text('No coupons yet.',
                      style: TextStyle(
                          color: onSurface.withValues(alpha: 0.6),
                          fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Watch rewarded ads in Ads Arena to earn coupons.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: onSurface.withValues(alpha: 0.4),
                          fontSize: 13)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data();
              final code = data['code'] as String? ?? '—';
              final desc = data['description'] as String? ?? '';
              final value = data['value'];
              final type = data['couponType'] as String? ?? 'discount';
              final redeemed = data['redeemed'] == true;

              return Card(
                color: redeemed
                    ? theme.scaffoldBackgroundColor
                    : theme.cardColor,
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: Icon(
                    Icons.confirmation_number_outlined,
                    color: redeemed
                        ? onSurface.withValues(alpha: 0.24)
                        : YohPalBrandColors.gold,
                  ),
                  title: Text(
                    code,
                    style: TextStyle(
                      color: redeemed
                          ? onSurface.withValues(alpha: 0.4)
                          : onSurface,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  subtitle: Text(
                    desc.isNotEmpty ? desc : type,
                    style: TextStyle(color: onSurface.withValues(alpha: 0.6)),
                  ),
                  trailing: redeemed
                      ? Chip(
                          label: const Text('Used',
                              style: TextStyle(fontSize: 11)),
                          backgroundColor: theme.scaffoldBackgroundColor,
                          labelStyle:
                              TextStyle(color: onSurface.withValues(alpha: 0.4)),
                        )
                      : Text(
                          value != null ? '$value' : '',
                          style: const TextStyle(
                              color: YohPalBrandColors.deepGold,
                              fontWeight: FontWeight.bold),
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
