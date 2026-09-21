import 'package:finance_app/core/constants/app_constants.dart';
import 'package:finance_app/features/automation/presentation/screens/scan_message_screen.dart';
import 'package:finance_app/features/automation/presentation/widgets/confirm_transaction_dialog.dart';
import 'package:finance_app/features/transactions/domain/models/transaction_model.dart';
import 'package:finance_app/features/transactions/presentation/screens/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 5: Scan Message (SMS Parser / OCR) Pipeline Tests', () {
    test('Regex correctly extracts currency amounts from diverse SMS patterns', () {
      final RegExp regex = RegExp(r'(?:INR|Rs\.?|₹|\$|€|£)\s*([\d,]+\.?\d*)', caseSensitive: false);

      const sms1 = 'Dear Customer, INR 75,000.00 credited to your A/C ending XX1234 on 21-Sep-2026';
      final match1 = regex.firstMatch(sms1);
      expect(match1, isNotNull);
      expect(match1!.group(1), equals('75,000.00'));

      const sms2 = 'Your A/C XX4321 was debited with Rs. 1420.00 at Whole Foods Market';
      final match2 = regex.firstMatch(sms2);
      expect(match2, isNotNull);
      expect(match2!.group(1), equals('1420.00'));

      const sms3 = 'Sent ₹ 450.00 from A/C XX5678 to Swiggy UPI';
      final match3 = regex.firstMatch(sms3);
      expect(match3, isNotNull);
      expect(match3!.group(1), equals('450.00'));
    });

    testWidgets('ScanMessageScreen renders input area, parse button, and quick presets',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ScanMessageScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('scan_message_screen')), findsOneWidget);
      expect(find.byKey(const Key('scan_message_input')), findsOneWidget);
      expect(find.byKey(const Key('parse_message_button')), findsOneWidget);
      expect(find.text('Quick Test SMS Presets'), findsOneWidget);
      expect(find.text('Salary Deposit'), findsOneWidget);
      expect(find.text('Whole Foods Market'), findsOneWidget);
    });

    testWidgets('Tapping a preset parses message and opens ConfirmTransactionDialog with pre-filled values',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ScanMessageScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on the Whole Foods Market preset
      await tester.tap(find.text('Whole Foods Market'));
      await tester.pumpAndSettle();

      // Verify ConfirmTransactionDialog is shown
      expect(find.byKey(const Key('confirm_transaction_dialog')), findsOneWidget);
      expect(find.text('Confirm Transaction'), findsOneWidget);

      // Verify pre-filled amount and title
      final amountField = tester.widget<TextField>(find.byKey(const Key('confirm_transaction_amount_field')));
      expect(amountField.controller?.text, equals('1420.00'));

      final titleField = tester.widget<TextField>(find.byKey(const Key('confirm_transaction_title_field')));
      expect(titleField.controller?.text, equals('Whole Foods Market'));
    });

    testWidgets('ConfirmTransactionDialog saves confirmed transaction to state/repository',
        (WidgetTester tester) async {
      TransactionModel? savedTxn;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  ConfirmTransactionDialog.show(
                    context: context,
                    initialAmount: 75000.0,
                    initialTitle: 'Salary Deposit',
                    initialCategory: 'Income',
                    initialFlow: TransactionFlow.income,
                    onConfirm: (txn) async {
                      savedTxn = txn;
                    },
                  );
                },
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open Modal
      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('confirm_transaction_dialog')), findsOneWidget);
      expect(find.text('Confirm & Save'), findsOneWidget);

      // Tap Confirm & Save
      await tester.tap(find.byKey(const Key('confirm_transaction_save_button')));
      await tester.pumpAndSettle();

      // Verify dialog dismissed and onConfirm called with correct model
      expect(find.byKey(const Key('confirm_transaction_dialog')), findsNothing);
      expect(savedTxn, isNotNull);
      expect(savedTxn!.amount, equals(75000.0));
      expect(savedTxn!.title, equals('Salary Deposit'));
      expect(savedTxn!.flow, equals(TransactionFlow.income));
    });

    testWidgets('DashboardScreen Fast Action "Scan SMS" triggers navigation to ScanMessageScreen',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: {
            AppConstants.scanMessageRoute: (_) => const ScanMessageScreen(),
          },
          home: const DashboardScreen(disableTour: true),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Fast Action "Scan SMS"
      expect(find.text('Scan SMS'), findsOneWidget);
      await tester.tap(find.text('Scan SMS'));
      await tester.pumpAndSettle();

      // Verify navigated to ScanMessageScreen
      expect(find.byKey(const Key('scan_message_screen')), findsOneWidget);
      expect(find.text('Scan Message / SMS'), findsOneWidget);
    });
  });
}
