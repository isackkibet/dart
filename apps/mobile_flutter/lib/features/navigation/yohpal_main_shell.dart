import 'package:flutter/material.dart';
import '../../design_system/tokens/yohpal_brand_colors.dart';
import '../discover/screens/discover_hub_screen.dart';
import '../create/screens/create_hub_screen.dart';
import '../community/screens/community_hub_screen.dart';
import '../rewards/screens/rewards_hub_screen.dart';
import '../profile/screens/profile_hub_screen.dart';

class YohPalMainShell extends StatefulWidget {
  const YohPalMainShell({super.key});

  @override
  State<YohPalMainShell> createState() => _YohPalMainShellState();
}

class _YohPalMainShellState extends State<YohPalMainShell> {
  int _index = 0;

  static const _pages = [
    DiscoverHubScreen(),
    CreateHubScreen(),
    CommunityHubScreen(),
    RewardsHubScreen(),
    ProfileHubScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        indicatorColor: YohPalBrandColors.gold.withValues(alpha: 0.25),
        selectedIndex: _index,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Create',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Community',
          ),
          NavigationDestination(
            icon: Icon(Icons.card_giftcard_outlined),
            selectedIcon: Icon(Icons.card_giftcard),
            label: 'Rewards',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
