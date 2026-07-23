import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../design_system/tokens/yohpal_brand_colors.dart';
import '../../../shared/widgets/yohpal_hub_card.dart';

class CommunityHubScreen extends StatelessWidget {
  const CommunityHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: const Text('Community'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          YohPalHubCard(
            icon: Icons.message_outlined,
            iconColor: YohPalBrandColors.gold,
            title: 'Messages',
            subtitle: 'Chat with creators and followers',
            onTap: () => Navigator.pushNamed(context, AppRoutes.messages),
          ),
          YohPalHubCard(
            icon: Icons.notifications_outlined,
            iconColor: YohPalBrandColors.gold,
            title: 'Notifications',
            subtitle: 'Engagement, live, chat and reward alerts',
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.notifications),
          ),
          YohPalHubCard(
            icon: Icons.people_alt_outlined,
            iconColor: YohPalBrandColors.gold,
            title: 'Collaboration',
            subtitle: 'Duet, react, remix and collaborate with creators',
            onTap: () => Navigator.pushNamed(
                context, AppRoutes.collaborationCreate),
          ),
          YohPalHubCard(
            icon: Icons.watch_later_outlined,
            iconColor: YohPalBrandColors.gold,
            title: 'Watch Later',
            subtitle: 'Videos you saved to watch later',
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.watchLater),
          ),
          YohPalHubCard(
            icon: Icons.person_add_outlined,
            iconColor: YohPalBrandColors.gold,
            title: 'Invite Friends',
            subtitle: 'Grow your network — invite contacts to YohPal',
            onTap: () => Navigator.pushNamed(context, AppRoutes.invite),
          ),
        ],
      ),
    );
  }
}
