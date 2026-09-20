import 'package:finance_app/features/accounts/data/models/account.dart';
import 'package:finance_app/features/categories/data/models/category.dart';
import 'package:finance_app/features/subscriptions/data/models/subscription.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

void main() {
  group('Phase 31: Recurring Subscription Schema Tests', () {
    test('Subscription model initializes all required fields and links correctly', () {
      final billingDate = DateTime(2026, 10, 15);
      final sub = Subscription()
        ..name = 'Netflix Premium'
        ..amount = 649.0
        ..cycle = BillingCycle.monthly
        ..nextBillingDate = billingDate
        ..reminderDaysBefore = 3
        ..isActive = true;

      expect(sub.id, Isar.autoIncrement);
      expect(sub.name, 'Netflix Premium');
      expect(sub.amount, 649.0);
      expect(sub.cycle, BillingCycle.monthly);
      expect(sub.nextBillingDate, billingDate);
      expect(sub.reminderDaysBefore, 3);
      expect(sub.isActive, isTrue);
      expect(sub.category, isA<IsarLink<Category>>());
      expect(sub.account, isA<IsarLink<Account>>());
    });

    test('BillingCycle enum supports weekly, monthly, quarterly, and yearly cycles', () {
      expect(BillingCycle.values, containsAll([
        BillingCycle.weekly,
        BillingCycle.monthly,
        BillingCycle.quarterly,
        BillingCycle.yearly,
      ]));
      expect(BillingCycle.values.length, 4);
      expect(BillingCycle.monthly.name, 'monthly');
      expect(BillingCycle.quarterly.name, 'quarterly');
      expect(BillingCycle.yearly.name, 'yearly');
      expect(BillingCycle.weekly.name, 'weekly');
    });

    test('Subscription defaults isActive to true', () {
      final sub = Subscription();
      expect(sub.isActive, isTrue);
    });

    test('Subscription links can attach Category and Account instances', () {
      final cat = Category()
        ..name = 'Entertainment'
        ..colorHex = 0xFF8B5CF6;

      final acc = Account()
        ..name = 'HDFC Bank'
        ..currentBalance = 50000.0
        ..type = AccountType.bank
        ..colorHex = 0xFF6366F1;

      final sub = Subscription()
        ..name = 'Spotify Family'
        ..amount = 199.0
        ..cycle = BillingCycle.monthly
        ..nextBillingDate = DateTime(2026, 10, 1)
        ..reminderDaysBefore = 2;

      sub.category.value = cat;
      sub.account.value = acc;

      expect(sub.category.value?.name, 'Entertainment');
      expect(sub.account.value?.name, 'HDFC Bank');
    });
  });
}
