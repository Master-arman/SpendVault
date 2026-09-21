import 'dart:io';
import 'package:finance_app/core/theme/app_colors.dart';
import 'package:finance_app/features/reports/domain/csv_exporter.dart';
import 'package:finance_app/features/reports/domain/pdf_statement_generator.dart';
import 'package:finance_app/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:finance_app/features/transactions/domain/models/transaction_model.dart';
import 'package:finance_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:flutter/material.dart';

enum ExportFormat {
  pdf,
  csv,
}

/// Modal bottom sheet allowing users to configure and export financial reports
/// in branded vector PDF or tabular CSV format with native OS sharing.
class ExportReportBottomSheet extends StatefulWidget {
  const ExportReportBottomSheet({
    super.key,
    this.initialTransactions,
    this.onExportComplete,
  });

  final List<dynamic>? initialTransactions;
  final Future<void> Function(ExportFormat format, File file)? onExportComplete;

  /// Helper to display the export bottom sheet.
  static Future<void> show({
    required BuildContext context,
    List<dynamic>? transactions,
    Future<void> Function(ExportFormat format, File file)? onExportComplete,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExportReportBottomSheet(
        initialTransactions: transactions,
        onExportComplete: onExportComplete,
      ),
    );
  }

  @override
  State<ExportReportBottomSheet> createState() => _ExportReportBottomSheetState();
}

class _ExportReportBottomSheetState extends State<ExportReportBottomSheet> {
  final TransactionRepository _repository = TransactionRepositoryImpl();
  ExportFormat _selectedFormat = ExportFormat.pdf;
  int _dateRangeDays = 0; // 0 = All time, 30 = past 30 days, 90 = past 90 days
  bool _isExporting = false;
  List<dynamic> _transactions = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialTransactions != null) {
      _transactions = widget.initialTransactions!;
    } else {
      _loadTransactions();
    }
  }

  Future<void> _loadTransactions() async {
    final list = await _repository.getTransactions();
    if (mounted) {
      setState(() {
        _transactions = list;
      });
    }
  }

  List<dynamic> _getFilteredTransactions() {
    if (_dateRangeDays == 0) return _transactions;
    final cutoff = DateTime.now().subtract(Duration(days: _dateRangeDays));
    return _transactions.where((tx) {
      if (tx is TransactionModel) {
        return tx.date.isAfter(cutoff);
      }
      return true;
    }).toList();
  }

  Future<void> _handleExport() async {
    setState(() => _isExporting = true);

    try {
      final records = _getFilteredTransactions();
      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      if (_selectedFormat == ExportFormat.pdf) {
        final filename = 'financex_statement_$dateStr.pdf';
        final file = await PdfStatementGenerator.writePdfFile(
          transactions: records,
          filename: filename,
        );

        if (widget.onExportComplete != null) {
          await widget.onExportComplete!(ExportFormat.pdf, file);
        } else {
          await PdfStatementGenerator.exportAndShare(
            transactions: records,
            filename: filename,
          );
        }
      } else {
        final filename = 'financex_transactions_$dateStr.csv';
        final file = await CsvExporter.writeCsvFile(
          transactions: records,
          filename: filename,
        );

        if (widget.onExportComplete != null) {
          await widget.onExportComplete!(ExportFormat.csv, file);
        } else {
          await CsvExporter.exportAndShare(
            transactions: records,
            filename: filename,
          );
        }
      }

      if (mounted) {
        setState(() => _isExporting = false);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_selectedFormat == ExportFormat.pdf ? "PDF Statement" : "CSV Spreadsheet"} generated successfully',
            ),
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isExporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppColors.expenseRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final filteredCount = _getFilteredTransactions().length;

    return Container(
      key: const Key('export_report_bottom_sheet'),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 20,
        right: 20,
        top: 20,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131A2A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.file_download_rounded,
                    color: AppColors.successGreen,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Export Data & Statements',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Generate branded PDF reports or tabular CSV files',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Export Format Picker
            Text(
              'EXPORT FORMAT',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                // PDF Option
                Expanded(
                  child: InkWell(
                    key: const Key('export_format_pdf'),
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => setState(() => _selectedFormat = ExportFormat.pdf),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _selectedFormat == ExportFormat.pdf
                            ? AppColors.accentIndigo.withValues(alpha: 0.12)
                            : (isDark ? const Color(0xFF1E2638) : const Color(0xFFF4F6F9)),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _selectedFormat == ExportFormat.pdf
                              ? AppColors.accentIndigo
                              : AppColors.borderStroke.withValues(alpha: 0.3),
                          width: _selectedFormat == ExportFormat.pdf ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Icon(Icons.picture_as_pdf_rounded, color: AppColors.expenseRed, size: 24),
                              if (_selectedFormat == ExportFormat.pdf)
                                const Icon(Icons.check_circle_rounded, color: AppColors.accentIndigo, size: 18),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'PDF Statement',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Vector report with KPIs & tables',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // CSV Option
                Expanded(
                  child: InkWell(
                    key: const Key('export_format_csv'),
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => setState(() => _selectedFormat = ExportFormat.csv),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _selectedFormat == ExportFormat.csv
                            ? AppColors.accentIndigo.withValues(alpha: 0.12)
                            : (isDark ? const Color(0xFF1E2638) : const Color(0xFFF4F6F9)),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _selectedFormat == ExportFormat.csv
                              ? AppColors.accentIndigo
                              : AppColors.borderStroke.withValues(alpha: 0.3),
                          width: _selectedFormat == ExportFormat.csv ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Icon(Icons.table_chart_rounded, color: AppColors.successGreen, size: 24),
                              if (_selectedFormat == ExportFormat.csv)
                                const Icon(Icons.check_circle_rounded, color: AppColors.accentIndigo, size: 18),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'CSV Spreadsheet',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Excel / Sheets tabular ledger',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Date Range Filter Chips
            Text(
              'DATE RANGE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                _buildRangeChip(label: 'All Time', days: 0),
                const SizedBox(width: 8),
                _buildRangeChip(label: 'Past 30 Days', days: 30),
                const SizedBox(width: 8),
                _buildRangeChip(label: 'Past 90 Days', days: 90),
              ],
            ),
            const SizedBox(height: 16),

            // Export Summary Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2638) : const Color(0xFFF4F6F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Included Records:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  Text(
                    '$filteredCount Transactions',
                    key: const Key('export_record_count_text'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.accentIndigo,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton.icon(
              key: const Key('export_submit_button'),
              onPressed: _isExporting ? null : _handleExport,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.successGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: _isExporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.share_rounded, size: 20),
              label: Text(
                _isExporting
                    ? 'Generating File...'
                    : 'Export & Share ${_selectedFormat == ExportFormat.pdf ? "PDF" : "CSV"}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRangeChip({required String label, required int days}) {
    final isSelected = _dateRangeDays == days;
    final theme = Theme.of(context);

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => _dateRangeDays = days),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accentIndigo.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.accentIndigo : AppColors.borderStroke.withValues(alpha: 0.4),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.accentIndigo : theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }
}
