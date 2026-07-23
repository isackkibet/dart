import 'package:flutter/material.dart';

import '../../design_system/tokens/yohpal_brand_colors.dart';

class YohPalHubCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;

  const YohPalHubCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = iconColor ?? YohPalBrandColors.gold;
    final onSurface = theme.colorScheme.onSurface;

    return Card(
      color: theme.cardColor,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: accent, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: onSurface.withValues(alpha: 0.6), fontSize: 12),
        ),
        trailing: Icon(Icons.chevron_right, color: onSurface.withValues(alpha: 0.4)),
        onTap: onTap,
      ),
    );
  }
}
