import 'package:flutter/material.dart';

import '../tokens/yohpal_brand_colors.dart';

/// Standard bordered surface card. Use across every module instead of
/// module-specific `Card(color: ...)` overrides.
class YohPalBrandCard extends StatelessWidget {
  final Widget child;

  const YohPalBrandCard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? YohPalBrandColors.charcoal : YohPalBrandColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? YohPalBrandColors.borderDark
              : YohPalBrandColors.borderLight,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}
