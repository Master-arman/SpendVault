import 'package:finance_app/core/theme/app_theme.dart';
import 'package:finance_app/features/automation/presentation/widgets/incoming_transaction_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 27: Foreground Instant Confirmation Card Tests', () {
    testWidgets('renders detection text, actions, and category correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: IncomingTransactionBanner(
              amount: 35.0,
              merchant: 'Sharma Tea Stall',
              category: 'Food & Dining',
              currencySymbol: '₹',
            ),
          ),
        ),
      );

      await tester.pump();

      // Check detected text
      expect(
        find.text('Detected ₹35 spent at Sharma Tea Stall. Category: Food & Dining.'),
        findsOneWidget,
      );

      // Check buttons
      expect(find.text('Confirm'), findsOneWidget);
      expect(find.text('Change Category'), findsOneWidget);
      expect(find.byTooltip('Dismiss'), findsOneWidget);
      expect(find.text('Instant Transaction Alert'), findsOneWidget);
      expect(find.text('Auto-saving in 10s'), findsOneWidget);
    });

    testWidgets('tapping Confirm triggers onConfirm callback', (WidgetTester tester) async {
      bool confirmed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: IncomingTransactionBanner(
              amount: 150.0,
              merchant: 'Starbucks',
              category: 'Food & Dining',
              onConfirm: () => confirmed = true,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.tap(find.text('Confirm'));
      await tester.pump();

      expect(confirmed, isTrue);
    });

    testWidgets('tapping Change Category triggers onChangeCategory callback',
        (WidgetTester tester) async {
      bool categoryChangeTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: IncomingTransactionBanner(
              amount: 450.0,
              merchant: 'Uber',
              category: 'Transportation',
              onChangeCategory: () => categoryChangeTriggered = true,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.tap(find.text('Change Category'));
      await tester.pump();

      expect(categoryChangeTriggered, isTrue);
    });

    testWidgets('tapping Dismiss triggers onDismiss callback', (WidgetTester tester) async {
      bool dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: IncomingTransactionBanner(
              amount: 50.0,
              merchant: 'Chai Stall',
              category: 'Food & Dining',
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.tap(find.byTooltip('Dismiss'));
      await tester.pump();

      expect(dismissed, isTrue);
    });

    testWidgets('auto-confirms after 10 seconds if no action is taken',
        (WidgetTester tester) async {
      bool autoConfirmed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: IncomingTransactionBanner(
              amount: 35.0,
              merchant: 'Sharma Tea Stall',
              category: 'Food & Dining',
              autoConfirmDuration: const Duration(seconds: 10),
              onConfirm: () => autoConfirmed = true,
            ),
          ),
        ),
      );

      await tester.pump();
      expect(autoConfirmed, isFalse);

      // Advance clock by 10 seconds
      await tester.pump(const Duration(seconds: 10));
      await tester.pump();

      expect(autoConfirmed, isTrue);
    });
  });
}
