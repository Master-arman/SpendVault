import 'package:finance_app/features/subscriptions/data/models/subscription.dart';
import 'package:finance_app/features/subscriptions/domain/models/subscription_model.dart';
import 'package:finance_app/features/subscriptions/domain/subscription_lifetime_calculator.dart';
import 'package:finance_app/features/subscriptions/presentation/screens/subscription_detail_screen.dart';
import 'package:finance_app/features/transactions/data/models/transaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 38: Historical Value & Lifetime Spend Engine Tests', () {
    group('SubscriptionLifetimeCalculator Calculation Engine', () {
      test('calculates Total Invested = ∑ Historical Transactions where tags contains #subscription_id', () {
        const String subId = '101';

        final tx1 = Transaction()
          ..id = 1
          ..amount = 499.0
          ..type = TransactionType.expense
          ..timestamp = DateTime(2025, 1, 15)
          ..tags = ['subscription', '#subscription_101'];

        final tx2 = Transaction()
          ..id = 2
          ..amount = 499.0
          ..type = TransactionType.expense
          ..timestamp = DateTime(2025, 2, 15)
          ..tags = ['subscription', '#subscription_101'];

        final tx3 = Transaction()
          ..id = 3
          ..amount = 599.0 // Price Hike 1
          ..type = TransactionType.expense
          ..timestamp = DateTime(2025, 3, 15)
          ..tags = ['subscription', '#subscription_101'];

        final tx4 = Transaction()
          ..id = 4
          ..amount = 649.0 // Price Hike 2
          ..type = TransactionType.expense
          ..timestamp = DateTime(2025, 4, 15)
          ..tags = ['subscription', '#subscription_101'];

        // Unrelated transaction
        final txOther = Transaction()
          ..id = 5
          ..amount = 1500.0
          ..type = TransactionType.expense
          ..timestamp = DateTime(2025, 4, 20)
          ..tags = ['shopping', '#subscription_202'];

        final analytics = SubscriptionLifetimeCalculator.calculateFromTransactions(
          subscriptionId: subId,
          allTransactions: [tx1, tx2, tx3, tx4, txOther],
        );

        // 1. Total Invested = 499 + 499 + 599 + 649 = 2246.0
        expect(analytics.totalInvested, 2246.0);
        expect(analytics.transactionsCount, 4);

        // 2. Price Hikes Detection
        expect(analytics.hasPriceHikes, isTrue);
        expect(analytics.priceHikesCount, 2);
        expect(analytics.initialPrice, 499.0);
        expect(analytics.latestPrice, 649.0);

        // Lifetime hike percentage: ((649 - 499) / 499) * 100 = ~30.06%
        expect(analytics.lifetimeHikePercentage, closeTo(30.06, 0.05));

        // 3. Price points list
        expect(analytics.pricePoints.length, 4);
        expect(analytics.pricePoints[0].isHike, isFalse);
        expect(analytics.pricePoints[1].isHike, isFalse);
        expect(analytics.pricePoints[2].isHike, isTrue);
        expect(analytics.pricePoints[2].priceDifference, 100.0);
        expect(analytics.pricePoints[3].isHike, isTrue);
        expect(analytics.pricePoints[3].priceDifference, 50.0);

        // 4. Chart Spots Generation
        final spots = SubscriptionLifetimeCalculator.generateChartSpots(analytics.pricePoints);
        expect(spots.length, 4);
        expect(spots[0].y, 499.0);
        expect(spots[3].y, 649.0);
      });

      test('handles subscriptions with 0 historical transactions gracefully', () {
        final analytics = SubscriptionLifetimeCalculator.calculateFromTransactions(
          subscriptionId: '999',
          allTransactions: [],
        );

        expect(analytics.totalInvested, 0.0);
        expect(analytics.transactionsCount, 0);
        expect(analytics.hasPriceHikes, isFalse);
        expect(analytics.priceHikesCount, 0);
        expect(analytics.initialPrice, 0.0);
        expect(analytics.latestPrice, 0.0);
        expect(analytics.lifetimeHikePercentage, 0.0);
      });
    });

    group('SubscriptionDetailScreen UI Rendering & Integration', () {
      testWidgets('renders Hero Total Invested card, Price Hike trajectory chart, and historical ledger list',
          (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final sub = Subscription()
          ..id = 42
          ..name = 'Netflix Premium'
          ..amount = 649.0
          ..cycle = BillingCycle.monthly
          ..nextBillingDate = DateTime(2026, 11, 15)
          ..reminderDaysBefore = 3
          ..isActive = true;

        final tx1 = Transaction()
          ..id = 101
          ..amount = 499.0
          ..type = TransactionType.expense
          ..timestamp = DateTime(2026, 1, 15)
          ..note = 'Renewal: Netflix Premium'
          ..tags = ['#subscription_42'];

        final tx2 = Transaction()
          ..id = 102
          ..amount = 649.0 // Hike
          ..type = TransactionType.expense
          ..timestamp = DateTime(2026, 2, 15)
          ..note = 'Renewal: Netflix Premium'
          ..tags = ['#subscription_42'];

        await tester.pumpWidget(
          MaterialApp(
            home: SubscriptionDetailScreen(
              subscription: sub,
              historicalTransactions: [tx1, tx2],
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Verify Header & Hero card
        expect(find.text('Netflix Premium'), findsWidgets);
        expect(find.text('TOTAL INVESTED'), findsOneWidget);
        // Total invested = 499 + 649 = 1148.00 -> ₹1,148.00
        expect(find.text('₹1,148.00'), findsOneWidget);
        expect(find.text('Current Rate'), findsOneWidget);
        expect(find.text('₹649.00 / monthly'), findsOneWidget);
        expect(find.text('ACTIVE'), findsOneWidget);

        // 2. Verify Price Hike Chart section
        expect(find.text('PRICE HIKE & RATE TRAJECTORY'), findsOneWidget);
        expect(find.text('+30.1% hike'), findsOneWidget);

        // 3. Verify Historical Renewals list
        expect(find.text('HISTORICAL RENEWALS'), findsOneWidget);
        expect(find.text('2 records'), findsOneWidget);
        expect(find.text('Renewal: Netflix Premium'), findsNWidgets(2));
      });

      testWidgets('renders domain SubscriptionModel and empty historical state correctly',
          (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final model = SubscriptionModel(
          id: 'sub-gym-100',
          name: 'Gold Gym',
          amount: 2500.0,
          cycle: BillingCycle.monthly,
          nextBillingDate: DateTime(2026, 10, 1),
          categoryName: 'Health & Fitness',
          isActive: true,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: SubscriptionDetailScreen(
              subscriptionModel: model,
              historicalTransactions: const [],
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Gold Gym'), findsWidgets);
        expect(find.text('TOTAL INVESTED'), findsOneWidget);
        expect(find.text('₹2,500.00'), findsOneWidget);
        expect(find.text('Stable Price'), findsOneWidget);
        expect(find.text('No historical renewals logged yet'), findsOneWidget);
      });
    });
  });
}
