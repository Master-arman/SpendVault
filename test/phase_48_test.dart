import 'package:finance_app/core/utils/currency_formatter.dart';
import 'package:finance_app/core/utils/currency_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 48: Multi-Currency & Numbering Localizer Tests', () {
    setUp(() {
      // Reset CurrencyManager to default INR / Indian scheme before each test
      CurrencyManager.instance.setCurrency(CurrencyItem.inr, scheme: NumberingScheme.indian);
      CurrencyManager.instance.setDecimalDigits(2);
    });

    test('1. Indian Numbering Scheme: Formats amounts with 3-then-2 digit grouping (12,34,567.00)', () {
      CurrencyManager.instance.setNumberingScheme(NumberingScheme.indian);

      expect(CurrencyManager.instance.format(1234567.00), '₹12,34,567.00');
      expect(CurrencyManager.instance.format(50000.50), '₹50,000.50');
      expect(CurrencyManager.instance.format(10000000.00), '₹1,00,00,000.00');
      expect(CurrencyManager.instance.format(999.00), '₹999.00');
    });

    test('2. Western Standard Numbering Scheme: Formats amounts with 3-digit grouping (1,234,567.00)', () {
      CurrencyManager.instance.setNumberingScheme(NumberingScheme.western);

      expect(CurrencyManager.instance.format(1234567.00), '₹1,234,567.00');
      expect(CurrencyManager.instance.format(50000.50), '₹50,000.50');
      expect(CurrencyManager.instance.format(10000000.00), '₹10,000,000.00');
    });

    test('3. Multi-Currency Switching: Dynamically updates active currency symbols and default schemes', () {
      // US Dollar
      CurrencyManager.instance.setCurrency(CurrencyItem.usd);
      expect(CurrencyManager.instance.activeSymbol, r'$');
      expect(CurrencyManager.instance.activeScheme, NumberingScheme.western);
      expect(CurrencyManager.instance.format(1234567.89), r'$1,234,567.89');

      // Euro
      CurrencyManager.instance.setCurrency(CurrencyItem.eur);
      expect(CurrencyManager.instance.activeSymbol, '€');
      expect(CurrencyManager.instance.format(9450.25), '€9,450.25');

      // British Pound
      CurrencyManager.instance.setCurrency(CurrencyItem.gbp);
      expect(CurrencyManager.instance.activeSymbol, '£');
      expect(CurrencyManager.instance.format(7500.00), '£7,500.00');

      // Japanese Yen (0 decimal digits)
      CurrencyManager.instance.setCurrency(CurrencyItem.jpy);
      expect(CurrencyManager.instance.activeSymbol, '¥');
      expect(CurrencyManager.instance.format(150000.0), '¥150,000');
    });

    test('4. CurrencyFormatter backwards compatibility and delegation', () {
      CurrencyManager.instance.setCurrency(CurrencyItem.inr, scheme: NumberingScheme.indian);
      expect(CurrencyFormatter.format(1234567.00), '₹12,34,567.00');
      expect(CurrencyFormatter.format(1234567.00, showSign: true), '+₹12,34,567.00');
      expect(CurrencyFormatter.format(-1234567.00), '-₹12,34,567.00');

      // Overriding custom symbol
      expect(CurrencyFormatter.format(5000.0, currencySymbol: r'$'), r'$5,000.00');
    });

    test('5. Compact Indian Formatting (Lakhs & Crores)', () {
      CurrencyManager.instance.setCurrency(CurrencyItem.inr, scheme: NumberingScheme.indian);

      expect(CurrencyManager.instance.formatCompact(45000000), '₹4.5Cr');
      expect(CurrencyManager.instance.formatCompact(1200000), '₹12L');
      expect(CurrencyManager.instance.formatCompact(85000), '₹85K');
      expect(CurrencyManager.instance.formatCompact(-150000), '-₹1.5L');
    });

    test('6. Compact Western Formatting (Millions & Billions)', () {
      CurrencyManager.instance.setCurrency(CurrencyItem.usd, scheme: NumberingScheme.western);

      expect(CurrencyManager.instance.formatCompact(45000000), r'$45M');
      expect(CurrencyManager.instance.formatCompact(1200000), r'$1.2M');
      expect(CurrencyManager.instance.formatCompact(85000), r'$85K');
    });

    test('7. Safe Amount Parsing from Strings', () {
      expect(CurrencyManager.parseAmount('₹12,34,567.50'), 1234567.50);
      expect(CurrencyManager.parseAmount(r'$ 1,234.00'), 1234.00);
      expect(CurrencyManager.parseAmount('-€99.99'), -99.99);
      expect(CurrencyManager.parseAmount('   '), isNull);
    });

    testWidgets('8. Reactive Prefix Widget dynamically updates with currency changes', (tester) async {
      CurrencyManager.instance.setCurrency(CurrencyItem.inr);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrencyManager.instance.buildPrefixWidget(),
          ),
        ),
      );

      expect(find.text('₹'), findsOneWidget);

      CurrencyManager.instance.setCurrency(CurrencyItem.usd);
      await tester.pumpAndSettle();

      expect(find.text(r'$'), findsOneWidget);

      CurrencyManager.instance.setCurrency(CurrencyItem.eur);
      await tester.pumpAndSettle();

      expect(find.text('€'), findsOneWidget);
    });
  });
}
