import 'dart:typed_data';
import 'package:finance_app/core/constants/app_constants.dart';
import 'package:finance_app/features/transactions/data/models/transaction.dart';
import 'package:finance_app/features/transactions/domain/models/transaction_model.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Representation of a single transaction entry in the PDF ledger.
class PdfStatementItem {
  const PdfStatementItem({
    required this.date,
    required this.payee,
    required this.category,
    required this.paymentMode,
    required this.amount,
    required this.isExpense,
  });

  final DateTime date;
  final String payee;
  final String category;
  final String paymentMode;
  final double amount;
  final bool isExpense;

  factory PdfStatementItem.fromIsar(Transaction tx) {
    final String payee = tx.note?.isNotEmpty == true
        ? tx.note!
        : (tx.category.value?.name ?? 'General Transaction');
    final String catName = tx.category.value?.name ?? 'General';
    final String mode = tx.type == TransactionType.transfer
        ? 'Internal Transfer'
        : (tx.sourceAccount.value?.name ?? 'Bank Account');

    return PdfStatementItem(
      date: tx.timestamp,
      payee: payee,
      category: catName,
      paymentMode: mode,
      amount: tx.amount,
      isExpense: tx.type == TransactionType.expense,
    );
  }

  factory PdfStatementItem.fromModel(TransactionModel model) {
    return PdfStatementItem(
      date: model.date,
      payee: model.merchant?.isNotEmpty == true ? model.merchant! : model.title,
      category: model.category,
      paymentMode: model.accountName,
      amount: model.amount,
      isExpense: model.isExpense,
    );
  }
}

/// Phase 43: Multipage Vector PDF Report Engine.
///
/// Generates production-grade multipage financial statements with:
/// - Header: Title, generated date, active account name, currency format.
/// - Summary Cards: Total Inflow, Total Outflow, Net Balance Change.
/// - Transaction Ledger: Alternating dark-bordered rows with date, payee,
///   category, payment mode, and amount formatted to two decimal places.
/// - Exports via [Printing.sharePdf].
class PdfStatementGenerator {
  const PdfStatementGenerator._();

