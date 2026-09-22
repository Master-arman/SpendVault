import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:finance_app/core/constants/app_constants.dart';
import 'package:finance_app/features/transactions/data/models/transaction.dart';
import 'package:finance_app/features/transactions/domain/models/transaction_model.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Abstract bridge for triggering share actions (enables effortless mocking in unit tests).
abstract class IShareBridge {
  Future<ShareResult> shareXFiles(
    List<XFile> files, {
    String? text,
    String? subject,
  });
}

/// Default production share bridge invoking [Share.shareXFiles].
class DefaultShareBridge implements IShareBridge {
  const DefaultShareBridge();

  @override
  Future<ShareResult> shareXFiles(
    List<XFile> files, {
    String? text,
    String? subject,
  }) {
    return Share.shareXFiles(
      files,
      text: text,
      subject: subject,
    );
  }
}

/// Phase 44: Tabular CSV & Excel Spreadsheet Exporter.
///
/// Exports structured transaction ledger records to standard CSV format
/// with designated columns:
/// `ID, Timestamp, Type, Source Account, Destination Account, Category, Amount, Currency, Tags, Notes, IsAutoDetected`
class CsvExporter {
  const CsvExporter._();

  static IShareBridge _shareBridge = const DefaultShareBridge();

  /// Overrides the share bridge for unit testing.
  static void setShareBridgeForTesting(IShareBridge? bridge) {
    _shareBridge = bridge ?? const DefaultShareBridge();
  }

  /// Defined CSV Header columns according to specifications.
  static const List<String> csvHeaders = [
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
  ];

  /// Transforms raw transaction entities into 2D tabular rows.
  static List<List<dynamic>> buildCsvData({
    required List<dynamic> transactions,
    String currency = AppConstants.defaultCurrencyCode,
  }) {
    final DateFormat isoFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
    final List<List<dynamic>> rows = [csvHeaders];

    for (final dynamic item in transactions) {
      if (item is Transaction) {
        final String id = item.id.toString();
        final String timestamp = isoFormat.format(item.timestamp);
        final String type = item.type.name;
        final String srcAccount = item.sourceAccount.value?.name ?? 'Primary Account';
        final String destAccount = item.type == TransactionType.transfer
            ? (item.destinationAccount.value?.name ?? 'Destination Account')
            : 'N/A';
        final String category = item.category.value?.name ?? 'General';
        final String amount = item.amount.toStringAsFixed(2);
        final String tags = item.tags.join('; ');
        final String notes = item.note ?? '';
        final bool isAutoDetected = item.deduplicationHash != null;

        rows.add([
          id,
          timestamp,
          type,
          srcAccount,
          destAccount,
          category,
          amount,
          currency,
          tags,
          notes,
          isAutoDetected,
        ]);
      } else if (item is TransactionModel) {
        final String id = item.id;
        final String timestamp = isoFormat.format(item.date);
        final String type = item.flow.name;
        final String srcAccount = item.accountName;
        final String destAccount = item.flow == TransactionFlow.transfer ? 'Destination Account' : 'N/A';
        final String category = item.category;
        final String amount = item.amount.toStringAsFixed(2);
        final String tags = item.isAutomated ? '#auto' : '';
        final String notes = item.merchant != null && item.merchant!.isNotEmpty && item.merchant != item.title
            ? '${item.merchant} - ${item.note ?? item.title}'
            : (item.note ?? item.title);
        final bool isAutoDetected = item.isAutomated;

        rows.add([
          id,
          timestamp,
          type,
          srcAccount,
          destAccount,
          category,
          amount,
          currency,
          tags,
          notes,
          isAutoDetected,
        ]);
      }
    }

    return rows;
  }

  /// Converts tabular data into RFC 4180 compliant CSV string buffer.
  static String generateCsvString({
    required List<dynamic> transactions,
    String currency = AppConstants.defaultCurrencyCode,
  }) {
    final List<List<dynamic>> rows = buildCsvData(
      transactions: transactions,
      currency: currency,
    );

    return const ListToCsvConverter().convert(rows);
  }

  /// Writes CSV string to a local temporary or document file.
  static Future<File> writeCsvFile({
    required List<dynamic> transactions,
    String filename = 'transactions_export.csv',
    String currency = AppConstants.defaultCurrencyCode,
    Directory? directory,
  }) async {
    final String csvContent = generateCsvString(
      transactions: transactions,
      currency: currency,
    );

    final Directory dir = directory ?? await getTemporaryDirectory();
    final File file = File('${dir.path}/$filename');
    return await file.writeAsString(csvContent, encoding: utf8);
  }

  /// Generates CSV file and triggers system share sheet via [Share.shareXFiles].
  static Future<ShareResult> exportAndShare({
    required List<dynamic> transactions,
    String filename = 'transactions_export.csv',
    String currency = AppConstants.defaultCurrencyCode,
    String subject = 'SpendVault Transaction Ledger Export',
    String? text = 'Attached is your exported financial transaction ledger.',
  }) async {
    final File file = await writeCsvFile(
      transactions: transactions,
      filename: filename,
      currency: currency,
    );

    final XFile xFile = XFile(
      file.path,
      mimeType: 'text/csv',
      name: filename,
    );

    return await _shareBridge.shareXFiles(
      [xFile],
      subject: subject,
      text: text,
    );
  }
}
