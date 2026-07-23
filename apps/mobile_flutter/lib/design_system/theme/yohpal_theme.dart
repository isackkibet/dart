import 'package:flutter/material.dart';

import '../tokens/yohpal_brand_colors.dart';

/// YohPal's global brand theme: Day (ivory/black/gold) and Night
/// (black/charcoal/gold) modes. Every module — Live, Hustle, YCIOS, Wallet,
/// Rewards, Chat, Creator Profile, Marketplace, Ads Arena — inherits this
/// theme rather than defining its own colors.
class YohPalTheme {
  YohPalTheme._();

  static ThemeData day() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: YohPalBrandColors.ivory,
      primaryColor: YohPalBrandColors.gold,
      colorScheme: const ColorScheme.light(
        primary: YohPalBrandColors.gold,
        secondary: YohPalBrandColors.deepGold,
        surface: YohPalBrandColors.white,
        onPrimary: YohPalBrandColors.black,
        onSurface: YohPalBrandColors.textDark,
      ),
      cardColor: YohPalBrandColors.white,
      dividerColor: YohPalBrandColors.softGray,
      appBarTheme: const AppBarTheme(
        backgroundColor: YohPalBrandColors.ivory,
        foregroundColor: YohPalBrandColors.black,
        elevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: YohPalBrandColors.white,
        selectedItemColor: YohPalBrandColors.gold,
        unselectedItemColor: YohPalBrandColors.textDark,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: YohPalBrandColors.white,
        indicatorColor: YohPalBrandColors.gold.withValues(alpha: 0.25),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected
                ? YohPalBrandColors.deepGold
                : YohPalBrandColors.textDark,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected
                ? YohPalBrandColors.deepGold
                : YohPalBrandColors.textDark,
            fontSize: 12,
          );
        }),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: YohPalBrandColors.gold,
        foregroundColor: YohPalBrandColors.black,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: YohPalBrandColors.gold,
          foregroundColor: YohPalBrandColors.black,
        ),
      ),
      textTheme: ThemeData.light().textTheme.apply(
            bodyColor: YohPalBrandColors.textDark,
            displayColor: YohPalBrandColors.textDark,
          ),
    );
  }

  static ThemeData night() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: YohPalBrandColors.black,
      primaryColor: YohPalBrandColors.gold,
      colorScheme: const ColorScheme.dark(
        primary: YohPalBrandColors.gold,
        secondary: YohPalBrandColors.deepGold,
        surface: YohPalBrandColors.charcoal,
        onPrimary: YohPalBrandColors.black,
        onSurface: YohPalBrandColors.textLight,
      ),
      cardColor: YohPalBrandColors.charcoal,
      dividerColor: const Color(0xFF2A2A2A),
      appBarTheme: const AppBarTheme(
        backgroundColor: YohPalBrandColors.black,
        foregroundColor: YohPalBrandColors.white,
        elevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: YohPalBrandColors.charcoal,
        selectedItemColor: YohPalBrandColors.gold,
        unselectedItemColor: YohPalBrandColors.textLight,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: YohPalBrandColors.charcoal,
        indicatorColor: YohPalBrandColors.gold.withValues(alpha: 0.25),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected
                ? YohPalBrandColors.gold
                : YohPalBrandColors.textLight,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected
                ? YohPalBrandColors.gold
                : YohPalBrandColors.textLight,
            fontSize: 12,
          );
        }),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: YohPalBrandColors.gold,
        foregroundColor: YohPalBrandColors.black,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: YohPalBrandColors.gold,
          foregroundColor: YohPalBrandColors.black,
        ),
      ),
      textTheme: ThemeData.dark().textTheme.apply(
            bodyColor: YohPalBrandColors.textLight,
            displayColor: YohPalBrandColors.textLight,
          ),
    );
  }
}
