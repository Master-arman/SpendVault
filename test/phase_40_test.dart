import 'package:finance_app/core/utils/currency_formatter.dart';
import 'package:finance_app/features/subscriptions/data/models/subscription.dart';
import 'package:finance_app/features/subscriptions/domain/models/subscription_model.dart';
import 'package:finance_app/features/subscriptions/presentation/widgets/committed_liabilities_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 40: Committed Liabilities Calculator Unit Tests', () {
    final DateTime refDate = DateTime(2026, 10, 15);

    test('Computes upcoming vs settled commitments accurately for the current month', () {
      final List<SubscriptionModel> subs = [
        SubscriptionModel(
          id: 'sub-1',
          name: 'Netflix',
          amount: 649.0,
          cycle: BillingCycle.monthly,
          nextBillingDate: DateTime(2026, 10, 20), // Upcoming (after 15th)
          categoryName: 'Entertainment',
          isActive: true,
        ),
        SubscriptionModel(
          id: 'sub-2',
          name: 'Spotify',
          amount: 179.0,
          cycle: BillingCycle.monthly,
          nextBillingDate: DateTime(2026, 10, 5), // Settled (before 15th)
          categoryName: 'Entertainment',
          isActive: true,
        ),
        SubscriptionModel(
          id: 'sub-3',
          name: 'Gym Membership',
          amount: 1500.0,
          cycle: BillingCycle.monthly,
          nextBillingDate: DateTime(2026, 10, 15), // Due today -> Upcoming
          categoryName: 'Health',
          isActive: true,
        ),
      ];

      final projection = CommittedLiabilitiesCalculator.compute(
        subscriptions: subs,
        referenceDate: refDate,
        availableBalance: 50000.0,
      );

      // Total monthly commitment = 649 + 179 + 1500 = 2328.0
      expect(projection.totalMonthlyCommitment, 2328.0);
      // Upcoming = Netflix (649) + Gym (1500) = 2149.0
      expect(projection.upcomingMonthlyCommitment, 2149.0);
      // Settled = Spotify (179) = 179.0
      expect(projection.settledMonthlyCommitment, 179.0);
      // Spendable balance = 50000.0 - 2149.0 = 47851.0
      expect(projection.spendableBalance, 47851.0);
      expect(projection.upcomingItems.length, 2);
      expect(projection.settledItems.length, 1);
      expect(projection.activeSubscriptionsCount, 3);
      expect(projection.pausedSubscriptionsCount, 0);
    });

    test('Ignores inactive/paused (frozen) subscriptions in commitment projection', () {
      final List<SubscriptionModel> subs = [
        SubscriptionModel(
          id: 'sub-1',
          name: 'Active Service',
          amount: 500.0,
          cycle: BillingCycle.monthly,
          nextBillingDate: DateTime(2026, 10, 25),
          categoryName: 'Utilities',
          isActive: true,
        ),
        SubscriptionModel(
          id: 'sub-2',
          name: 'Paused Service',
          amount: 1200.0,
          cycle: BillingCycle.monthly,
          nextBillingDate: DateTime(2026, 10, 22),
          categoryName: 'Entertainment',
          isActive: false, // Paused
        ),
      ];

      final projection = CommittedLiabilitiesCalculator.compute(
        subscriptions: subs,
        referenceDate: refDate,
        availableBalance: 10000.0,
      );

      expect(projection.totalMonthlyCommitment, 500.0);
      expect(projection.upcomingMonthlyCommitment, 500.0);
      expect(projection.spendableBalance, 9500.0);
      expect(projection.activeSubscriptionsCount, 1);
      expect(projection.pausedSubscriptionsCount, 1);
    });

    test('Supports Isar Subscription entities seamlessly', () {
      final sub = Subscription()
        ..id = 99
        ..name = 'Cloud Storage'
        ..amount = 350.0
        ..cycle = BillingCycle.monthly
        ..nextBillingDate = DateTime(2026, 10, 28)
        ..reminderDaysBefore = 2
        ..isActive = true;

      final projection = CommittedLiabilitiesCalculator.compute(
        subscriptions: [sub],
        referenceDate: refDate,
        availableBalance: 20000.0,
      );

      expect(projection.totalMonthlyCommitment, 350.0);
      expect(projection.upcomingMonthlyCommitment, 350.0);
      expect(projection.spendableBalance, 19650.0);
      expect(projection.upcomingItems.first.name, 'Cloud Storage');
    });

    test('Calculates safe daily spend based on days remaining in the month', () {
      // Oct 15 -> Oct 31 has 17 days remaining (15..31)
      final projection = CommittedLiabilitiesCalculator.compute(
        subscriptions: [],
        referenceDate: DateTime(2026, 10, 15),
        availableBalance: 17000.0,
      );

      expect(projection.daysRemainingInMonth, 17);
      expect(projection.safeDailySpend, 1000.0);
    });
  });

  group('Phase 40: Committed Liabilities Card Widget Tests', () {
    final DateTime refDate = DateTime(2026, 10, 15);
    final List<SubscriptionModel> mockSubs = [
      SubscriptionModel(
        id: 'sub-1',
        name: 'Netflix Premium',
        amount: 649.0,
        cycle: BillingCycle.monthly,
        nextBillingDate: DateTime(2026, 10, 20),
        categoryName: 'Entertainment',
      ),
      SubscriptionModel(
        id: 'sub-2',
        name: 'GitHub Pro',
        amount: 820.0,
        cycle: BillingCycle.monthly,
        nextBillingDate: DateTime(2026, 10, 25),
        categoryName: 'Development',
      ),
    ];

    testWidgets('Renders spendable balance, upcoming commitments and breakdown expansion', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommittedLiabilitiesCard(
              subscriptions: mockSubs,
              availableBalance: 50000.0,
              referenceDate: refDate,
            ),
          ),
        ),
      );

      // Verify header and primary metrics
      expect(find.byKey(const Key('committed_liabilities_card')), findsOneWidget);
      expect(find.text('Monthly Committed Liabilities'), findsOneWidget);
      expect(find.byKey(const Key('spendable_balance_text')), findsOneWidget);
      expect(find.byKey(const Key('upcoming_commitments_text')), findsOneWidget);

      // Spendable: 50,000 - (649 + 820 = 1469) = 48,531.00
      expect(find.text(CurrencyFormatter.format(48531.00)), findsOneWidget);
      expect(find.text(CurrencyFormatter.format(1469.00)), findsOneWidget);

      // Verify breakdown is initially collapsed
      expect(find.text('UPCOMING COMMITMENTS BREAKDOWN'), findsNothing);

      // Tap toggle breakdown button to expand
      await tester.tap(find.byKey(const Key('toggle_breakdown_button')));
      await tester.pumpAndSettle();

      expect(find.text('UPCOMING COMMITMENTS BREAKDOWN'), findsOneWidget);
      expect(find.text('Netflix Premium'), findsOneWidget);
      expect(find.text('GitHub Pro'), findsOneWidget);
    });

    testWidgets('Displays all settled message when there are no upcoming bills', (tester) async {
      final List<SubscriptionModel> settledSubs = [
        SubscriptionModel(
          id: 'sub-1',
          name: 'Already Paid Service',
          amount: 299.0,
          cycle: BillingCycle.monthly,
          nextBillingDate: DateTime(2026, 10, 2), // Past
          categoryName: 'Utilities',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommittedLiabilitiesCard(
              subscriptions: settledSubs,
              availableBalance: 25000.0,
              referenceDate: refDate,
              initiallyExpanded: true,
            ),
          ),
        ),
      );

      // 0 upcoming bills
      expect(find.text(CurrencyFormatter.format(0.0)), findsOneWidget);
      expect(find.text('All committed liabilities for this month are settled!'), findsOneWidget);
    });
  });
}
