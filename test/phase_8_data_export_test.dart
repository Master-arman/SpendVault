import 'dart:io';
import 'package:finance_app/core/theme/app_theme.dart';
import 'package:finance_app/features/reports/domain/csv_exporter.dart';
import 'package:finance_app/features/reports/domain/pdf_statement_generator.dart';
import 'package:finance_app/features/reports/presentation/widgets/export_report_bottom_sheet.dart';
import 'package:finance_app/features/transactions/domain/models/transaction_model.dart';
import 'package:finance_app/features/transactions/presentation/screens/dashboard_screen.dart';
import 'package:finance_app/features/transactions/presentation/screens/transactions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';

/// Test mock implementation of [IShareBridge]
class MockShareBridge implements IShareBridge {
  List<XFile>? lastSharedFiles;
  String? lastSubject;
  String? lastText;

  @override
  Future<ShareResult> shareXFiles(
    List<XFile> files, {
    String? text,
    String? subject,
  }) async {
    lastSharedFiles = files;
    lastSubject = subject;
    lastText = text;
    return const ShareResult('success', ShareResultStatus.success);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleTransactions = [
    TransactionModel(
      id: 'txn-101',
      title: 'Whole Foods Groceries',
      amount: 142.50,
      flow: TransactionFlow.expense,
      category: 'Groceries',
      date: DateTime(2026, 9, 21, 11, 30),
      accountId: 'acc-1',
      accountName: 'Chase Checking',
      merchant: 'Whole Foods Market',
      note: 'Weekly grocery restock',
    ),
    TransactionModel(
      id: 'txn-102',
      title: 'Salary Direct Deposit',
      amount: 4500.00,
      flow: TransactionFlow.income,
      category: 'Salary',
      date: DateTime(2026, 9, 20, 9, 0),
      accountId: 'acc-1',
      accountName: 'Chase Checking',
      merchant: 'Acme Corp Payroll',
      note: 'Monthly salary credit',
    ),
    TransactionModel(
      id: 'txn-103',
      title: 'Coffee & Chai',
      amount: 12.00,
      flow: TransactionFlow.expense,
      category: 'Food & Dining',
      date: DateTime(2026, 9, 19, 16, 45),
      accountId: 'acc-1',
      accountName: 'Chase Checking',
      merchant: 'Blue Tokai',
      note: 'Afternoon coffee',
    ),
  ];

  group('Phase 8: Data Export (PDF & CSV) Tests', () {
    late MockShareBridge mockShare;

    setUp(() {
      mockShare = MockShareBridge();
      CsvExporter.setShareBridgeForTesting(mockShare);
      PdfStatementGenerator.setShareBridgeForTesting(mockShare);

      const MethodChannel channel = MethodChannel('plugins.flutter.io/path_provider');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'getTemporaryDirectory') {
          return Directory.systemTemp.path;
        }
        return null;
      });
    });

    tearDown(() {
      CsvExporter.setShareBridgeForTesting(null);
      PdfStatementGenerator.setShareBridgeForTesting(null);
      const MethodChannel channel = MethodChannel('plugins.flutter.io/path_provider');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('CSV Logic: Converts transaction list to 2D array and generates valid CSV content', () {
      final rows = CsvExporter.buildCsvData(transactions: sampleTransactions);

      expect(rows.length, 4); // 1 header row + 3 transactions
      expect(rows[0], CsvExporter.csvHeaders);

      final csvString = CsvExporter.generateCsvString(transactions: sampleTransactions);
      expect(csvString, contains('Whole Foods Market'));
      expect(csvString, contains('4500.00'));
      expect(csvString, contains('Chase Checking'));
      expect(csvString, contains('Weekly grocery restock'));
    });

    test('CSV Export & Share: Writes CSV file and triggers native share sheet via shareXFiles', () async {
      final result = await CsvExporter.exportAndShare(
        transactions: sampleTransactions,
        filename: 'test_export.csv',
      );

      expect(result.status, ShareResultStatus.success);
      expect(mockShare.lastSharedFiles, isNotNull);
      expect(mockShare.lastSharedFiles!.length, 1);
      expect(mockShare.lastSharedFiles!.first.path, contains('test_export.csv'));
      expect(mockShare.lastSharedFiles!.first.mimeType, 'text/csv');
    });

    test('PDF Logic: Generates branded PDF statement with summary metrics and table rows', () async {
      final doc = await PdfStatementGenerator.generateDocument(
        transactions: sampleTransactions,
        accountName: 'Executive Portfolio',
      );

      final pdfBytes = await doc.save();
      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(1000));
    });

    test('PDF Export & Share: Writes PDF file and triggers native share sheet via shareXFiles', () async {
      final result = await PdfStatementGenerator.exportAndShare(
        transactions: sampleTransactions,
        filename: 'test_statement.pdf',
        accountName: 'Executive Portfolio',
      );

      expect(result.status, ShareResultStatus.success);
      expect(mockShare.lastSharedFiles, isNotNull);
      expect(mockShare.lastSharedFiles!.length, 1);
      expect(mockShare.lastSharedFiles!.first.path, contains('test_statement.pdf'));
      expect(mockShare.lastSharedFiles!.first.mimeType, 'application/pdf');
    });

    testWidgets('ExportReportBottomSheet renders format options and triggers PDF export callback',
        (WidgetTester tester) async {
      ExportFormat? exportedFormat;
      File? exportedFile;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: ExportReportBottomSheet(
              initialTransactions: sampleTransactions,
              onExportComplete: (format, file) async {
                exportedFormat = format;
                exportedFile = file;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('export_report_bottom_sheet')), findsOneWidget);
      expect(find.byKey(const Key('export_format_pdf')), findsOneWidget);
      expect(find.byKey(const Key('export_format_csv')), findsOneWidget);
      expect(find.text('3 Transactions'), findsOneWidget);

      // Tap Export & Share button inside runAsync
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('export_submit_button')));
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();

      expect(exportedFormat, ExportFormat.pdf);
      expect(exportedFile, isNotNull);
      expect(exportedFile!.path, contains('.pdf'));
    });

    testWidgets('ExportReportBottomSheet allows switching to CSV format and exports CSV file',
        (WidgetTester tester) async {
      ExportFormat? exportedFormat;
      File? exportedFile;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: ExportReportBottomSheet(
              initialTransactions: sampleTransactions,
              onExportComplete: (format, file) async {
                exportedFormat = format;
                exportedFile = file;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to CSV
      await tester.tap(find.byKey(const Key('export_format_csv')));
      await tester.pumpAndSettle();

      // Submit export inside runAsync
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('export_submit_button')));
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();

      expect(exportedFormat, ExportFormat.csv);
      expect(exportedFile, isNotNull);
      expect(exportedFile!.path, contains('.csv'));
    });

    testWidgets('DashboardScreen Fast Action "Export Report" opens ExportReportBottomSheet',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const DashboardScreen(disableTour: true),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Export Report'), findsOneWidget);
      await tester.tap(find.text('Export Report'));
      await tester.pumpAndSettle();

      expect(find.byType(ExportReportBottomSheet), findsOneWidget);
      expect(find.text('Export Data & Statements'), findsOneWidget);
    });

    testWidgets('TransactionsScreen AppBar Export button opens ExportReportBottomSheet',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const TransactionsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('button_export_transactions')), findsOneWidget);
      await tester.tap(find.byKey(const Key('button_export_transactions')));
      await tester.pumpAndSettle();

      expect(find.byType(ExportReportBottomSheet), findsOneWidget);
    });
  });
}
