import 'package:finance_app/core/theme/app_colors.dart';
import 'package:finance_app/core/theme/theme_toggle_button.dart';
import 'package:finance_app/core/utils/currency_formatter.dart';
import 'package:finance_app/features/categories/domain/models/category_model.dart';
import 'package:finance_app/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:finance_app/features/transactions/domain/models/transaction_model.dart';
import 'package:finance_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:finance_app/features/transactions/presentation/widgets/transaction_tile.dart';
import 'package:flutter/material.dart';

/// Screen displaying category breakdown, monthly budget limit progress,
/// and transactions tagged with that specific category.
class CategoryDetailScreen extends StatefulWidget {
  final CategoryModel category;
  final TransactionRepository? transactionRepository;

  const CategoryDetailScreen({
    super.key,
    required this.category,
    this.transactionRepository,
  });

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  late final TransactionRepository _repository;
  List<TransactionModel> _filteredTransactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _repository = widget.transactionRepository ?? TransactionRepositoryImpl();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final allTransactions = await _repository.getTransactions();
    final categoryNameLower = widget.category.name.trim().toLowerCase();
    final categoryIdLower = widget.category.id.trim().toLowerCase();

    final filtered = allTransactions.where((txn) {
      final txnCatLower = txn.category.trim().toLowerCase();
      return txnCatLower == categoryNameLower ||
          txnCatLower.contains(categoryNameLower) ||
          categoryNameLower.contains(txnCatLower) ||
          txnCatLower == categoryIdLower;
    }).toList();

    if (mounted) {
      setState(() {
        _filteredTransactions = filtered;
        _isLoading = false;
      });
    }
  }

  double get _totalSpent {
    return _filteredTransactions
        .where((t) => t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = widget.category;
    final limit = category.budgetLimit;
    final spent = _totalSpent;
    final progress = (limit != null && limit > 0) ? (spent / limit).clamp(0.0, 1.0) : 0.0;
    final isOverBudget = limit != null && spent > limit;

    return Scaffold(
      appBar: AppBar(
        title: Text(category.name),
        actions: const [
          ThemeToggleButton(),
          SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentIndigo))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ── Category Budget Card ──
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color ?? theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: category.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(category.icon, color: category.color, size: 26),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category.name,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.onSurface,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_filteredTransactions.length} Total Transactions',
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
                      if (limit != null) ...[
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Spent: ${CurrencyFormatter.format(spent)}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isOverBudget ? AppColors.expenseRed : theme.colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              'Limit: ${CurrencyFormatter.format(limit)}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isOverBudget
                                  ? AppColors.expenseRed
                                  : progress > 0.8
                                      ? AppColors.warningAmber
                                      : category.color,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isOverBudget
                              ? 'Exceeded by ${CurrencyFormatter.format(spent - limit)}'
                              : '${CurrencyFormatter.format(limit - spent)} remaining this month',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isOverBudget
                                ? AppColors.expenseRed
                                : AppColors.successGreen,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                Text(
                  'Transactions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),

                // ── Filtered Transactions List ──
                if (_filteredTransactions.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 48,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No transactions found for ${category.name}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ..._filteredTransactions.map(
                    (txn) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TransactionTile(transaction: txn),
                    ),
                  ),
              ],
            ),
    );
  }
}
