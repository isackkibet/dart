import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../design_system/tokens/yohpal_brand_colors.dart';
import '../../../shared/widgets/yohpal_hub_card.dart';

class CreateHubScreen extends StatelessWidget {
  const CreateHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: const Text('Create'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          YohPalHubCard(
            icon: Icons.upload_rounded,
            iconColor: YohPalBrandColors.gold,
            title: 'Upload Video',
            subtitle: 'Record or upload a video to your feed',
            onTap: () => Navigator.pushNamed(context, AppRoutes.upload),
          ),
          YohPalHubCard(
            icon: Icons.live_tv_outlined,
            iconColor: YohPalBrandColors.gold,
            title: 'Go Live',
            subtitle: 'Start a live stream with your followers',
            onTap: () => Navigator.pushNamed(context, AppRoutes.goLive),
          ),
          YohPalHubCard(
            icon: Icons.auto_awesome,
            iconColor: YohPalBrandColors.gold,
            title: 'YCIOS Workspace',
            subtitle: 'AI Creator Intelligence OS — projects, tasks, render',
            onTap: () => Navigator.pushNamed(context, AppRoutes.ycios),
          ),
          YohPalHubCard(
            icon: Icons.settings_input_antenna,
            iconColor: YohPalBrandColors.gold,
            title: 'Multistream Setup',
            subtitle: 'Go live first, then configure multistream from controls',
            onTap: () => Navigator.pushNamed(context, AppRoutes.goLive),
          ),
          YohPalHubCard(
            icon: Icons.shopping_bag_outlined,
            iconColor: YohPalBrandColors.gold,
            title: 'Live Commerce Setup',
            subtitle: 'Pin products and offers during your live streams',
            onTap: () => Navigator.pushNamed(context, AppRoutes.goLive),
          ),
        ],
      ),
    );
  }
}
