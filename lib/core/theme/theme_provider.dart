import 'package:finance_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Phase 49: Material 3 Theming Modes.
enum AppThemeType {
  /// Minimalist off-white theme (0xFFF8FAFC).
  light,

  /// Deep slate navy dark theme (0xFF0A0F1D / 0xFF151D30).
  deepDark,

  /// Pure pitch-black OLED theme (0xFF000000) for AMOLED battery conservation.
  oledBlack,
}

/// Global theme provider managing active theme state across all widgets.
class ThemeProvider extends ValueNotifier<AppThemeType> {
  ThemeProvider._() : super(AppThemeType.deepDark);

  /// Central singleton instance.
  static final ThemeProvider instance = ThemeProvider._();

  /// Gets current active theme type.
  AppThemeType get activeTheme => value;

  /// Returns true if current theme is either Deep Dark or Pure OLED.
  bool get isDark => value == AppThemeType.deepDark || value == AppThemeType.oledBlack;

  /// Returns true if current theme is Pure OLED.
  bool get isOled => value == AppThemeType.oledBlack;

  /// Returns true if current theme is Light Mode.
  bool get isLight => value == AppThemeType.light;

  /// Updates the active theme mode.
  void setTheme(AppThemeType themeType) {
    value = themeType;
  }

  /// Cycles sequentially through all three themes: Light -> Deep Dark -> Pure OLED -> Light.
  void cycleTheme() {
    switch (value) {
      case AppThemeType.light:
        value = AppThemeType.deepDark;
        break;
      case AppThemeType.deepDark:
        value = AppThemeType.oledBlack;
        break;
      case AppThemeType.oledBlack:
        value = AppThemeType.light;
        break;
    }
  }

  /// Toggles between Light and Deep Dark modes.
  void toggleLightDark() {
    value = isDark ? AppThemeType.light : AppThemeType.deepDark;
  }

  /// Returns the corresponding [ThemeData] for the current theme type.
  ThemeData get currentThemeData => AppTheme.getThemeData(value);
}
