import 'package:flutter/material.dart';

/// Single source of truth for YohPal brand colors.
/// Every module (Live, Hustle, YCIOS, Wallet, Rewards, Chat, etc.) must
/// pull colors from here via [YohPalTheme] — no per-module color systems.
class YohPalBrandColors {
  YohPalBrandColors._();

  static const gold = Color(0xFFD4AF37);
  static const deepGold = Color(0xFFB8860B);
  static const black = Color(0xFF050505);
  static const charcoal = Color(0xFF111111);
  static const ivory = Color(0xFFFFFBF0);
  static const white = Color(0xFFFFFFFF);
  static const softGray = Color(0xFFF4F4F4);
  static const borderLight = Color(0xFFE8E0CC);
  static const borderDark = Color(0xFF2A2416);
  static const textDark = Color(0xFF111111);
  static const textLight = Color(0xFFFFFFFF);
}
