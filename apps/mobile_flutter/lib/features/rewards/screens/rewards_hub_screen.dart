import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../design_system/tokens/yohpal_brand_colors.dart';
import '../../../shared/widgets/yohpal_hub_card.dart';

class RewardsHubScreen extends StatelessWidget {
  const RewardsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = theme.scaffoldBackgroundColor;
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: const Text('Rewards'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'All money movement is handled securely via YohPal Web.',
              style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  fontSize: 12),
            ),
          ),
          YohPalHubCard(
            icon: Icons.account_balance_wallet_outlined,
            iconColor: YohPalBrandColors.gold,
            title: 'Wallet',
            subtitle: 'YohPoints balance, transaction history',
            onTap: () => Navigator.pushNamed(context, AppRoutes.wallet),
          ),
          YohPalHubCard(
            icon: Icons.monetization_on_outlined,
            iconColor: YohPalBrandColors.gold,
            title: 'Creator Earnings',
            subtitle: 'Ads, gifts, affiliate and commerce earnings',
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.creatorEarnings),
          ),
          YohPalHubCard(
            icon: Icons.confirmation_number_outlined,
            iconColor: YohPalBrandColors.gold,
            title: 'Coupon Wallet',
            subtitle: 'Smart coupons earned from rewarded ads',
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.couponWallet),
          ),
          YohPalHubCard(
            icon: Icons.play_circle_outline,
            iconColor: YohPalBrandColors.gold,
            title: 'Ads Arena',
            subtitle: 'Watch ads, earn YohPoints and unlock coupons',
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.adsArena),
          ),
          YohPalHubCard(
            icon: Icons.leaderboard_outlined,
            iconColor: YohPalBrandColors.gold,
            title: 'Leaderboards',
            subtitle: 'Top viewers, creators and coupon savers',
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.adsLeaderboard),
          ),
          YohPalHubCard(
            icon: Icons.card_giftcard_outlined,
            iconColor: YohPalBrandColors.gold,
            title: 'Gift History',
            subtitle: 'Gifts you have sent and received',
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Gift history — launching soon.'),
                behavior: SnackBarBehavior.floating,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
