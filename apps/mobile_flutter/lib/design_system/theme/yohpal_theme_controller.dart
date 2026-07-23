import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's Day/Night/System theme choice across app launches.
class YohPalThemeController extends ChangeNotifier {
  static const _prefsKey = 'yohpal_theme_mode';

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  YohPalThemeController() {
    _restore();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefsKey);
    if (stored != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (m) => m.name == stored,
        orElse: () => ThemeMode.system,
      );
      notifyListeners();
    }
  }

  void setSystem() => _setMode(ThemeMode.system);
  void setDay() => _setMode(ThemeMode.light);
  void setNight() => _setMode(ThemeMode.dark);

  void _setMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    SharedPreferences.getInstance()
        .then((prefs) => prefs.setString(_prefsKey, mode.name));
  }
}
