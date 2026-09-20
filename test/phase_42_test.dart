import 'package:finance_app/features/accounts/data/models/account.dart';
import 'package:finance_app/features/categories/data/models/category.dart';
import 'package:finance_app/features/transactions/data/models/transaction.dart';
import 'package:finance_app/features/transactions/domain/models/transaction_model.dart';
import 'package:finance_app/features/transactions/presentation/widgets/filter_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 42: TransactionFilterCriteria Unit Tests', () {
    test('Evaluates account IDs, category IDs, amount limits, and date range filters', () {
      final acc1 = Account()..id = 10..name = 'Savings';
      final acc2 = Account()..id = 20..name = 'Checking';
      final catFood = Category()..id = 100..name = 'Food';
      final catTech = Category()..id = 200..name = 'Tech';

      final tx1 = Transaction()
        ..id = 1
        ..amount = 450.0
        ..timestamp = DateTime(2026, 9, 10);
      tx1.sourceAccount.value = acc1;
      tx1.category.value = catFood;

      final tx2 = Transaction()
        ..id = 2
        ..amount = 2500.0
        ..timestamp = DateTime(2026, 9, 15);
      tx2.sourceAccount.value = acc2;
      tx2.category.value = catTech;

      // 1. Account filter (matches only acc1)
      final accountFilter = TransactionFilterCriteria(accountIds: {10});
      expect(accountFilter.matchesIsar(tx1), isTrue);
      expect(accountFilter.matchesIsar(tx2), isFalse);

      // 2. Category filter (matches only catTech)
      final catFilter = TransactionFilterCriteria(categoryIds: {200});
      expect(catFilter.matchesIsar(tx1), isFalse);
      expect(catFilter.matchesIsar(tx2), isTrue);

      // 3. Amount boundary filter (min 1000, max 3000)
      final amountFilter = TransactionFilterCriteria(minAmount: 1000.0, maxAmount: 3000.0);
      expect(amountFilter.matchesIsar(tx1), isFalse);
      expect(amountFilter.matchesIsar(tx2), isTrue);

      // 4. Date range filter
      final dateFilter = TransactionFilterCriteria(
        dateRange: DateTimeRange(
          start: DateTime(2026, 9, 12),
          end: DateTime(2026, 9, 20),
        ),
      );
      expect(dateFilter.matchesIsar(tx1), isFalse);
      expect(dateFilter.matchesIsar(tx2), isTrue);

      // Combined criteria
      final combined = TransactionFilterCriteria(
        accountIds: {20},
        categoryIds: {200},
        minAmount: 2000.0,
      );
      expect(combined.matchesIsar(tx2), isTrue);
      expect(combined.activeFilterCount, 3);
    });

    test('Evaluates TransactionModel filtering accurately', () {
      final model = TransactionModel(
        id: 'txn-1',
        title: 'MacBook Charger',
        amount: 3500.0,
        flow: TransactionFlow.expense,
        category: 'Electronics',
        date: DateTime(2026, 9, 14),
        accountId: 'acc-1',
      );

      final filter = TransactionFilterCriteria(
        minAmount: 2000.0,
        maxAmount: 5000.0,
        dateRange: DateTimeRange(
          start: DateTime(2026, 9, 1),
          end: DateTime(2026, 9, 30),
        ),
      );

      expect(filter.matchesModel(model), isTrue);

      final failingFilter = filter.copyWith(maxAmount: 1000.0);
      expect(failingFilter.matchesModel(model), isFalse);
    });
  });

  group('Phase 42: Filter Bottom Sheet Widget Tests', () {
    final customAccounts = [
      Account()..id = 1..name = 'Salary Account',
      Account()..id = 2..name = 'Credit Card',
    ];

    final customCategories = [
      Category()..id = 101..name = 'Dining Out',
      Category()..id = 102..name = 'Groceries',
    ];

    testWidgets('Renders sections, toggles account & category filters, and applies result', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      TransactionFilterCriteria? appliedCriteria;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterBottomSheet(
              accounts: customAccounts,
              categories: customCategories,
              onApply: (criteria) {
                appliedCriteria = criteria;
              },
            ),
          ),
        ),
      );

      // Verify UI title and sections
      expect(find.byKey(const Key('filter_bottom_sheet')), findsOneWidget);
      expect(find.text('Filter Transactions'), findsOneWidget);
      expect(find.text('Salary Account'), findsOneWidget);
      expect(find.text('Dining Out'), findsOneWidget);

      // Tap account filter chip #1
      await tester.tap(find.byKey(const Key('account_filter_chip_1')));
      await tester.pumpAndSettle();

      // Tap category filter chip #102
      await tester.tap(find.byKey(const Key('category_filter_chip_102')));
      await tester.pumpAndSettle();

      // Enter Min and Max amounts
      await tester.enterText(find.byKey(const Key('min_amount_input')), '500');
      await tester.enterText(find.byKey(const Key('max_amount_input')), '5000');
      await tester.pumpAndSettle();

      // Tap quick date preset '30 Days'
      await tester.tap(find.text('30 Days'));
      await tester.pumpAndSettle();

      // Tap Apply Filters button
      expect(find.byKey(const Key('apply_filters_button')), findsOneWidget);
      await tester.tap(find.byKey(const Key('apply_filters_button')));
      await tester.pumpAndSettle();

      expect(appliedCriteria, isNotNull);
      expect(appliedCriteria!.accountIds, contains(1));
      expect(appliedCriteria!.categoryIds, contains(102));
      expect(appliedCriteria!.minAmount, 500.0);
      expect(appliedCriteria!.maxAmount, 5000.0);
      expect(appliedCriteria!.dateRange, isNotNull);
      expect(appliedCriteria!.activeFilterCount, 4);
    });

    testWidgets('Reset All button clears all selections', (tester) async {
      final initial = TransactionFilterCriteria(
        accountIds: {1},
        categoryIds: {101},
        minAmount: 100.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterBottomSheet(
              initialFilters: initial,
              accounts: customAccounts,
              categories: customCategories,
            ),
          ),
        ),
      );

      // Verify active badge
      expect(find.byKey(const Key('active_filters_count_badge')), findsOneWidget);

      // Tap Reset All
      await tester.tap(find.byKey(const Key('reset_filters_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('active_filters_count_badge')), findsNothing);
    });
  });
}
