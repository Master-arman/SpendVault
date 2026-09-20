import 'package:finance_app/features/accounts/data/models/account.dart';
import 'package:finance_app/features/categories/data/models/category.dart';
import 'package:finance_app/features/subscriptions/data/models/subscription.dart';
import 'package:finance_app/features/subscriptions/domain/models/subscription_model.dart';
import 'package:finance_app/features/subscriptions/domain/subscription_auto_logger.dart';
import 'package:finance_app/features/subscriptions/presentation/screens/add_subscription_screen.dart';
import 'package:finance_app/features/transactions/data/models/transaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 37: Automatic Subscription Transaction Generation Tests', () {
    late SubscriptionAutoLogger autoLogger;

    setUp(() {
      autoLogger = const SubscriptionAutoLogger();
    });

    group('Model & Schema Properties', () {
      test('Subscription model supports autoLogOnRenewal flag with default false', () {
        final sub = Subscription()
          ..name = 'Netflix 4K'
          ..amount = 649.0
          ..cycle = BillingCycle.monthly
          ..nextBillingDate = DateTime(2026, 10, 15);

        expect(sub.autoLogOnRenewal, isFalse);

        sub.autoLogOnRenewal = true;
        expect(sub.autoLogOnRenewal, isTrue);
      });

      test('SubscriptionModel entity supports autoLogOnRenewal and account linking', () {
        final model = SubscriptionModel(
          id: 'sub_001',
          name: 'Spotify Premium',
          amount: 119.0,
          cycle: BillingCycle.monthly,
          nextBillingDate: DateTime(2026, 11, 1),
          categoryName: 'Entertainment',
          autoLogOnRenewal: true,
          accountId: 'acc_hdfc',
          accountName: 'HDFC Checking',
        );

        expect(model.autoLogOnRenewal, isTrue);
        expect(model.accountId, 'acc_hdfc');
        expect(model.accountName, 'HDFC Checking');
      });
    });

    group('SubscriptionAutoLogger Pipeline Execution', () {
      test('processDueSubscriptions executes atomic balance deduction, advances nextBillingDate, and generates Transaction', () {
        final now = DateTime(2026, 10, 15, 10, 0);

        final account = Account()
          ..name = 'HDFC Salary'
          ..currentBalance = 50000.0
          ..type = AccountType.bank;

        final category = Category()
          ..name = 'Entertainment'
          ..colorHex = 0xFF6366F1;

        final sub1 = Subscription()
          ..id = 1
          ..name = 'Netflix'
          ..amount = 649.0
          ..cycle = BillingCycle.monthly
          ..nextBillingDate = DateTime(2026, 10, 15) // Due today
          ..reminderDaysBefore = 3
          ..autoLogOnRenewal = true
          ..isActive = true;
        sub1.account.value = account;
        sub1.category.value = category;

        final sub2 = Subscription()
          ..id = 2
          ..name = 'Gym Membership'
          ..amount = 1500.0
          ..cycle = BillingCycle.monthly
          ..nextBillingDate = DateTime(2026, 10, 20) // Future (not due)
          ..reminderDaysBefore = 2
          ..autoLogOnRenewal = true
          ..isActive = true;

        final sub3 = Subscription()
          ..id = 3
          ..name = 'AWS Cloud'
          ..amount = 2500.0
          ..cycle = BillingCycle.monthly
          ..nextBillingDate = DateTime(2026, 10, 10) // Due, but autoLog is FALSE
          ..reminderDaysBefore = 1
          ..autoLogOnRenewal = false
          ..isActive = true;

        final sub4 = Subscription()
          ..id = 4
          ..name = 'Cancelled Service'
          ..amount = 300.0
          ..cycle = BillingCycle.monthly
          ..nextBillingDate = DateTime(2026, 10, 10)
          ..reminderDaysBefore = 1
          ..autoLogOnRenewal = true
          ..isActive = false; // Inactive

        final results = autoLogger.processDueSubscriptions(
          subscriptions: [sub1, sub2, sub3, sub4],
          now: now,
        );

        // Only sub1 should be processed
        expect(results.length, 1);

        final res = results.first;
        expect(res.subscriptionName, 'Netflix');
        expect(res.amount, 649.0);
        expect(res.originalBillingDate, DateTime(2026, 10, 15));
        expect(res.updatedNextBillingDate, DateTime(2026, 11, 15));
        expect(sub1.nextBillingDate, DateTime(2026, 11, 15));

        // Phase 6 balance deduction check
        expect(res.previousBalance, 50000.0);
        expect(res.newBalance, 49351.0); // 50000 - 649
        expect(account.currentBalance, 49351.0);

        // Transaction record check
        final tx = res.transaction;
        expect(tx.amount, 649.0);
        expect(tx.type, TransactionType.expense);
        expect(tx.timestamp, DateTime(2026, 10, 15));
        expect(tx.note, 'Auto-Logged Renewal: Netflix');
        expect(tx.tags, containsAll(['subscription', 'recurring', 'auto-logged', 'netflix']));
        expect(tx.sourceAccount.value?.name, 'HDFC Salary');
      });

      test('processDueModels processes domain entities and updates account ledger correctly', () {
        final now = DateTime(2026, 12, 1);

        final account = Account()
          ..name = 'Amazon Pay Wallet'
          ..currentBalance = 3000.0
          ..type = AccountType.wallet;

        final model = SubscriptionModel(
          id: 'prime-yearly',
          name: 'Amazon Prime',
          amount: 1499.0,
          cycle: BillingCycle.yearly,
          nextBillingDate: DateTime(2026, 12, 1),
          categoryName: 'Shopping',
          autoLogOnRenewal: true,
          accountId: 'acc_wallet',
        );

        final results = autoLogger.processDueModels(
          models: [model],
          now: now,
          accountsMap: {'acc_wallet': account},
        );

        expect(results.length, 1);
        final res = results.first;
        expect(res.subscriptionName, 'Amazon Prime');
        expect(res.amount, 1499.0);
        expect(res.updatedNextBillingDate, DateTime(2027, 12, 1));
        expect(res.previousBalance, 3000.0);
        expect(res.newBalance, 1501.0);
        expect(account.currentBalance, 1501.0);
        expect(res.transaction.amount, 1499.0);
        expect(res.transaction.tags, contains('auto-logged'));
      });
    });

    group('AddSubscriptionScreen UI Auto-Log Switch Integration', () {
      testWidgets('renders Auto-Log on Renewal Date switch and passes autoLogOnRenewal to onSave',
          (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        Subscription? savedSub;

        await tester.pumpWidget(
          MaterialApp(
            home: AddSubscriptionScreen(
              initialName: 'YouTube Premium',
              initialAmount: 189.0,
              initialCycle: BillingCycle.monthly,
              initialAutoLog: false,
              onSave: (Subscription sub) async {
                savedSub = sub;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Auto-Log on Renewal Date'), findsOneWidget);
        expect(
          find.text('Automatically record transaction & deduct ledger balance on billing date without manual prompt'),
          findsOneWidget,
        );

        final switchFinder = find.byKey(const Key('switch_auto_log_renewal'));
        expect(switchFinder, findsOneWidget);

        // Scroll to switch and tap to toggle it ON
        await tester.ensureVisible(switchFinder);
        await tester.pumpAndSettle();
        await tester.tap(switchFinder);
        await tester.pumpAndSettle();

        // Tap Save Subscription button
        final saveBtn = find.byKey(const Key('save_subscription_button'));
        await tester.ensureVisible(saveBtn);
        await tester.pumpAndSettle();
        await tester.tap(saveBtn);
        await tester.pumpAndSettle();

        expect(savedSub, isNotNull);
        expect(savedSub?.name, 'YouTube Premium');
        expect(savedSub?.amount, 189.0);
        expect(savedSub?.autoLogOnRenewal, isTrue);
      });
    });
  });
}
