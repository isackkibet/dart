import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/web_handoff/yohpal_web_handoff.dart';
import '../../../design_system/tokens/yohpal_brand_colors.dart';
import '../../../shared/widgets/yohpal_hub_card.dart';

class TimelineOverlayScreen extends StatelessWidget {
  const TimelineOverlayScreen({super.key});

  static const routeName = '/timeline-overlay-detail';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = theme.scaffoldBackgroundColor;
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: const Text('Shop / Book / Apply'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text(
              'Take action directly from the video timeline.',
              style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 14),
            ),
          ),
          YohPalHubCard(
            icon: Icons.shopping_bag_outlined,
            iconColor: YohPalBrandColors.gold,
            title: 'Shop',
            subtitle: 'Buy products featured in this video',
            onTap: () => _openWeb(context),
          ),
          YohPalHubCard(
            icon: Icons.calendar_today_outlined,
            iconColor: YohPalBrandColors.gold,
            title: 'Book',
            subtitle: 'Book a session, appointment or event',
            onTap: () => _openWeb(context),
          ),
          YohPalHubCard(
            icon: Icons.work_outline,
            iconColor: YohPalBrandColors.gold,
            title: 'Apply',
            subtitle: 'Apply for a job, course or opportunity',
            onTap: () => _openWeb(context),
          ),
          YohPalHubCard(
            icon: Icons.link_outlined,
            iconColor: YohPalBrandColors.gold,
            title: 'View Creator Links',
            subtitle: 'All links shared by this creator',
            onTap: () => _openWeb(context),
          ),
        ],
      ),
    );
  }

  void _openWeb(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sign in to continue on web.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    context.read<YohPalWebHandoff>().openWallet(userId: user.uid);
  }
}
