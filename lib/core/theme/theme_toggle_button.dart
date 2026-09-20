import 'package:finance_app/core/theme/theme_provider.dart';
import 'package:flutter/material.dart';

/// Backward-compatible global notifier managing application theme mode across legacy screens.
final ValueNotifier<ThemeMode> appThemeNotifier = ValueNotifier<ThemeMode>(ThemeMode.dark);

/// Production-grade Theme Toggle Button for AppBar actions and Settings screens.
/// Supports 3-state cycling: Light Mode -> Deep Slate Dark -> Pure AMOLED OLED.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({
    super.key,
    this.showTooltip = true,
  });

  final bool showTooltip;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeType>(
      valueListenable: ThemeProvider.instance,
      builder: (BuildContext context, AppThemeType activeTheme, _) {
        final IconData icon;
        final String tooltipMessage;

        switch (activeTheme) {
          case AppThemeType.light:
            icon = Icons.light_mode_rounded;
            tooltipMessage = 'Active: Light Mode (Tap for Deep Dark)';
            break;
          case AppThemeType.deepDark:
            icon = Icons.dark_mode_rounded;
            tooltipMessage = 'Active: Deep Dark (Tap for Pure OLED)';
            break;
          case AppThemeType.oledBlack:
            icon = Icons.brightness_2_rounded;
            tooltipMessage = 'Active: Pure OLED Black (Tap for Light)';
            break;
        }

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
              icon,
              key: ValueKey<AppThemeType>(activeTheme),
              size: 22,
            ),
          ),
          onPressed: () {
            ThemeProvider.instance.cycleTheme();
            appThemeNotifier.value = ThemeProvider.instance.isDark ? ThemeMode.dark : ThemeMode.light;
          },
        );

        if (!showTooltip) return iconButton;

        return Tooltip(
          message: tooltipMessage,
          child: iconButton,
        );
      },
    );
  }
}
