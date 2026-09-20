import 'package:finance_app/app.dart';
import 'package:finance_app/core/constants/regex_patterns.dart';
import 'package:finance_app/core/theme/app_colors.dart';
import 'package:finance_app/core/theme/interactive_card.dart';
import 'package:finance_app/core/utils/currency_formatter.dart';
import 'package:finance_app/core/utils/debouncer.dart';
import 'package:finance_app/core/utils/security_hash.dart';
import 'package:finance_app/features/automation/sms_parser/bank_sms_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Theme Tokens & Colors', () {
    test('AppColors token values match requirement specs', () {
      expect(AppColors.darkSlateBackground, const Color(0xFF0A0F1D));
      expect(AppColors.surfaceCard, const Color(0xFF151D30));
      expect(AppColors.borderStroke, const Color(0xFF24304F));
      expect(AppColors.accentIndigo, const Color(0xFF6366F1));
    });
  });

  group('CurrencyFormatter Tests', () {
    test('Formats currency amounts correctly', () {
      expect(CurrencyFormatter.format(1250.50), '\$1,250.50');
      expect(CurrencyFormatter.format(1250.50, showSign: true), '+\$1,250.50');
      expect(CurrencyFormatter.format(-450.00), '-\$450.00');
    });

    test('Formats compact currency values', () {
      expect(CurrencyFormatter.formatCompact(1500000), '\$1.5M');
      expect(CurrencyFormatter.formatCompact(45000), '\$45K');
    });

    test('Parses strings to double', () {
      expect(CurrencyFormatter.parseAmount('\$1,250.75'), 1250.75);
      expect(CurrencyFormatter.parseAmount('-45.20'), -45.20);
    });
  });

  group('SecurityHash Tests', () {
    test('Generates deterministic SHA-256 digests', () {
      final String hash1 = SecurityHash.sha256Hash('test-data-payload');
      final String hash2 = SecurityHash.sha256Hash('test-data-payload');
      expect(hash1, equals(hash2));
      expect(hash1.length, 64);
    });

    test('Masks account numbers cleanly', () {
      expect(SecurityHash.maskAccount('123456789012'), '********9012');
      expect(SecurityHash.maskAccount('4321'), '4321');
    });
  });

  group('Debouncer Tests', () {
    test('Debounces multiple rapid calls into a single execution', () async {
      final Debouncer debouncer = Debouncer(duration: const Duration(milliseconds: 50));
      int callCount = 0;

      debouncer.run(() => callCount++);
      debouncer.run(() => callCount++);
      debouncer.run(() => callCount++);

      expect(callCount, 0);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(callCount, 1);
      debouncer.dispose();
    });
  });

  group('Bank SMS Parser & Regex Tests', () {
    test('Parses debit bank SMS message correctly', () {
      const BankSmsParser parser = BankSmsParser();
      const String sms =
          'Alert: Your A/c **4592 has been debited by USD 84.50 on 12-Sep towards Whole Foods. Ref: UTR998877';

      final parsed = parser.parse(sms);
      expect(parsed, isNotNull);
      expect(parsed!.amount, 84.50);
      expect(parsed.accountMasked, '**4592');
      expect(parsed.referenceNumber, 'UTR998877');
    });

    test('Regex detects credit amounts', () {
      const String sms = 'INR 50,000.00 credited to account XX1234 on 01-Oct';
      expect(RegexPatterns.creditKeywords.hasMatch(sms), isTrue);
      final RegExpMatch? amount = RegexPatterns.currencyAmount.firstMatch(sms);
      expect(amount, isNotNull);
      expect(amount!.group(1), '50,000.00');
    });
  });

  group('InteractiveCard Tests', () {
    testWidgets('InteractiveCard renders child and handles interactions', (WidgetTester tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveCard(
              onTap: () => tapped = true,
              child: const Text('Card Content'),
            ),
          ),
        ),
      );

      expect(find.text('Card Content'), findsOneWidget);
      final initialScaleWidget = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
      expect(initialScaleWidget.scale, 1.0);

      // Simulate tap
      await tester.tap(find.text('Card Content'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });
  });

  group('App Widget Smoke Test', () {
    testWidgets('FinanceApp renders SplashScreen initially', (WidgetTester tester) async {
      await tester.pumpWidget(const FinanceApp());
      expect(find.text('FINANCEX'), findsOneWidget);
      expect(find.text('Autonomous Wealth Management'), findsOneWidget);
      await tester.pumpAndSettle();
    });
  });
}
