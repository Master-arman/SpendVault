import 'package:finance_app/core/theme/app_theme.dart';
import 'package:finance_app/features/subscriptions/presentation/screens/subscriptions_screen.dart';
import 'package:finance_app/features/subscriptions/presentation/widgets/renewal_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 33: Renewal Calendar Visual Matrix Tests', () {
    testWidgets('RenewalCalendar renders month header, weekday labels, and category dots on renewal dates',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final focusedDate = DateTime(2026, 10, 1);
      final items = [
        RenewalSubscriptionItem(
          id: 'sub-1',
          name: 'Netflix Premium',
          amount: 649.0,
          nextBillingDate: DateTime(2026, 10, 15),
          categoryName: 'Entertainment',
          cycleName: 'Monthly',
        ),
        RenewalSubscriptionItem(
          id: 'sub-2',
          name: 'Spotify Family',
          amount: 199.0,
          nextBillingDate: DateTime(2026, 10, 15),
          categoryName: 'Entertainment',
          cycleName: 'Monthly',
        ),
        RenewalSubscriptionItem(
          id: 'sub-3',
          name: 'iCloud+ Storage',
          amount: 219.0,
          nextBillingDate: DateTime(2026, 10, 25),
          categoryName: 'Bills & Utilities',
          cycleName: 'Monthly',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: RenewalCalendar(
                items: items,
                initialFocusedDate: focusedDate,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check Month & Year Header
      expect(find.text('October 2026'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);

      // Check Weekday Labels
      for (final day in ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']) {
        expect(find.text(day), findsOneWidget);
      }

      // Check Days grid numbers
      expect(find.text('15'), findsOneWidget);
      expect(find.text('25'), findsOneWidget);
      expect(find.byKey(const Key('calendar_day_15')), findsOneWidget);
      expect(find.byKey(const Key('calendar_day_25')), findsOneWidget);
    });

    testWidgets('Tapping a renewal date opens bottom modal with charging services and total sum',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final focusedDate = DateTime(2026, 10, 1);
      final items = [
        RenewalSubscriptionItem(
          id: 'sub-1',
          name: 'Netflix Premium',
          amount: 649.0,
          nextBillingDate: DateTime(2026, 10, 15),
          categoryName: 'Entertainment',
          cycleName: 'Monthly',
        ),
        RenewalSubscriptionItem(
          id: 'sub-2',
          name: 'Spotify Family',
          amount: 199.0,
          nextBillingDate: DateTime(2026, 10, 15),
          categoryName: 'Entertainment',
          cycleName: 'Monthly',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: RenewalCalendar(
                items: items,
                initialFocusedDate: focusedDate,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on Day 15
      final day15Finder = find.byKey(const Key('calendar_day_15'));
      await tester.tap(day15Finder);
      await tester.pumpAndSettle();

      // Modal should open
      expect(find.text('Scheduled Renewals'), findsOneWidget);
      expect(find.text('Netflix Premium'), findsOneWidget);
      expect(find.text('Spotify Family'), findsOneWidget);

      // 649 + 199 = 848.00 due
      expect(find.text('₹848.00 due'), findsOneWidget);
      expect(find.text('₹649.00'), findsOneWidget);
      expect(find.text('₹199.00'), findsOneWidget);

      // Close modal
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.text('Scheduled Renewals'), findsNothing);
    });

    testWidgets('Month navigation changes displayed month properly',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final focusedDate = DateTime(2026, 10, 1);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: RenewalCalendar(
                items: const [],
                initialFocusedDate: focusedDate,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('October 2026'), findsOneWidget);

      // Tap next month
      await tester.tap(find.byKey(const Key('next_month_button')));
      await tester.pumpAndSettle();
      expect(find.text('November 2026'), findsOneWidget);

      // Tap prev month twice
      await tester.tap(find.byKey(const Key('prev_month_button')));
      await tester.pumpAndSettle();
      expect(find.text('October 2026'), findsOneWidget);

      await tester.tap(find.byKey(const Key('prev_month_button')));
      await tester.pumpAndSettle();
      expect(find.text('September 2026'), findsOneWidget);
    });

    testWidgets('SubscriptionsScreen integrates RenewalCalendar and toggles between views',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const SubscriptionsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Should render Recurring Subscriptions header & RenewalCalendar
      expect(find.text('Recurring Subscriptions'), findsOneWidget);
      expect(find.byType(RenewalCalendar), findsOneWidget);

      // Toggle to list view
      final toggleButton = find.byKey(const Key('toggle_subscription_view_button'));
      await tester.tap(toggleButton);
      await tester.pumpAndSettle();

      // Calendar should be toggled off in pure list mode
      expect(find.byType(RenewalCalendar), findsNothing);

      // Toggle back to calendar view
      await tester.tap(toggleButton);
      await tester.pumpAndSettle();
      expect(find.byType(RenewalCalendar), findsOneWidget);
    });
  });
}
