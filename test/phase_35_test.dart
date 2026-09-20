import 'package:finance_app/features/subscriptions/data/models/subscription.dart';
import 'package:finance_app/features/subscriptions/domain/models/subscription_model.dart';
import 'package:finance_app/features/subscriptions/domain/subscription_reconciler.dart';
import 'package:finance_app/features/transactions/data/models/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 35: Downtime Catch-Up & Cold-Boot Auto-Reconciler Tests', () {
    const reconciler = SubscriptionReconciler();

    group('Catch-up Prompt and Date Formatting', () {
      test('formatCatchUpPrompt produces exact required prompt for Netflix ₹649 on 12th Sept', () {
        final prompt = SubscriptionReconciler.formatCatchUpPrompt(
          name: 'Netflix',
          amount: 649.0,
          billingDate: DateTime(2026, 9, 12),
        );
        expect(prompt, 'Did your Netflix renewal for ₹649 go through on 12th Sept?');
      });

      test('formatOrdinalDate correctly handles 1st, 2nd, 3rd, 4th, 11th, 12th, 13th, 21st, 22nd, 23rd, 31st', () {
        expect(SubscriptionReconciler.formatOrdinalDate(DateTime(2026, 1, 1)), '1st Jan');
        expect(SubscriptionReconciler.formatOrdinalDate(DateTime(2026, 2, 2)), '2nd Feb');
        expect(SubscriptionReconciler.formatOrdinalDate(DateTime(2026, 3, 3)), '3rd Mar');
        expect(SubscriptionReconciler.formatOrdinalDate(DateTime(2026, 4, 4)), '4th Apr');
        expect(SubscriptionReconciler.formatOrdinalDate(DateTime(2026, 5, 11)), '11th May');
        expect(SubscriptionReconciler.formatOrdinalDate(DateTime(2026, 6, 12)), '12th Jun');
        expect(SubscriptionReconciler.formatOrdinalDate(DateTime(2026, 7, 13)), '13th Jul');
        expect(SubscriptionReconciler.formatOrdinalDate(DateTime(2026, 8, 21)), '21st Aug');
        expect(SubscriptionReconciler.formatOrdinalDate(DateTime(2026, 9, 22)), '22nd Sept');
        expect(SubscriptionReconciler.formatOrdinalDate(DateTime(2026, 10, 23)), '23rd Oct');
        expect(SubscriptionReconciler.formatOrdinalDate(DateTime(2026, 12, 31)), '31st Dec');
      });

      test('formatCatchUpPrompt supports decimal amounts and custom currency symbols', () {
        final prompt = SubscriptionReconciler.formatCatchUpPrompt(
          name: 'Spotify Premium',
          amount: 119.50,
          billingDate: DateTime(2026, 10, 1),
          currencySymbol: '\$',
        );
        expect(prompt, 'Did your Spotify Premium renewal for \$119.50 go through on 1st Oct?');
      });
    });

    group('Billing Cycle Date Advancement', () {
      test('Weekly advances by 7 days', () {
        final start = DateTime(2026, 9, 1);
        final next = SubscriptionReconciler.advanceBillingDate(start, BillingCycle.weekly);
        expect(next, DateTime(2026, 9, 8));
      });

      test('Monthly advances by 1 month and handles month-end clamping (Jan 31 -> Feb 28)', () {
        final start = DateTime(2026, 9, 12);
        final next = SubscriptionReconciler.advanceBillingDate(start, BillingCycle.monthly);
        expect(next, DateTime(2026, 10, 12));

        // Clamping test: 31 Jan in non-leap year -> 28 Feb
        final jan31 = DateTime(2027, 1, 31);
        final febEnd = SubscriptionReconciler.advanceBillingDate(jan31, BillingCycle.monthly);
        expect(febEnd, DateTime(2027, 2, 28));
      });

      test('Quarterly advances by 3 months', () {
        final start = DateTime(2026, 3, 15);
        final next = SubscriptionReconciler.advanceBillingDate(start, BillingCycle.quarterly);
        expect(next, DateTime(2026, 6, 15));
      });

      test('Yearly advances by 1 year', () {
        final start = DateTime(2026, 9, 12);
        final next = SubscriptionReconciler.advanceBillingDate(start, BillingCycle.yearly);
        expect(next, DateTime(2027, 9, 12));
      });
    });

    group('Overdue Subscriptions Detection on Cold-Boot / Startup', () {
      test('finds overdue subscriptions when app was closed for 14 days', () {
        final now = DateTime(2026, 9, 26); // 14 days after 12 Sept

        final sub1 = Subscription()
          ..id = 1
          ..name = 'Netflix'
          ..amount = 649.0
          ..cycle = BillingCycle.monthly
          ..nextBillingDate = DateTime(2026, 9, 12) // Overdue
          ..reminderDaysBefore = 3
          ..isActive = true;

        final sub2 = Subscription()
          ..id = 2
          ..name = 'Gym'
          ..amount = 1500.0
          ..cycle = BillingCycle.monthly
          ..nextBillingDate = DateTime(2026, 9, 10) // Overdue
          ..reminderDaysBefore = 1
          ..isActive = true;

        final sub3 = Subscription()
          ..id = 3
          ..name = 'Disney+'
          ..amount = 299.0
          ..cycle = BillingCycle.monthly
          ..nextBillingDate = DateTime(2026, 9, 30) // Future (not overdue)
          ..reminderDaysBefore = 2
          ..isActive = true;

        final sub4 = Subscription()
          ..id = 4
          ..name = 'Cancelled Sub'
          ..amount = 500.0
          ..cycle = BillingCycle.monthly
          ..nextBillingDate = DateTime(2026, 9, 5) // Overdue but inactive
          ..reminderDaysBefore = 1
          ..isActive = false;

        final overdue = reconciler.findOverdueSubscriptions(
          subscriptions: [sub1, sub2, sub3, sub4],
          now: now,
        );

        expect(overdue.length, 2);
        expect(overdue[0].subscriptionName, 'Netflix');
        expect(overdue[0].promptText, 'Did your Netflix renewal for ₹649 go through on 12th Sept?');
        expect(overdue[1].subscriptionName, 'Gym');
        expect(overdue[1].promptText, 'Did your Gym renewal for ₹1500 go through on 10th Sept?');
      });
    });

    group('Reconciliation Execution & Transaction Generation', () {
      test('reconcileSubscription advances nextBillingDate and generates matching expense Transaction', () {
        final originalBillingDate = DateTime(2026, 9, 12);
        final sub = Subscription()
          ..id = 42
          ..name = 'Netflix'
          ..amount = 649.0
          ..cycle = BillingCycle.monthly
          ..nextBillingDate = originalBillingDate
          ..reminderDaysBefore = 3
          ..isActive = true;

        final result = reconciler.reconcileSubscription(subscription: sub);

        // 1. Check updated billing date
        expect(result.originalBillingDate, DateTime(2026, 9, 12));
        expect(result.updatedNextBillingDate, DateTime(2026, 10, 12));
        expect(sub.nextBillingDate, DateTime(2026, 10, 12));

        // 2. Check generated Transaction record
        final tx = result.transaction;
        expect(tx.amount, 649.0);
        expect(tx.type, TransactionType.expense);
        expect(tx.timestamp, originalBillingDate);
        expect(tx.note, 'Recurring Renewal: Netflix');
        expect(tx.tags, contains('subscription'));
        expect(tx.tags, contains('recurring'));
        expect(tx.tags, contains('auto-reconciled'));
        expect(tx.tags, contains('netflix'));
      });

      test('reconcileModel supports domain SubscriptionModel entity', () {
        final model = SubscriptionModel(
          id: 'sub-gym-100',
          name: 'Gold Gym',
          amount: 2500.0,
          cycle: BillingCycle.quarterly,
          nextBillingDate: DateTime(2026, 6, 1),
          categoryName: 'Health',
          isActive: true,
        );

        final result = reconciler.reconcileModel(model: model);

        expect(result.originalBillingDate, DateTime(2026, 6, 1));
        expect(result.updatedNextBillingDate, DateTime(2026, 9, 1));
        expect(result.transaction.amount, 2500.0);
        expect(result.transaction.type, TransactionType.expense);
        expect(result.transaction.note, 'Recurring Renewal: Gold Gym');
        expect(result.transaction.tags, contains('gold gym'));
      });
    });
  });
}
