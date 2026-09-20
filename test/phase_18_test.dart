import 'package:finance_app/features/transactions/domain/bill_split_calculator.dart';
import 'package:finance_app/features/transactions/presentation/screens/split_bill_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 18: Bill Splitting & Group Reimbursements Tests', () {
    test('Debt calculation correctly computes User Share (B/N) and Lent Amount (B - B/N)', () {
      const double totalBill = 120.0;
      const int participants = 4;

      final result = BillSplitCalculator.calculate(
        totalBill: totalBill,
        participantsCount: participants,
      );

      // User Share = B / N = 120 / 4 = 30.0
      expect(result.userShare, 30.0);
      // Lent Amount = B - (B / N) = 120 - 30 = 90.0
      expect(result.lentAmount, 90.0);
      expect(result.perPersonShare, 30.0);
      expect(result.tags, containsAll(['#split', '#reimbursable']));
    });

    test('Reimbursement payback reduces food/entertainment expense bucket directly', () {
      const double initialExpense = 200.0;
      const double reimbursement = 150.0;

      final remainingExpense = BillSplitCalculator.applyReimbursementToExpenseBucket(
        currentExpenseTotal: initialExpense,
        reimbursementAmount: reimbursement,
      );

      // Direct offset against original expense bucket
      expect(remainingExpense, 50.0);
    });

    testWidgets('SplitBillScreen renders calculations, auto-tags, and participant settlement controls',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SplitBillScreen(
            initialBillAmount: 120.0,
            initialParticipants: 4,
            categoryName: 'Food & Dining',
          ),
        ),
      );

      expect(find.text('Split Bill & Reimburse'), findsOneWidget);
      expect(find.text('YOUR SHARE'), findsOneWidget);
      expect(find.text('LENT AMOUNT'), findsOneWidget);
      expect(find.text('₹30.00'), findsWidgets); // User Share
      expect(find.text('₹90.00'), findsOneWidget); // Lent Amount
      expect(find.text('#split'), findsOneWidget);
      expect(find.text('#reimbursable'), findsOneWidget);

      // Verify participants list
      expect(find.text('You (Host)'), findsOneWidget);
      expect(find.text('Participant 1'), findsOneWidget);
      expect(find.text('Mark Paid'), findsWidgets);

      // Scroll to make sure Mark Paid is visible in SingleChildScrollView
      await tester.ensureVisible(find.text('Mark Paid').first);
      await tester.pumpAndSettle();

      // Tap Mark Paid for Participant 1
      await tester.tap(find.text('Mark Paid').first);
      await tester.pumpAndSettle();

      expect(find.text('Settled'), findsWidgets);
    });
  });
}
