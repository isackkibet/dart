import 'package:flutter/material.dart';
import '../../../design_system/tokens/yohpal_brand_colors.dart';
import '../../../shared/widgets/yohpal_hub_card.dart';

class CollaborationScreen extends StatelessWidget {
  const CollaborationScreen({super.key});

  static const routeName = '/collaboration-create';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = theme.scaffoldBackgroundColor;
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: const Text('Collaborate'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text(
              'Create together with other YohPal creators.',
              style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 14),
            ),
          ),
          YohPalHubCard(
            icon: Icons.people_alt_outlined,
            iconColor: YohPalBrandColors.gold,
            title: 'Duet',
            subtitle: 'Record a side-by-side video with any creator',
            onTap: () => _showComingSoon(context, 'Duet'),
          ),
          YohPalHubCard(
            icon: Icons.replay_outlined,
            iconColor: YohPalBrandColors.gold,
            title: 'React',
            subtitle: 'Film your reaction to a video, side by side',
            onTap: () => _showComingSoon(context, 'React'),
          ),
          YohPalHubCard(
            icon: Icons.music_note_outlined,
            iconColor: YohPalBrandColors.gold,
            title: 'Remix',
            subtitle: 'Remix audio, effects or scenes from another video',
            onTap: () => _showComingSoon(context, 'Remix'),
          ),
          YohPalHubCard(
            icon: Icons.link_outlined,
            iconColor: YohPalBrandColors.gold,
            title: 'Collab Invite',
            subtitle: 'Invite a creator to collaborate on a project',
            onTap: () => _showComingSoon(context, 'Collab Invite'),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature — launching soon.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
