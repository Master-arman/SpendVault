import 'package:finance_app/core/theme/app_theme.dart';
import 'package:finance_app/features/subscriptions/data/models/subscription.dart';
import 'package:finance_app/features/subscriptions/presentation/screens/add_subscription_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 32: Subscription Lifecycle Form & Annual Cost Calculator Tests', () {
    testWidgets('Dynamic Metric Display live updates to Annual commitment: ₹7,788.00/year for ₹649/month',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const AddSubscriptionScreen(
            initialAmount: 649.0,
            initialCycle: BillingCycle.monthly,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Dynamic metric should show exactly ₹7,788.00/year for ₹649/month
      expect(
        find.text('Annual commitment: ₹7,788.00/year'),
        findsOneWidget,
      );
    });

    testWidgets('Dynamic Metric Display updates in real time when amount is edited',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const AddSubscriptionScreen(
            initialAmount: 649.0,
            initialCycle: BillingCycle.monthly,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Annual commitment: ₹7,788.00/year'), findsOneWidget);

      // Enter 199 in amount field
      final amountField = find.byKey(const Key('subscription_amount_input'));
      await tester.enterText(amountField, '199');
      await tester.pump();

      // 199 * 12 = 2388.00
      expect(find.text('Annual commitment: ₹2,388.00/year'), findsOneWidget);
    });

    testWidgets('Dynamic Metric Display updates in real time when billing cycle changes',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const AddSubscriptionScreen(
            initialAmount: 100.0,
            initialCycle: BillingCycle.monthly,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Monthly: 100 * 12 = 1200
      expect(find.text('Annual commitment: ₹1,200.00/year'), findsOneWidget);

      // Tap Weekly: 100 * 52 = 5200
      await tester.tap(find.byKey(const Key('cycle_option_weekly')));
      await tester.pumpAndSettle();
      expect(find.text('Annual commitment: ₹5,200.00/year'), findsOneWidget);

      // Tap Quarterly: 100 * 4 = 400
      await tester.tap(find.byKey(const Key('cycle_option_quarterly')));
      await tester.pumpAndSettle();
      expect(find.text('Annual commitment: ₹400.00/year'), findsOneWidget);

      // Tap Yearly: 100 * 1 = 100
      await tester.tap(find.byKey(const Key('cycle_option_yearly')));
      await tester.pumpAndSettle();
      expect(find.text('Annual commitment: ₹100.00/year'), findsOneWidget);
    });

    testWidgets('Tapping popular preset autofills name, amount, cycle, and calculates annual commitment',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const AddSubscriptionScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Spotify preset (199 / month)
      final spotifyPresetFinder = find.byKey(const Key('preset_Spotify'));
      expect(spotifyPresetFinder, findsOneWidget);

      await tester.tap(spotifyPresetFinder);
      await tester.pumpAndSettle();

      final nameField = tester.widget<TextFormField>(find.byKey(const Key('subscription_name_input')));
      expect(nameField.controller?.text, 'Spotify');

      final amountField = tester.widget<TextFormField>(find.byKey(const Key('subscription_amount_input')));
      expect(amountField.controller?.text, '199');

      expect(find.text('Annual commitment: ₹2,388.00/year'), findsOneWidget);

      // Tap Amazon Prime preset (1499 / year)
      final primePresetFinder = find.byKey(const Key('preset_Amazon Prime'));
      expect(primePresetFinder, findsOneWidget);

      await tester.tap(primePresetFinder);
      await tester.pumpAndSettle();

      expect(nameField.controller?.text, 'Amazon Prime');
      expect(amountField.controller?.text, '1499');
      expect(find.text('Annual commitment: ₹1,499.00/year'), findsOneWidget);
    });

    testWidgets('Form validation and submission with onSave callback',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      Subscription? savedSubscription;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: AddSubscriptionScreen(
            onSave: (sub) async {
              savedSubscription = sub;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Attempt to save with empty name
      final saveButton = find.byKey(const Key('save_subscription_button'));
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(find.text('Please enter a subscription name'), findsOneWidget);
      expect(savedSubscription, isNull);

      // Enter name
      await tester.enterText(find.byKey(const Key('subscription_name_input')), 'Netflix 4K');
      await tester.enterText(find.byKey(const Key('subscription_amount_input')), '649');
      await tester.tap(find.byKey(const Key('reminder_days_5')));
      await tester.pumpAndSettle();

      // Submit form
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(savedSubscription, isNotNull);
      expect(savedSubscription?.name, 'Netflix 4K');
      expect(savedSubscription?.amount, 649.0);
      expect(savedSubscription?.cycle, BillingCycle.monthly);
      expect(savedSubscription?.reminderDaysBefore, 5);
      expect(savedSubscription?.isActive, isTrue);
    });
  });
}
