import 'package:finance_app/core/theme/app_colors.dart';
import 'package:finance_app/core/theme/app_theme.dart';
import 'package:finance_app/core/theme/theme_provider.dart';
import 'package:finance_app/core/theme/theme_toggle_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 49: Material 3 Theming System (Dark / Light / OLED) Tests', () {
    setUp(() {
      ThemeProvider.instance.setTheme(AppThemeType.deepDark);
    });

    test('1. Light Theme: Configured with minimalist off-white palette (0xFFF8FAFC)', () {
      final ThemeData lightTheme = AppTheme.lightTheme;
      expect(lightTheme.useMaterial3, isTrue);
      expect(lightTheme.brightness, Brightness.light);
      expect(lightTheme.scaffoldBackgroundColor, AppColors.lightBackground);
      expect(lightTheme.scaffoldBackgroundColor, const Color(0xFFF8FAFC));
      expect(lightTheme.cardTheme.color, AppColors.lightCard);
    });

    test('2. Deep Dark Theme: Configured with slate navy palette (0xFF0A0F1D / 0xFF151D30)', () {
      final ThemeData darkTheme = AppTheme.deepDarkTheme;
      expect(darkTheme.useMaterial3, isTrue);
      expect(darkTheme.brightness, Brightness.dark);
      expect(darkTheme.scaffoldBackgroundColor, AppColors.darkSlateBackground);
      expect(darkTheme.scaffoldBackgroundColor, const Color(0xFF0A0F1D));
      expect(darkTheme.colorScheme.surface, AppColors.surfaceCard);
    });

    test('3. Pure OLED Theme: Configured with pitch black palette (0xFF000000) for AMOLED battery conservation', () {
      final ThemeData oledTheme = AppTheme.oledTheme;
      expect(oledTheme.useMaterial3, isTrue);
      expect(oledTheme.brightness, Brightness.dark);
      expect(oledTheme.scaffoldBackgroundColor, AppColors.oledBackground);
      expect(oledTheme.scaffoldBackgroundColor, const Color(0xFF000000));
      expect(oledTheme.colorScheme.surface, AppColors.oledCard);
      expect(oledTheme.colorScheme.surface, const Color(0xFF0D0D0D));
    });

    test('4. ThemeProvider State Management: Switches modes and resolves ThemeData correctly', () {
      ThemeProvider.instance.setTheme(AppThemeType.light);
      expect(ThemeProvider.instance.isLight, isTrue);
      expect(ThemeProvider.instance.isDark, isFalse);
      expect(ThemeProvider.instance.isOled, isFalse);
      expect(ThemeProvider.instance.currentThemeData.brightness, Brightness.light);

      ThemeProvider.instance.setTheme(AppThemeType.oledBlack);
      expect(ThemeProvider.instance.isOled, isTrue);
      expect(ThemeProvider.instance.isDark, isTrue);
      expect(ThemeProvider.instance.isLight, isFalse);
      expect(ThemeProvider.instance.currentThemeData.scaffoldBackgroundColor, const Color(0xFF000000));

      ThemeProvider.instance.setTheme(AppThemeType.deepDark);
      expect(ThemeProvider.instance.activeTheme, AppThemeType.deepDark);
      expect(ThemeProvider.instance.currentThemeData.scaffoldBackgroundColor, const Color(0xFF0A0F1D));
    });

    test('5. ThemeProvider 3-Way Cycle: Light -> Deep Dark -> Pure OLED -> Light', () {
      ThemeProvider.instance.setTheme(AppThemeType.light);

      ThemeProvider.instance.cycleTheme();
      expect(ThemeProvider.instance.activeTheme, AppThemeType.deepDark);

      ThemeProvider.instance.cycleTheme();
      expect(ThemeProvider.instance.activeTheme, AppThemeType.oledBlack);

      ThemeProvider.instance.cycleTheme();
      expect(ThemeProvider.instance.activeTheme, AppThemeType.light);
    });

    testWidgets('6. ThemeToggleButton Widget cycles through 3 theme states on tap', (tester) async {
      ThemeProvider.instance.setTheme(AppThemeType.light);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(56),
              child: ThemeToggleButton(),
            ),
          ),
        ),
      );

      expect(find.byType(ThemeToggleButton), findsOneWidget);

      // Tap 1: Light -> Deep Dark
      await tester.tap(find.byKey(const Key('theme_toggle_button')));
      await tester.pumpAndSettle();
      expect(ThemeProvider.instance.activeTheme, AppThemeType.deepDark);

      // Tap 2: Deep Dark -> Pure OLED
      await tester.tap(find.byKey(const Key('theme_toggle_button')));
      await tester.pumpAndSettle();
      expect(ThemeProvider.instance.activeTheme, AppThemeType.oledBlack);

      // Tap 3: Pure OLED -> Light
      await tester.tap(find.byKey(const Key('theme_toggle_button')));
      await tester.pumpAndSettle();
      expect(ThemeProvider.instance.activeTheme, AppThemeType.light);
    });
  });
}
