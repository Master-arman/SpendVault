import 'package:finance_app/features/accounts/data/models/account.dart';
import 'package:finance_app/features/accounts/presentation/widgets/account_carousel_3d.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 4: Multi-Account Ledger Schema Tests', () {
    test('Account model correctly holds all schema properties', () {
      final account = Account()
        ..name = 'HDFC Salary'
        ..currentBalance = 48500.50
        ..type = AccountType.bank
        ..last4Digits = '4592'
        ..colorHex = 0xFF4F46E5
        ..isDefault = true;

      expect(account.name, 'HDFC Salary');
      expect(account.currentBalance, 48500.50);
      expect(account.type, AccountType.bank);
      expect(account.last4Digits, '4592');
      expect(account.colorHex, 0xFF4F46E5);
      expect(account.isDefault, isTrue);
    });

    testWidgets('AccountCarousel3D renders accounts with 3D tilt transform and PageView',
        (WidgetTester tester) async {
      final accounts = [
        Account()
          ..name = 'HDFC Salary'
          ..currentBalance = 12400.00
          ..type = AccountType.bank
          ..last4Digits = '4592'
          ..colorHex = 0xFF4F46E5
          ..isDefault = true,
        Account()
          ..name = 'SBI Savings'
          ..currentBalance = 18950.00
          ..type = AccountType.bank
          ..last4Digits = '8821'
          ..colorHex = 0xFF0D9488
          ..isDefault = false,
      ];

      Account? selected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccountCarousel3D(
              accounts: accounts,
              onAccountSelected: (acc) => selected = acc,
            ),
          ),
        ),
      );

      expect(find.byType(PageView), findsOneWidget);
      expect(find.text('HDFC Salary'), findsOneWidget);

      // Verify Transform 3D tilt exists
      expect(find.byType(Transform), findsWidgets);

      // Tap on the first card
      await tester.tap(find.text('HDFC Salary'));
      await tester.pumpAndSettle();

      expect(selected, isNotNull);
      expect(selected!.name, 'HDFC Salary');
    });
  });
}
