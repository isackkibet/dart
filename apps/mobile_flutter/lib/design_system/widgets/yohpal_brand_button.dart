import 'package:flutter/material.dart';

import '../tokens/yohpal_brand_colors.dart';

/// Standard gold/black primary action button. Use across every module
/// instead of module-specific `ElevatedButton.styleFrom` colors.
class YohPalBrandButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const YohPalBrandButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: YohPalBrandColors.gold,
        foregroundColor: YohPalBrandColors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}
