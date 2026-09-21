import 'package:finance_app/core/constants/app_constants.dart';
import 'package:finance_app/features/transactions/domain/models/transaction_model.dart';
import 'package:finance_app/features/transactions/presentation/screens/dashboard_screen.dart';
import 'package:finance_app/features/transactions/presentation/screens/split_bill_screen.dart';
import 'package:finance_app/features/transactions/presentation/widgets/split_bill_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 7: Split Bills Feature Tests', () {
    testWidgets('Splitting ₹900 equally across 3 people displays ₹300 per person',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SplitBillDialog(
              initialTotalAmount: 900.0,
              initialTitle: 'Dinner',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('split_bill_dialog')), findsOneWidget);
      expect(find.byKey(const Key('split_total_amount_field')), findsOneWidget);

      // Verify ₹300.00 per person is rendered
      expect(find.text('₹300.00'), findsWidgets);
    });

    testWidgets('Adding person dynamically updates per person share',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SplitBillDialog(
              initialTotalAmount: 1000.0,
              initialTitle: 'Brunch',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially 3 people: 1000 / 3 = 333.33
      expect(find.text('₹333.33'), findsWidgets);

      // Tap Add Person -> 4 people: 1000 / 4 = 250.00
      await tester.tap(find.byKey(const Key('split_add_person_button')));
      await tester.pumpAndSettle();

      expect(find.text('₹250.00'), findsWidgets);
      expect(find.text('Share Per Person (4 people)'), findsOneWidget);
    });

    testWidgets('Tapping Share Summary generates formatted summary message and triggers share callback',
        (WidgetTester tester) async {
      String? generatedShareText;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SplitBillDialog(
              initialTotalAmount: 900.0,
              initialTitle: 'Dinner',
              onShareCallback: (summary) async {
                generatedShareText = summary;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll & Tap Share Summary
      await tester.ensureVisible(find.byKey(const Key('split_share_summary_button')));
      await tester.tap(find.byKey(const Key('split_share_summary_button')));
      await tester.pumpAndSettle();

      expect(generatedShareText, isNotNull);
      expect(generatedShareText, contains('Bill Split: Dinner'));
      expect(generatedShareText, contains('Total Bill: ₹900.00'));
      expect(generatedShareText, contains('You owe ₹300.00 for Dinner.'));
    });

    testWidgets('SplitBillDialog saves host share to transaction ledger',
        (WidgetTester tester) async {
      TransactionModel? savedTxn;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SplitBillDialog(
              initialTotalAmount: 900.0,
              initialTitle: 'Dinner',
              onSaved: (txn) async {
                savedTxn = txn;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll & Tap Save to Ledger
      await tester.ensureVisible(find.byKey(const Key('split_save_button')));
      await tester.tap(find.byKey(const Key('split_save_button')));
      await tester.pumpAndSettle();

      expect(savedTxn, isNotNull);
      expect(savedTxn!.amount, equals(300.0));
      expect(savedTxn!.title, equals('Dinner (Split)'));
      expect(savedTxn!.flow, equals(TransactionFlow.expense));
    });

    testWidgets('DashboardScreen Fast Action "Split Bill" triggers navigation to SplitBillScreen',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: {
            AppConstants.splitBillRoute: (_) => const SplitBillScreen(),
          },
          home: const DashboardScreen(disableTour: true),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Split Bill'), findsOneWidget);
      await tester.tap(find.text('Split Bill'));
      await tester.pumpAndSettle();

      expect(find.text('Split Bill & Reimburse'), findsOneWidget);
    });
  });
}
