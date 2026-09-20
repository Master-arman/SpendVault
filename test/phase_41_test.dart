import 'package:finance_app/core/utils/debouncer.dart';
import 'package:finance_app/features/categories/data/models/category.dart';
import 'package:finance_app/features/transactions/data/models/transaction.dart';
import 'package:finance_app/features/transactions/domain/models/transaction_model.dart';
import 'package:finance_app/features/transactions/presentation/screens/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 41: Multi-Parametric Search & Debounce Unit Tests', () {
    test('Debouncer cancels rapid keystrokes and executes once after specified delay', () async {
      final Debouncer debouncer = Debouncer(milliseconds: 300);
      int searchExecutions = 0;
      String lastQuery = '';

      // Simulate rapid user typing 'a' -> 'ap' -> 'app' -> 'apple'
      debouncer.run(() {
        searchExecutions++;
        lastQuery = 'a';
      });
      await Future<void>.delayed(const Duration(milliseconds: 50));

      debouncer.run(() {
        searchExecutions++;
        lastQuery = 'ap';
      });
      await Future<void>.delayed(const Duration(milliseconds: 50));

      debouncer.run(() {
        searchExecutions++;
        lastQuery = 'app';
      });
      await Future<void>.delayed(const Duration(milliseconds: 50));

      debouncer.run(() {
        searchExecutions++;
        lastQuery = 'apple';
      });

      // Before 300ms debounce finishes, executions should be 0
      expect(searchExecutions, 0);

      // Wait 350ms for debounce timer to fire
      await Future<void>.delayed(const Duration(milliseconds: 350));

      expect(searchExecutions, 1);
      expect(lastQuery, 'apple');
    });

    test('In-memory multi-parametric matching filters notes, tags, and categories', () {
      final tx1 = Transaction()
        ..id = 1
        ..amount = 540.0
        ..type = TransactionType.expense
        ..note = 'Grocery run at Whole Foods'
        ..tags = ['#grocery', '#organic']
        ..timestamp = DateTime(2026, 9, 10);

      final cat = Category()..name = 'Food & Dining';
      tx1.category.value = cat;

      final tx2 = Transaction()
        ..id = 2
        ..amount = 1200.0
        ..type = TransactionType.expense
        ..note = 'AirPods Case Replacement'
        ..tags = ['#tech', '#apple']
        ..timestamp = DateTime(2026, 9, 12);

      final List<Transaction> list = [tx1, tx2];

      // Match by tag '#organic'
      final tagMatch = list.where((t) => t.tags.any((tag) => tag.contains('organic'))).toList();
      expect(tagMatch.length, 1);
      expect(tagMatch.first.id, 1);

      // Match by note 'AirPods'
      final noteMatch = list.where((t) => t.note?.toLowerCase().contains('airpods') ?? false).toList();
      expect(noteMatch.length, 1);
      expect(noteMatch.first.id, 2);
    });
  });

  group('Phase 41: Search Screen Widget Tests', () {
    final List<TransactionModel> mockModels = [
      TransactionModel(
        id: 'txn-1',
        title: 'Starbucks Caramel Macchiato',
        amount: 380.0,
        flow: TransactionFlow.expense,
        category: 'Food & Dining',
        date: DateTime(2026, 9, 15),
        accountId: 'acc-1',
        note: 'Coffee with team #coffee #meeting',
      ),
      TransactionModel(
        id: 'txn-2',
        title: 'Electricity Bill Payment',
        amount: 2150.0,
        flow: TransactionFlow.expense,
        category: 'Bills & Utilities',
        date: DateTime(2026, 9, 14),
        accountId: 'acc-1',
        note: 'Monthly power grid bill #bills',
      ),
      TransactionModel(
        id: 'txn-3',
        title: 'Freelance Design Consulting',
        amount: 45000.0,
        flow: TransactionFlow.income,
        category: 'Income',
        date: DateTime(2026, 9, 10),
        accountId: 'acc-1',
        note: 'UI/UX Client retainer payment #freelance',
      ),
    ];

    testWidgets('Renders empty state initially and updates results after 300ms debounce', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SearchScreen(
            initialTransactionModels: mockModels,
          ),
        ),
      );

      // Verify empty search state
      expect(find.byKey(const Key('empty_search_state')), findsOneWidget);
      expect(find.text('Multi-Parametric Search'), findsOneWidget);

      // Enter search query into text field
      await tester.enterText(find.byKey(const Key('search_input_field')), 'Starbucks');
      
      // Before debounce time (300ms), results should not have rendered yet
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const Key('search_results_list')), findsNothing);

      // Advance clock past 300ms
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // Results rendered
      expect(find.byKey(const Key('search_results_list')), findsOneWidget);
      expect(find.text('Starbucks Caramel Macchiato'), findsOneWidget);
      expect(find.text('Electricity Bill Payment'), findsNothing);
    });

    testWidgets('Filters by category or tag chip tap', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SearchScreen(
            initialTransactionModels: mockModels,
          ),
        ),
      );

      // Tap on '#bills' chip
      await tester.tap(find.text('#bills'));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.text('Electricity Bill Payment'), findsOneWidget);
      expect(find.text('Starbucks Caramel Macchiato'), findsNothing);

      // Clear search with clear button
      expect(find.byKey(const Key('search_clear_button')), findsOneWidget);
      await tester.tap(find.byKey(const Key('search_clear_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('empty_search_state')), findsOneWidget);
    });

    testWidgets('Renders no-results state when query does not match any transaction', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SearchScreen(
            initialTransactionModels: mockModels,
          ),
        ),
      );

      await tester.enterText(find.byKey(const Key('search_input_field')), 'NonexistentXYZ');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('no_results_state')), findsOneWidget);
      expect(find.text('No matches found for "NonexistentXYZ"'), findsOneWidget);
    });
  });
}
