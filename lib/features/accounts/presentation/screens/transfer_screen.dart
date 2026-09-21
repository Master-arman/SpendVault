import 'package:finance_app/core/theme/app_colors.dart';
import 'package:finance_app/core/theme/theme_toggle_button.dart';
import 'package:finance_app/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:finance_app/features/accounts/domain/models/account_model.dart';
import 'package:finance_app/features/accounts/domain/repositories/account_repository.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Screen and modal sheet for executing double-entry inter-account transfers.
/// Decrements source balance and increments destination balance atomically in a single mutation.
class TransferScreen extends StatefulWidget {
  const TransferScreen({
    super.key,
    this.initialFromAccountId,
    this.initialToAccountId,
    this.initialAmount,
  });

  final String? initialFromAccountId;
  final String? initialToAccountId;
  final double? initialAmount;

  /// Modal bottom sheet helper to present Transfer flow.
  static Future<bool?> show({
    required BuildContext context,
    String? initialFromAccountId,
    String? initialToAccountId,
    double? initialAmount,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransferScreen(
        initialFromAccountId: initialFromAccountId,
        initialToAccountId: initialToAccountId,
        initialAmount: initialAmount,
      ),
    );
  }

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final AccountRepository _accountRepository = AccountRepositoryImpl();
  final NumberFormat _currencyFormatter = NumberFormat.currency(
    symbol: '₹',
    decimalDigits: 2,
  );

  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  List<AccountModel> _accounts = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  String? _fromAccountId;
  String? _toAccountId;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.initialAmount != null ? widget.initialAmount!.toStringAsFixed(2) : '',
    );
    _noteController = TextEditingController();
    _loadAccounts();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadAccounts() async {
    final List<AccountModel> accounts = await _accountRepository.getAccounts();
    if (mounted) {
      setState(() {
        _accounts = accounts;
        _isLoading = false;

        if (accounts.isNotEmpty) {
          _fromAccountId = widget.initialFromAccountId ?? accounts.first.id;
          if (accounts.length > 1) {
            _toAccountId = widget.initialToAccountId ?? accounts[1].id;
          } else {
            _toAccountId = accounts.first.id;
          }
        }
      });
    }
  }

  void _swapAccounts() {
    if (_fromAccountId == null || _toAccountId == null) return;
    setState(() {
      final temp = _fromAccountId;
      _fromAccountId = _toAccountId;
      _toAccountId = temp;
    });
  }

  Future<void> _handleSubmitTransfer() async {
    if (_fromAccountId == null || _toAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select source and destination accounts')),
      );
      return;
    }

    if (_fromAccountId == _toAccountId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Source and destination accounts must be different')),
      );
      return;
    }

    final double? parsedAmount = double.tryParse(_amountController.text.replaceAll(',', '').trim());
    if (parsedAmount == null || parsedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid transfer amount')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Execute double-entry transfer mutation
      await _accountRepository.transferFunds(
        fromAccountId: _fromAccountId!,
        toAccountId: _toAccountId!,
        amount: parsedAmount,
        date: _selectedDate,
        note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
      );

      final fromAccount = _accounts.firstWhere((a) => a.id == _fromAccountId);
      final toAccount = _accounts.firstWhere((a) => a.id == _toAccountId);

      if (mounted) {
        setState(() => _isSubmitting = false);
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Transferred ₹${parsedAmount.toStringAsFixed(2)} from ${fromAccount.name} to ${toAccount.name}',
            ),
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transfer failed: $e'),
            backgroundColor: AppColors.expenseRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final fromAccount = _accounts.where((a) => a.id == _fromAccountId).firstOrNull;
    final toAccount = _accounts.where((a) => a.id == _toAccountId).firstOrNull;

    return Scaffold(
      key: const Key('transfer_screen'),
      appBar: AppBar(
        title: const Text('Transfer Funds'),
        actions: const [
          ThemeToggleButton(),
          SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentIndigo))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Transfer Header Visualization Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF131A2A) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // From Account Section
                        _buildAccountSelectorCard(
                          title: 'FROM ACCOUNT',
                          selectedId: _fromAccountId,
                          selectedAccount: fromAccount,
                          iconColor: AppColors.expenseRed,
                          onChanged: (val) => setState(() => _fromAccountId = val),
                          dropdownKey: const Key('transfer_from_account_dropdown'),
                        ),

                        // Swap Divider Button
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Divider(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
                              Material(
                                color: isDark ? const Color(0xFF1E2638) : const Color(0xFFF1F5F9),
                                shape: const CircleBorder(),
                                child: IconButton(
                                  key: const Key('transfer_swap_accounts_button'),
                                  icon: const Icon(Icons.swap_vert_rounded, color: AppColors.accentIndigo, size: 22),
                                  tooltip: 'Swap Accounts',
                                  onPressed: _swapAccounts,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // To Account Section
                        _buildAccountSelectorCard(
                          title: 'TO ACCOUNT',
                          selectedId: _toAccountId,
                          selectedAccount: toAccount,
                          iconColor: AppColors.successGreen,
                          onChanged: (val) => setState(() => _toAccountId = val),
                          dropdownKey: const Key('transfer_to_account_dropdown'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Amount Input Card
                  Text(
                    'Transfer Amount',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF131A2A) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    child: TextField(
                      key: const Key('transfer_amount_field'),
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accentIndigo,
                      ),
                      decoration: InputDecoration(
                        prefixText: '₹ ',
                        prefixStyle: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accentIndigo,
                        ),
                        hintText: '0.00',
                        hintStyle: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Date Picker Card
                  Text(
                    'Transfer Date',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    key: const Key('transfer_date_picker'),
                    borderRadius: BorderRadius.circular(16),
                    onTap: () async {
                      final picked = await showDatePicker(
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF131A2A) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month_rounded, color: AppColors.accentCyan, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              DateFormat('EEEE, dd MMMM yyyy').format(_selectedDate),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Icon(Icons.edit_calendar_rounded, size: 18, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Remarks / Note Field
                  Text(
                    'Notes / Reference (Optional)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF131A2A) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    child: TextField(
                      key: const Key('transfer_notes_field'),
                      controller: _noteController,
                      style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface),
                      decoration: InputDecoration(
                        hintText: 'e.g. Monthly savings allocation',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Submit Button
                  ElevatedButton.icon(
                    key: const Key('transfer_submit_button'),
                    onPressed: _isSubmitting ? null : _handleSubmitTransfer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentIndigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded, size: 20),
                    label: Text(
                      _isSubmitting ? 'Processing Transfer...' : 'Complete Transfer',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAccountSelectorCard({
    required String title,
    required String? selectedId,
    required AccountModel? selectedAccount,
    required Color iconColor,
    required ValueChanged<String?> onChanged,
    required Key dropdownKey,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          key: dropdownKey,
          initialValue: selectedId,
          decoration: const InputDecoration(
            isDense: true,
            filled: true,
            fillColor: Colors.transparent,
            contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            border: InputBorder.none,
          ),
          items: _accounts.map((acc) {
            return DropdownMenuItem<String>(
              value: acc.id,
              child: Row(
                children: [
                  Icon(
                    acc.type == AccountType.creditCard
                        ? Icons.credit_card_rounded
                        : (acc.type == AccountType.wallet
                            ? Icons.account_balance_wallet_rounded
                            : Icons.account_balance_rounded),
                    color: iconColor,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    acc.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${_currencyFormatter.format(acc.balance)})',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
