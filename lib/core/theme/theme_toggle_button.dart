import 'package:flutter/material.dart';

/// Global notifier managing application theme mode across all screens.
/// Defaults to ThemeMode.light.
final ValueNotifier<ThemeMode> appThemeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

/// Production-grade Theme Toggle Button for AppBar actions and Settings screens.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({
    super.key,
    this.showTooltip = true,
  });

  final bool showTooltip;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeNotifier,
      builder: (BuildContext context, ThemeMode currentMode, _) {
        final bool isDark = currentMode == ThemeMode.dark ||
            (currentMode == ThemeMode.system &&
                MediaQuery.platformBrightnessOf(context) == Brightness.dark);

        final Widget iconButton = IconButton(
          key: const Key('theme_toggle_button'),
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return RotationTransition(
                turns: animation,
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              key: ValueKey<bool>(isDark),
              size: 22,
            ),
          ),
          onPressed: () {
            appThemeNotifier.value =
                isDark ? ThemeMode.light : ThemeMode.dark;
          },
        );

        if (!showTooltip) return iconButton;

        return Tooltip(
          message: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
          child: iconButton,
        );
      },
    );
  }
}
