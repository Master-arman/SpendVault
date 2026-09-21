import 'package:finance_app/core/theme/app_colors.dart';
import 'package:finance_app/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:finance_app/features/transactions/domain/models/transaction_model.dart';
import 'package:finance_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Pre-filled review dialog displayed after parsing SMS or receipt text.
/// Allows the user to inspect, modify, and confirm transaction details before committing to state.
class ConfirmTransactionDialog extends StatefulWidget {
  const ConfirmTransactionDialog({
    super.key,
    required this.initialAmount,
    required this.initialTitle,
    this.initialCategory = 'Shopping',
    this.initialFlow = TransactionFlow.expense,
    this.initialDate,
    this.initialAccountName = 'Primary Account',
    this.initialAccountId = 'acc-1',
    this.rawMessage,
    this.onConfirm,
  });

  final double initialAmount;
  final String initialTitle;
  final String initialCategory;
  final TransactionFlow initialFlow;
  final DateTime? initialDate;
  final String initialAccountName;
  final String initialAccountId;
  final String? rawMessage;
  final Future<void> Function(TransactionModel transaction)? onConfirm;

  /// Static helper to display the dialog as a modal bottom sheet or dialog.
  static Future<TransactionModel?> show({
    required BuildContext context,
    required double initialAmount,
    required String initialTitle,
    String initialCategory = 'Shopping',
    TransactionFlow initialFlow = TransactionFlow.expense,
    DateTime? initialDate,
    String initialAccountName = 'Primary Account',
    String initialAccountId = 'acc-1',
    String? rawMessage,
    Future<void> Function(TransactionModel transaction)? onConfirm,
  }) {
    return showModalBottomSheet<TransactionModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ConfirmTransactionDialog(
        initialAmount: initialAmount,
        initialTitle: initialTitle,
        initialCategory: initialCategory,
        initialFlow: initialFlow,
        initialDate: initialDate,
        initialAccountName: initialAccountName,
        initialAccountId: initialAccountId,
        rawMessage: rawMessage,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<ConfirmTransactionDialog> createState() => _ConfirmTransactionDialogState();
}

class _ConfirmTransactionDialogState extends State<ConfirmTransactionDialog> {
  late final TextEditingController _amountController;
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;

  late TransactionFlow _selectedFlow;
  late String _selectedCategory;
  late String _selectedAccount;
  late DateTime _selectedDate;
  bool _isSaving = false;

  final List<String> _categories = [
    'Food & Dining',
    'Shopping',
    'Transport',
    'Entertainment',
    'Bills & Utilities',
    'Health',
    'Income',
    'General',
  ];

  final List<String> _accounts = [
    'Primary Account',
    'HDFC Salary A/C',
    'SBI Savings A/C',
    'Cash Wallet',
  ];

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.initialAmount.toStringAsFixed(2),
    );
    _titleController = TextEditingController(text: widget.initialTitle);
    _notesController = TextEditingController();
    _selectedFlow = widget.initialFlow;
    _selectedCategory = _categories.contains(widget.initialCategory)
        ? widget.initialCategory
        : 'Shopping';
    _selectedAccount = widget.initialAccountName;
    _selectedDate = widget.initialDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final double? parsedAmount = double.tryParse(_amountController.text.replaceAll(',', ''));
    if (parsedAmount == null || parsedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    final String title = _titleController.text.trim().isEmpty
        ? 'Untitled Transaction'
        : _titleController.text.trim();

    setState(() => _isSaving = true);

    final TransactionModel newTxn = TransactionModel(
      id: 'txn-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      amount: parsedAmount,
      flow: _selectedFlow,
      category: _selectedCategory,
      date: _selectedDate,
      accountId: widget.initialAccountId,
      accountName: _selectedAccount,
      merchant: title,
      note: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : (widget.rawMessage != null ? 'Parsed via Scan Engine' : null),
      isAutomated: true,
    );

    if (widget.onConfirm != null) {
      await widget.onConfirm!(newTxn);
    } else {
      final TransactionRepository repo = TransactionRepositoryImpl();
      await repo.addTransaction(newTxn);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.of(context).pop(newTxn);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved "$title" (₹${parsedAmount.toStringAsFixed(2)}) to Ledger'),
          backgroundColor: AppColors.successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      key: const Key('confirm_transaction_dialog'),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
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
                width: 48,
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
                    color: AppColors.accentCyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.accentCyan,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Confirm Transaction',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Parsed from Scan Message Pipeline',
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

            // Flow Selector (Expense / Income / Transfer)
            Row(
              children: [
                _buildFlowTab('Expense', TransactionFlow.expense, AppColors.expenseRed),
                const SizedBox(width: 8),
                _buildFlowTab('Income', TransactionFlow.income, AppColors.incomeGreen),
                const SizedBox(width: 8),
                _buildFlowTab('Transfer', TransactionFlow.transfer, AppColors.accentIndigo),
              ],
            ),
            const SizedBox(height: 16),

            // Amount Input
            TextField(
              key: const Key('confirm_transaction_amount_field'),
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: _selectedFlow == TransactionFlow.income
                    ? AppColors.incomeGreen
                    : AppColors.expenseRed,
              ),
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '₹ ',
                prefixStyle: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: _selectedFlow == TransactionFlow.income
                      ? AppColors.incomeGreen
                      : AppColors.expenseRed,
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF1E2638) : const Color(0xFFF4F6F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Title / Merchant Input
            TextField(
              key: const Key('confirm_transaction_title_field'),
              controller: _titleController,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                labelText: 'Title / Merchant',
                prefixIcon: const Icon(Icons.storefront_rounded, size: 20),
                filled: true,
                fillColor: isDark ? const Color(0xFF1E2638) : const Color(0xFFF4F6F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Category Chips Selection
            Text(
              'Category',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedCategory = cat);
                        }
                      },
                      selectedColor: AppColors.accentIndigo,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            // Account & Date Row
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedAccount,
                    decoration: InputDecoration(
                      labelText: 'Account',
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E2638) : const Color(0xFFF4F6F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    items: _accounts.map((acc) {
                      return DropdownMenuItem<String>(
                        value: acc,
                        child: Text(
                          acc,
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedAccount = val);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E2638) : const Color(0xFFF4F6F9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.accentCyan),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              DateFormat('dd MMM yyyy').format(_selectedDate),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
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

            // Save & Cancel Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const Key('confirm_transaction_cancel_button'),
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    key: const Key('confirm_transaction_save_button'),
                    onPressed: _isSaving ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentCyan,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : const Icon(Icons.check_circle_rounded, size: 20),
                    label: Text(
                      _isSaving ? 'Saving...' : 'Confirm & Save',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlowTab(String label, TransactionFlow flow, Color color) {
    final isSelected = _selectedFlow == flow;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _selectedFlow = flow),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : AppColors.borderStroke.withValues(alpha: 0.4),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? color : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }
}
