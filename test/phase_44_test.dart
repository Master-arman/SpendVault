import 'dart:convert';
import 'package:cross_file/cross_file.dart';
import 'package:finance_app/features/accounts/data/models/account.dart';
import 'package:finance_app/features/categories/data/models/category.dart';
import 'package:finance_app/features/reports/domain/csv_exporter.dart';
import 'package:finance_app/features/transactions/data/models/transaction.dart';
import 'package:finance_app/features/transactions/domain/models/transaction_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';

class MockShareBridge implements IShareBridge {
  List<XFile> sharedFiles = [];
  String? sharedSubject;
  String? sharedText;

  @override
  Future<ShareResult> shareXFiles(
    List<XFile> files, {
    String? text,
    String? subject,
  }) async {
    sharedFiles = files;
    sharedSubject = subject;
    sharedText = text;
    return const ShareResult('success', ShareResultStatus.success);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 44: Tabular CSV & Excel Spreadsheet Exporter Unit Tests', () {
    late MockShareBridge mockShareBridge;

    setUp(() {
      mockShareBridge = MockShareBridge();
      CsvExporter.setShareBridgeForTesting(mockShareBridge);
    });

    tearDown(() {
      CsvExporter.setShareBridgeForTesting(null);
    });

    test('CSV header matches required columns specification', () {
      expect(CsvExporter.csvHeaders, [
        'ID',
        'Timestamp',
        'Type',
        'Source Account',
        'Destination Account',
        'Category',
        'Amount',
        'Currency',
        'Tags',
        'Notes',
        'IsAutoDetected',
      ]);
    });

    test('Generates valid CSV string from TransactionModel list', () {
      final List<TransactionModel> models = [
        TransactionModel(
          id: 'txn-1',
          title: 'Starbucks Coffee, Downtown',
          amount: 380.50,
          flow: TransactionFlow.expense,
          category: 'Food & Dining',
          date: DateTime(2026, 9, 15, 14, 30),
          accountId: 'acc-1',
          accountName: 'Checking HDFC',
          note: 'Meeting with team, coffee & snacks',
          isAutomated: true,
        ),
        TransactionModel(
          id: 'txn-2',
          title: 'Salary Deposit',
          amount: 75000.00,
          flow: TransactionFlow.income,
          category: 'Income',
          date: DateTime(2026, 9, 1, 9, 0),
          accountId: 'acc-1',
          accountName: 'Checking HDFC',
          note: 'August payroll',
        ),
      ];

      final String csv = CsvExporter.generateCsvString(
        transactions: models,
        currency: 'INR',
      );

      expect(csv, contains('ID,Timestamp,Type,Source Account'));
      expect(csv, contains('txn-1,2026-09-15 14:30:00,expense,Checking HDFC,N/A,Food & Dining,380.50,INR,#auto,"Meeting with team, coffee & snacks",true'));
      expect(csv, contains('txn-2,2026-09-01 09:00:00,income,Checking HDFC,N/A,Income,75000.00,INR,,August payroll,false'));
    });

    test('Generates valid CSV string from Isar Transaction entities', () {
      final src = Account()..id = 1..name = 'Savings SBI';
      final dest = Account()..id = 2..name = 'ICICI Card';
      final cat = Category()..id = 10..name = 'Credit Card Bill';

      final tx = Transaction()
        ..id = 42
        ..amount = 12500.00
        ..type = TransactionType.transfer
        ..timestamp = DateTime(2026, 9, 18, 11, 20)
        ..tags = ['#card', '#transfer']
        ..note = 'Bill clearance'
        ..deduplicationHash = 'hash-abc-123';
      tx.sourceAccount.value = src;
      tx.destinationAccount.value = dest;
      tx.category.value = cat;

      final String csv = CsvExporter.generateCsvString(
        transactions: [tx],
        currency: 'INR',
      );

      expect(csv, contains('42,2026-09-18 11:20:00,transfer,Savings SBI,ICICI Card,Credit Card Bill,12500.00,INR,#card; #transfer,Bill clearance,true'));
    });

    test('exportAndShare prepares XFile and triggers share sheet via bridge', () async {
      final List<TransactionModel> models = [
        TransactionModel(
          id: 'txn-100',
          title: 'Uber Ride',
          amount: 450.00,
          flow: TransactionFlow.expense,
          category: 'Transport',
          date: DateTime(2026, 9, 19, 18, 0),
          accountId: 'acc-1',
        ),
      ];

      final result = await CsvExporter.exportAndShare(
        transactions: models,
        filename: 'statement.csv',
        subject: 'Monthly Ledger',
      );

      expect(result.status, ShareResultStatus.success);
      expect(mockShareBridge.sharedFiles.length, 1);
      expect(mockShareBridge.sharedFiles.first.name, 'statement.csv');
      expect(mockShareBridge.sharedSubject, 'Monthly Ledger');

      final String sharedContent = utf8.decode(await mockShareBridge.sharedFiles.first.readAsBytes());
      expect(sharedContent, contains('txn-100,2026-09-19 18:00:00,expense'));
    });
  });
}
