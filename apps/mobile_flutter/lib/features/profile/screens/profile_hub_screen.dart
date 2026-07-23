import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yohpal_live_v2/features/auth/controllers/auth_controller.dart';
import '../../../core/routes/app_routes.dart';
import '../../../design_system/tokens/yohpal_brand_colors.dart';
import '../../../shared/widgets/yohpal_hub_card.dart';
import '../../creator_profile/screens/creator_analytics_screen.dart';
import '../../settings/theme_settings_screen.dart';

class ProfileHubScreen extends StatelessWidget {
  const ProfileHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? '';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: theme.scaffoldBackgroundColor,
            expandedHeight: 140,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                user?.displayName ?? user?.email ?? 'My Profile',
                style: TextStyle(fontSize: 16, color: onSurface),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.surface,
                      theme.scaffoldBackgroundColor,
                    ],
                  ),
                ),
                child: Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: YohPalBrandColors.gold,
                    backgroundImage: user?.photoURL != null
                        ? NetworkImage(user!.photoURL!)
                        : null,
                    child: user?.photoURL == null
                        ? Text(
                            (user?.displayName?.isNotEmpty == true
                                    ? user!.displayName![0]
                                    : '?')
                                .toUpperCase(),
                            style: const TextStyle(
                                fontSize: 32, color: YohPalBrandColors.black),
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ),
          if (user == null)
            SliverFillRemaining(
              child: Center(
                child: Text('Sign in to view your profile.',
                    style: TextStyle(color: onSurface.withValues(alpha: 0.7))),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _section('Creator', onSurface.withValues(alpha: 0.5)),
                  YohPalHubCard(
                    icon: Icons.person_outlined,
                    iconColor: YohPalBrandColors.gold,
                    title: 'My Creator Profile',
                    subtitle: 'View and edit your public creator page',
                    onTap: () => Navigator.pushNamed(
                        context, '/creator-profile',
                        arguments: uid),
                  ),
                  YohPalHubCard(
                    icon: Icons.auto_awesome,
                    iconColor: YohPalBrandColors.gold,
                    title: 'YCIOS Workspace',
                    subtitle: 'AI projects, tasks and render queue',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.ycios),
                  ),
                  YohPalHubCard(
                    icon: Icons.bar_chart,
                    iconColor: YohPalBrandColors.gold,
                    title: 'Analytics',
                    subtitle: 'Views, engagement and growth metrics',
                    onTap: () => Navigator.pushNamed(
                        context, CreatorAnalyticsScreen.routeName,
                        arguments: uid),
                  ),
                  YohPalHubCard(
                    icon: Icons.monetization_on_outlined,
                    iconColor: YohPalBrandColors.gold,
                    title: 'Earnings',
                    subtitle: 'Ads, gifts, affiliate and commerce earnings',
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.creatorEarnings),
                  ),
                  YohPalHubCard(
                    icon: Icons.handshake_outlined,
                    iconColor: YohPalBrandColors.gold,
                    title: 'Affiliate Dashboard',
                    subtitle: 'Referral links, commissions and payouts',
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.affiliate),
                  ),
                  const SizedBox(height: 8),
                  _section('Business', onSurface.withValues(alpha: 0.5)),
                  YohPalHubCard(
                    icon: Icons.campaign_outlined,
                    iconColor: YohPalBrandColors.gold,
                    title: 'Advertiser Dashboard',
                    subtitle: 'Manage ad campaigns and budgets',
                    onTap: () =>
                        Navigator.pushNamed(context, '/advertiser-dashboard'),
                  ),
                  YohPalHubCard(
                    icon: Icons.storefront_outlined,
                    iconColor: YohPalBrandColors.gold,
                    title: 'Creator Marketplace',
                    subtitle: 'Brand deals, sponsorships and collaborations',
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Marketplace — launching soon.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _section('Account', onSurface.withValues(alpha: 0.5)),
                  YohPalHubCard(
                    icon: Icons.person_add_outlined,
                    iconColor: YohPalBrandColors.gold,
                    title: 'Invite Friends',
                    subtitle: 'Grow your network — invite your contacts',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.invite),
                  ),
                  YohPalHubCard(
                    icon: Icons.palette_outlined,
                    iconColor: YohPalBrandColors.gold,
                    title: 'Theme',
                    subtitle: 'Day mode, Night mode or System default',
                    onTap: () => Navigator.pushNamed(
                        context, ThemeSettingsScreen.routeName),
                  ),
                  YohPalHubCard(
                    icon: Icons.settings_outlined,
                    iconColor: YohPalBrandColors.gold.withValues(alpha: 0.6),
                    title: 'Settings',
                    subtitle: 'Account, privacy and notification settings',
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Settings — coming soon.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    ),
                  ),
                  YohPalHubCard(
                    icon: Icons.logout,
                    iconColor: Colors.redAccent,
                    title: 'Sign Out',
                    subtitle: 'Sign out of your YohPal account',
                    onTap: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Sign out?'),
                          content: const Text(
                              'You will need to sign in again to access your account.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Sign out'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed != true || !context.mounted) return;
                      await context.read<AuthController>().logout();
                    },
                  ),
                  const SizedBox(height: 32),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _section(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2),
      ),
    );
  }
}
