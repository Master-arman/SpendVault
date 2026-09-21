import 'package:finance_app/core/theme/app_colors.dart';
import 'package:finance_app/core/theme/theme_toggle_button.dart';
import 'package:finance_app/core/widgets/staggered_list_wrapper.dart';
import 'package:finance_app/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:finance_app/features/transactions/domain/models/transaction_model.dart';
import 'package:finance_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:finance_app/features/transactions/presentation/widgets/transaction_detail_modal.dart';
import 'package:finance_app/features/transactions/presentation/widgets/transaction_tile.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Screen displaying transactions filtered by category, date range, or account.
class FilteredTransactionsScreen extends StatefulWidget {
  const FilteredTransactionsScreen({
    super.key,
    this.categoryId,
    this.categoryName,
    this.startDate,
    this.endDate,
  });

  final String? categoryId;
  final String? categoryName;
  final DateTime? startDate;
  final DateTime? endDate;

  @override
  State<FilteredTransactionsScreen> createState() => _FilteredTransactionsScreenState();
}

class _FilteredTransactionsScreenState extends State<FilteredTransactionsScreen> {
  final TransactionRepository _repository = TransactionRepositoryImpl();
  List<TransactionModel> _filteredTransactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFilteredTransactions();
  }

  Future<void> _loadFilteredTransactions() async {
    final List<TransactionModel> all = await _repository.getTransactions();

    final List<TransactionModel> filtered = all.where((TransactionModel tx) {
      if (widget.categoryId != null && widget.categoryId!.isNotEmpty) {
        if (!tx.category.toLowerCase().contains(widget.categoryId!.toLowerCase()) &&
            !tx.category.toLowerCase().contains((widget.categoryName ?? '').toLowerCase())) {
          return false;
        }
      }
      if (widget.startDate != null && tx.date.isBefore(widget.startDate!)) {
        return false;
      }
      if (widget.endDate != null && tx.date.isAfter(widget.endDate!)) {
        return false;
      }
      return true;
    }).toList();

    if (mounted) {
      setState(() {
        _filteredTransactions = filtered;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat formatter = DateFormat('MMM d');
    final String dateRangeText = (widget.startDate != null && widget.endDate != null)
        ? '${formatter.format(widget.startDate!)} - ${formatter.format(widget.endDate!)}'
        : 'All Time';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName ?? 'Filtered Ledger'),
        actions: const [
          ThemeToggleButton(),
          SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderStroke),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.indigoLight),
                  const SizedBox(width: 8),
                  Text(
                    'Scope: $dateRangeText',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accentIndigo.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${_filteredTransactions.length} items',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.indigoLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.accentIndigo))
                : _filteredTransactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.textMuted.withValues(alpha: 0.5)),
                            const SizedBox(height: 12),
                            const Text(
                              'No transactions found for this scope',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemExtent: 82.0,
                        padding: const EdgeInsets.all(20),
                        itemCount: _filteredTransactions.length,
                        itemBuilder: (BuildContext context, int index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: AnimationConfiguration.staggeredList(
                              position: index,
                              delay: const Duration(milliseconds: 40),
                              duration: const Duration(milliseconds: 320),
                              child: TransactionTile(
                                transaction: _filteredTransactions[index],
                                onTap: () => TransactionDetailModal.show(
                                  context: context,
                                  transaction: _filteredTransactions[index],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