  /// Builds a [pw.Document] representing the complete multipage statement.
  static Future<pw.Document> generateDocument({
    required List<dynamic> transactions,
    String accountName = 'All Linked Accounts',
    String? accountNumberMasked,
    DateTime? generatedDate,
    DateTimeRange? dateRange,
    String currencySymbol = AppConstants.defaultCurrencySymbol,
  }) async {
    final DateTime genDate = generatedDate ?? DateTime.now();
    final DateFormat fullDateFormat = DateFormat('MMM dd, yyyy HH:mm');
    final DateFormat rowDateFormat = DateFormat('yyyy-MM-dd');

    // Convert raw dynamic transaction inputs into unified PdfStatementItem records
    final List<PdfStatementItem> items = transactions.map((dynamic item) {
      if (item is PdfStatementItem) return item;
      if (item is Transaction) return PdfStatementItem.fromIsar(item);
      if (item is TransactionModel) return PdfStatementItem.fromModel(item);
      return PdfStatementItem(
        date: DateTime.now(),
        payee: item.toString(),
        category: 'General',
        paymentMode: 'Account',
        amount: 0.0,
        isExpense: true,
      );
    }).toList();

    // Sort chronologically descending
    items.sort((a, b) => b.date.compareTo(a.date));

    // Compute financial statement aggregations
    double totalInflow = 0.0;
    double totalOutflow = 0.0;

    for (final item in items) {
      if (item.isExpense) {
        totalOutflow += item.amount;
      } else {
        totalInflow += item.amount;
      }
    }

    final String curr = currencySymbol == '₹' ? 'Rs. ' : currencySymbol;
    final double netBalanceChange = totalInflow - totalOutflow;

    final doc = pw.Document();

    // Palette Colors for PDF
    const PdfColor primaryTeal = PdfColor.fromInt(0xFF0D9488);
    const PdfColor darkSlate = PdfColor.fromInt(0xFF0F172A);
    const PdfColor surfaceCard = PdfColor.fromInt(0xFFF8FAFC);
    const PdfColor borderGrey = PdfColor.fromInt(0xFFE2E8F0);
    const PdfColor greenInflow = PdfColor.fromInt(0xFF10B981);
    const PdfColor redOutflow = PdfColor.fromInt(0xFFEF4444);
    const PdfColor textSecondary = PdfColor.fromInt(0xFF64748B);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 20),
            padding: const pw.EdgeInsets.only(bottom: 12),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: borderGrey, width: 1.5),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      children: [
                        pw.Container(
                          width: 12,
                          height: 12,
                          decoration: const pw.BoxDecoration(
                            color: primaryTeal,
                            shape: pw.BoxShape.circle,
                          ),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Text(
                          'FINANCEX STATEMENT',
                          style: const pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: darkSlate,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Account: $accountName ${accountNumberMasked != null ? "($accountNumberMasked)" : ""}',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Generated: ${fullDateFormat.format(genDate)}',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: textSecondary,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Currency: $curr (INR)',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: darkSlate,
                      ),
                    ),
                    if (dateRange != null) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Period: ${rowDateFormat.format(dateRange.start)} to ${rowDateFormat.format(dateRange.end)}',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: primaryTeal,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 16),
            padding: const pw.EdgeInsets.only(top: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: borderGrey, width: 0.8),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Confidential - Generated by FinanceX Executive Engine',
                  style: const pw.TextStyle(fontSize: 8, color: textSecondary),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: const pw.TextStyle(fontSize: 8, color: textSecondary),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) => [
          // SUMMARY CARDS SECTION
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 20),
            child: pw.Row(
              children: [
                // Total Inflow Card
                pw.Expanded(
                  child: _buildSummaryCard(
                    title: 'TOTAL INFLOW',
                    amountStr: '+$curr${totalInflow.toStringAsFixed(2)}',
                    textColor: greenInflow,
                    bgColor: surfaceCard,
                    borderColor: borderGrey,
                  ),
                ),
                pw.SizedBox(width: 12),
                // Total Outflow Card
                pw.Expanded(
                  child: _buildSummaryCard(
                    title: 'TOTAL OUTFLOW',
                    amountStr: '-$curr${totalOutflow.toStringAsFixed(2)}',
                    textColor: redOutflow,
                    bgColor: surfaceCard,
                    borderColor: borderGrey,
                  ),
                ),
                pw.SizedBox(width: 12),
                // Net Balance Change Card
                pw.Expanded(
                  child: _buildSummaryCard(
                    title: 'NET CHANGE',
                    amountStr:
                        '${netBalanceChange >= 0 ? "+" : "-"}$curr${netBalanceChange.abs().toStringAsFixed(2)}',
                    textColor: netBalanceChange >= 0 ? greenInflow : redOutflow,
                    bgColor: surfaceCard,
                    borderColor: borderGrey,
                  ),
                ),
              ],
            ),
          ),

          // TRANSACTION LEDGER SECTION
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Text(
              'TRANSACTION LEDGER (${items.length} Entries)',
              style: const pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: darkSlate,
                letterSpacing: 0.4,
              ),
            ),
          ),

          // Alternating Dark-Bordered Table Rows
          pw.Table(
            border: pw.TableBorder.all(
              color: borderGrey,
              width: 0.8,
            ),
            columnWidths: const {
              0: pw.FlexColumnWidth(1.2), // Date
              1: pw.FlexColumnWidth(2.8), // Payee / Description
              2: pw.FlexColumnWidth(1.8), // Category
              3: pw.FlexColumnWidth(2.0), // Payment Mode
              4: pw.FlexColumnWidth(1.8), // Amount
            },
            children: [
              // Header Row
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: darkSlate),
                children: [
                  _buildHeaderCell('Date'),
                  _buildHeaderCell('Payee / Note'),
                  _buildHeaderCell('Category'),
                  _buildHeaderCell('Payment Mode'),
                  _buildHeaderCell('Amount', align: pw.TextAlign.right),
                ],
              ),
              // Data Rows with alternating backgrounds
              ...List.generate(items.length, (int index) {
                final item = items[index];
                final bool isEven = index.isEven;
                final PdfColor rowBg = isEven
                    ? const PdfColor.fromInt(0xFFFFFFFF)
                    : const PdfColor.fromInt(0xFFF1F5F9);

                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: rowBg),
                  children: [
                    _buildDataCell(rowDateFormat.format(item.date)),
                    _buildDataCell(item.payee, isBold: true),
                    _buildDataCell(item.category),
                    _buildDataCell(item.paymentMode),
                    _buildDataCell(
                      '${item.isExpense ? "-" : "+"}$curr${item.amount.toStringAsFixed(2)}',
                      align: pw.TextAlign.right,
                      textColor: item.isExpense ? redOutflow : greenInflow,
                      isBold: true,
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );

    return doc;
  }

  /// Generates the raw PDF bytes for testing or custom sharing.
  static Future<Uint8List> generatePdfBytes({
    required List<dynamic> transactions,
    String accountName = 'All Linked Accounts',
    String? accountNumberMasked,
    DateTime? generatedDate,
    DateTimeRange? dateRange,
    String currencySymbol = AppConstants.defaultCurrencySymbol,
  }) async {
    final pw.Document doc = await generateDocument(
      transactions: transactions,
      accountName: accountName,
      accountNumberMasked: accountNumberMasked,
      generatedDate: generatedDate,
      dateRange: dateRange,
      currencySymbol: currencySymbol,
    );
    return await doc.save();
  }

  /// Exports and invokes [Printing.sharePdf] with the generated statement.
  static Future<void> shareStatement({
    required List<dynamic> transactions,
    String accountName = 'All Linked Accounts',
    String? accountNumberMasked,
    DateTime? generatedDate,
    DateTimeRange? dateRange,
    String currencySymbol = AppConstants.defaultCurrencySymbol,
    String filename = 'statement.pdf',
  }) async {
    final Uint8List bytes = await generatePdfBytes(
      transactions: transactions,
      accountName: accountName,
      accountNumberMasked: accountNumberMasked,
      generatedDate: generatedDate,
      dateRange: dateRange,
      currencySymbol: currencySymbol,
    );

    await Printing.sharePdf(bytes: bytes, filename: filename);
  }

  static pw.Widget _buildSummaryCard({
    required String title,
    required String amountStr,
    required PdfColor textColor,
    required PdfColor bgColor,
    required PdfColor borderColor,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: borderColor, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: const pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromInt(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            amountStr,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildHeaderCell(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        textAlign: align,
        style: const pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: PdfColor.fromInt(0xFFFFFFFF),
        ),
      ),
    );
  }

  static pw.Widget _buildDataCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
    PdfColor textColor = const PdfColor.fromInt(0xFF0F172A),
    bool isBold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 8.5,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: textColor,
        ),
      ),
    );
  }
}
