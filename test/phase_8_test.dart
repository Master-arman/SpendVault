import 'package:finance_app/features/transactions/data/models/transaction.dart';
import 'package:finance_app/features/transactions/presentation/widgets/transaction_type_toggle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 8: Sliding Segmented Transaction Toggle Tests', () {
    testWidgets('TransactionTypeToggle renders all 3 segments and handles selection changes',
        (WidgetTester tester) async {
      TransactionType current = TransactionType.expense;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return TransactionTypeToggle(
                  selectedType: current,
                  onChanged: (newType) {
                    setState(() {
                      current = newType;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      // Verify labels exist
      expect(find.text('Expense'), findsOneWidget);
      expect(find.text('Income'), findsOneWidget);
      expect(find.text('Transfer'), findsOneWidget);

      // Verify AnimatedAlign configuration
      final animatedAlignFinder = find.byType(AnimatedAlign);
      expect(animatedAlignFinder, findsOneWidget);
      final animatedAlignWidget = tester.widget<AnimatedAlign>(animatedAlignFinder);
      expect(animatedAlignWidget.duration, const Duration(milliseconds: 220));
      expect(animatedAlignWidget.curve, Curves.easeOutCubic);
      expect(animatedAlignWidget.alignment, Alignment.centerLeft);

      // Tap Income
      await tester.tap(find.text('Income'));
      await tester.pump();
      expect(current, TransactionType.income);

      await tester.pumpAndSettle();
      final updatedAlignIncome = tester.widget<AnimatedAlign>(animatedAlignFinder);
      expect(updatedAlignIncome.alignment, Alignment.center);

      // Tap Transfer
      await tester.tap(find.text('Transfer'));
      await tester.pump();
      expect(current, TransactionType.transfer);

      await tester.pumpAndSettle();
      final updatedAlignTransfer = tester.widget<AnimatedAlign>(animatedAlignFinder);
      expect(updatedAlignTransfer.alignment, Alignment.centerRight);
    });
  });
}
