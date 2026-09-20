import 'package:finance_app/core/constants/app_constants.dart';
import 'package:finance_app/features/tour/domain/feature_tour_service.dart';
import 'package:finance_app/features/tour/presentation/widgets/feature_spotlight_overlay.dart';
import 'package:finance_app/features/transactions/presentation/screens/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 54: FeatureTourService Unit Tests', () {
    setUp(() {
      FeatureTourService.instance.testingOverrideHasSeen = null;
    });

    tearDown(() {
      FeatureTourService.instance.testingOverrideHasSeen = null;
    });

    test('testingOverrideHasSeen controls hasSeenTour() without disk I/O', () async {
      FeatureTourService.instance.testingOverrideHasSeen = false;
      expect(await FeatureTourService.instance.hasSeenTour(), isFalse);

      FeatureTourService.instance.testingOverrideHasSeen = true;
      expect(await FeatureTourService.instance.hasSeenTour(), isTrue);
    });

    test('markTourSeen() sets state to true', () async {
      FeatureTourService.instance.testingOverrideHasSeen = false;
      expect(await FeatureTourService.instance.hasSeenTour(), isFalse);

      await FeatureTourService.instance.markTourSeen();
      expect(await FeatureTourService.instance.hasSeenTour(), isTrue);
    });

    test('resetTour() resets state to false', () async {
      FeatureTourService.instance.testingOverrideHasSeen = true;
      expect(await FeatureTourService.instance.hasSeenTour(), isTrue);

      await FeatureTourService.instance.resetTour();
      expect(await FeatureTourService.instance.hasSeenTour(), isFalse);
    });
  });

  group('Phase 54: FeatureSpotlightOverlay Widget Tests', () {
    final GlobalKey target1Key = GlobalKey();
    final GlobalKey target2Key = GlobalKey();
    final GlobalKey target3Key = GlobalKey();

    Widget buildTestHost({
      required VoidCallback onComplete,
      VoidCallback? onSkip,
    }) {
      final List<FeatureTourStep> testSteps = [
        FeatureTourStep(
          targetKey: target1Key,
          title: 'Step One Title',
          description: 'Step One Description',
          icon: Icons.add_circle,
        ),
        FeatureTourStep(
          targetKey: target2Key,
          title: 'Step Two Title',
          description: 'Step Two Description',
          icon: Icons.insights,
        ),
        FeatureTourStep(
          targetKey: target3Key,
          title: 'Step Three Title',
          description: 'Step Three Description',
          icon: Icons.notifications,
        ),
      ];

      return MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Column(
                children: [
                  Container(key: target1Key, height: 50, color: Colors.red),
                  const SizedBox(height: 50),
                  Container(key: target2Key, height: 50, color: Colors.green),
                  const SizedBox(height: 50),
                  Container(key: target3Key, height: 50, color: Colors.blue),
                ],
              ),
              Positioned.fill(
                child: FeatureSpotlightOverlay(
                  steps: testSteps,
                  onComplete: onComplete,
                  onSkip: onSkip,
                ),
              ),
            ],
          ),
        ),
      );
    }

    testWidgets('renders step 1 with title, description, step count, and skip button',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestHost(onComplete: () {}));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Step One Title'), findsOneWidget);
      expect(find.text('Step One Description'), findsOneWidget);
      expect(find.text('Step 1 of 3'), findsOneWidget);
      expect(find.byKey(const Key('feature_tour_skip_button')), findsOneWidget);
      expect(find.byKey(const Key('feature_tour_next_button')), findsOneWidget);
      // Back button should NOT be visible on first step
      expect(find.byKey(const Key('feature_tour_back_button')), findsNothing);
    });

    testWidgets('advancing with Next and stepping back with Back works seamlessly',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestHost(onComplete: () {}));
      await tester.pump(const Duration(milliseconds: 100));

      // Advance to Step 2
      await tester.tap(find.byKey(const Key('feature_tour_next_button')));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Step Two Title'), findsOneWidget);
      expect(find.text('Step 2 of 3'), findsOneWidget);
      expect(find.byKey(const Key('feature_tour_back_button')), findsOneWidget);

      // Go back to Step 1
      await tester.tap(find.byKey(const Key('feature_tour_back_button')));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Step One Title'), findsOneWidget);
      expect(find.text('Step 1 of 3'), findsOneWidget);
    });

    testWidgets('completing last step triggers onComplete callback',
        (WidgetTester tester) async {
      bool completed = false;
      await tester.pumpWidget(buildTestHost(onComplete: () {
        completed = true;
      }));
      await tester.pump(const Duration(milliseconds: 100));

      // Step 1 -> Step 2
      await tester.tap(find.byKey(const Key('feature_tour_next_button')));
      await tester.pump(const Duration(milliseconds: 100));

      // Step 2 -> Step 3
      await tester.tap(find.byKey(const Key('feature_tour_next_button')));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Step Three Title'), findsOneWidget);
      expect(find.text('Step 3 of 3'), findsOneWidget);
      expect(find.text('Got it!'), findsOneWidget);

      // Finish
      await tester.tap(find.byKey(const Key('feature_tour_next_button')));
      await tester.pump(const Duration(milliseconds: 100));

      expect(completed, isTrue);
    });

    testWidgets('tapping Skip button triggers onSkip callback',
        (WidgetTester tester) async {
      bool skipped = false;
      await tester.pumpWidget(buildTestHost(
        onComplete: () {},
        onSkip: () {
          skipped = true;
        },
      ));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byKey(const Key('feature_tour_skip_button')));
      await tester.pump(const Duration(milliseconds: 100));

      expect(skipped, isTrue);
    });
  });

  group('Phase 54: DashboardScreen Tour Integration Tests', () {
    setUp(() {
      FeatureTourService.instance.testingOverrideHasSeen = false;
    });

    tearDown(() {
      FeatureTourService.instance.testingOverrideHasSeen = null;
    });

    testWidgets('Dashboard renders all 3 key spotlight target entry points',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: {
            AppConstants.transactionsRoute: (_) => const Scaffold(body: Text('Transactions')),
            AppConstants.analyticsRoute: (_) => const Scaffold(body: Text('Analytics')),
            AppConstants.notificationConsentRoute: (_) => const Scaffold(body: Text('Consent')),
            AppConstants.splitBillRoute: (_) => const Scaffold(body: Text('Split Bill')),
          },
          home: const DashboardScreen(disableTour: true),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // 1. + Add Transaction / Expense Button
      expect(find.byKey(const Key('feature_tour_add_transaction')), findsOneWidget);

      // 2. Analytics 7-day sparkline drill-down
      expect(find.byKey(const Key('feature_tour_analytics_drilldown')), findsOneWidget);

      // 3. Notification permission / sync toggle
      expect(find.byKey(const Key('feature_tour_notification_toggle')), findsOneWidget);
    });

    testWidgets('Dashboard automatically shows Feature Discovery Tour on first boot',
        (WidgetTester tester) async {
      FeatureTourService.instance.testingOverrideHasSeen = false;

      await tester.pumpWidget(
        MaterialApp(
          routes: {
            AppConstants.transactionsRoute: (_) => const Scaffold(body: Text('Transactions')),
            AppConstants.analyticsRoute: (_) => const Scaffold(body: Text('Analytics')),
            AppConstants.notificationConsentRoute: (_) => const Scaffold(body: Text('Consent')),
            AppConstants.splitBillRoute: (_) => const Scaffold(body: Text('Split Bill')),
          },
          home: const DashboardScreen(forceShowTour: true),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Tour Step 1 is visible
      expect(find.text('Quick Add Transaction'), findsOneWidget);
      expect(find.text('Step 1 of 3'), findsOneWidget);

      // Step forward to Analytics Drill-Down
      await tester.tap(find.byKey(const Key('feature_tour_next_button')));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Analytics Drill-Down'), findsOneWidget);
      expect(find.text('Step 2 of 3'), findsOneWidget);

      // Step forward to Notification Sync
      await tester.tap(find.byKey(const Key('feature_tour_next_button')));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Smart Notification Sync'), findsOneWidget);
      expect(find.text('Step 3 of 3'), findsOneWidget);

      // Finish tour
      await tester.tap(find.byKey(const Key('feature_tour_next_button')));
      await tester.pump(const Duration(milliseconds: 100));

      // Tour is dismissed
      expect(find.text('Smart Notification Sync'), findsNothing);
    });
  });
}
