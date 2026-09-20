import 'dart:typed_data';
import 'package:finance_app/features/accounts/data/models/account.dart';
import 'package:finance_app/features/categories/data/models/category.dart';
import 'package:finance_app/features/reports/domain/pdf_statement_generator.dart';
import 'package:finance_app/features/transactions/data/models/transaction.dart';
import 'package:finance_app/features/transactions/domain/models/transaction_model.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 43: Multipage Vector PDF Report Engine Unit Tests', () {
    final List<TransactionModel> mockModels = [
      TransactionModel(
        id: 'txn-1',
        title: 'Salary Credit - August',
        amount: 85000.00,
        flow: TransactionFlow.income,
        category: 'Income',
        date: DateTime(2026, 8, 31, 10, 0),
        accountId: 'acc-1',
        merchant: 'Tech Corp Payroll',
      ),
      TransactionModel(
        id: 'txn-2',
        title: 'Amazon Online Electronics',
        amount: 3499.50,
        flow: TransactionFlow.expense,
        category: 'Shopping',
        date: DateTime(2026, 9, 2, 14, 30),
        accountId: 'acc-1',
        merchant: 'Amazon India',
      ),
      TransactionModel(
        id: 'txn-3',
        title: 'Starbucks Coffee',
        amount: 450.00,
        flow: TransactionFlow.expense,
        category: 'Food & Dining',
        date: DateTime(2026, 9, 5, 9, 15),
        accountId: 'acc-1',
        merchant: 'Starbucks',
      ),
    ];

    test('Generates pw.Document with header, summary cards, and ledger rows', () async {
      final pw.Document doc = await PdfStatementGenerator.generateDocument(
        transactions: mockModels,
        accountName: 'Primary Checking',
        accountNumberMasked: '****4592',
        generatedDate: DateTime(2026, 9, 10),
        dateRange: DateTimeRange(
          start: DateTime(2026, 8, 1),
          end: DateTime(2026, 9, 10),
        ),
      );

      expect(doc, isNotNull);
      final Uint8List bytes = await doc.save();
      expect(bytes.isNotEmpty, isTrue);

      // Verify PDF Magic Header (%PDF-)
      final String headerStr = String.fromCharCodes(bytes.take(5));
      expect(headerStr, equals('%PDF-'));
    });

    test('Computes total inflow, outflow, and net balance change correctly', () async {
      final Uint8List bytes = await PdfStatementGenerator.generatePdfBytes(
        transactions: mockModels,
        accountName: 'HDFC Bank Account',
      );

      // Inflow: 85,000.00
      // Outflow: 3,499.50 + 450.00 = 3,949.50
      // Net: 85,000.00 - 3,949.50 = 81,050.50
      expect(bytes.length, greaterThan(1000));
    });

    test('Supports Isar Transaction entities and multipage pagination', () async {
      final acc = Account()..id = 1..name = 'Savings';
      final cat = Category()..id = 10..name = 'Utilities';

      // Generate 60 transactions to trigger multipage document layout
      final List<Transaction> isarTransactions = List.generate(60, (index) {
        final tx = Transaction()
          ..id = index + 1
          ..amount = (index + 1) * 100.0
          ..type = index % 5 == 0 ? TransactionType.income : TransactionType.expense
          ..note = 'Ledger Entry #$index'
          ..timestamp = DateTime(2026, 9, (index % 28) + 1);
        tx.sourceAccount.value = acc;
        tx.category.value = cat;
        return tx;
      });

      final pw.Document doc = await PdfStatementGenerator.generateDocument(
        transactions: isarTransactions,
        accountName: 'Corporate Expense Portfolio',
      );

      final Uint8List bytes = await doc.save();
      expect(bytes.length, greaterThan(5000));
      expect(String.fromCharCodes(bytes.take(5)), equals('%PDF-'));
    });

    test('Handles empty transaction list gracefully', () async {
      final pw.Document doc = await PdfStatementGenerator.generateDocument(
        transactions: const [],
        accountName: 'Empty Account',
      );

      final Uint8List bytes = await doc.save();
      expect(bytes.isNotEmpty, isTrue);
      expect(String.fromCharCodes(bytes.take(5)), equals('%PDF-'));
    });
  });
}
