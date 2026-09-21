import 'package:finance_app/core/theme/app_colors.dart';
import 'package:finance_app/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:finance_app/features/transactions/domain/models/transaction_model.dart';
import 'package:finance_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

enum SplitMethod {
  equal,
  percentage,
}

class SplitPerson {
  SplitPerson({
    required this.name,
    this.phoneOrUpi = '',
    this.percentage = 0.0,
    this.shareAmount = 0.0,
    this.isSettled = false,
  });

  String name;
  String phoneOrUpi;
  double percentage;
  double shareAmount;
  bool isSettled;
}

/// Dialog and modal sheet for splitting group bills, calculating debt per person, and sharing summaries.
class SplitBillDialog extends StatefulWidget {
  const SplitBillDialog({
    super.key,
    this.initialTotalAmount = 900.0,
    this.initialTitle = 'Dinner',
    this.initialCategory = 'Food & Dining',
    this.onShareCallback,
    this.onSaved,
  });

  final double initialTotalAmount;
  final String initialTitle;
  final String initialCategory;
  final Future<void> Function(String summary)? onShareCallback;
  final Future<void> Function(TransactionModel transaction)? onSaved;

  /// Modal display helper
  static Future<void> show({
    required BuildContext context,
    double initialTotalAmount = 900.0,
    String initialTitle = 'Dinner',
    String initialCategory = 'Food & Dining',
    Future<void> Function(String summary)? onShareCallback,
    Future<void> Function(TransactionModel transaction)? onSaved,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SplitBillDialog(
        initialTotalAmount: initialTotalAmount,
        initialTitle: initialTitle,
        initialCategory: initialCategory,
        onShareCallback: onShareCallback,
        onSaved: onSaved,
      ),
    );
  }

  @override
  State<SplitBillDialog> createState() => _SplitBillDialogState();
}

class _SplitBillDialogState extends State<SplitBillDialog> {
  final TransactionRepository _transactionRepository = TransactionRepositoryImpl();
  final NumberFormat _currencyFormatter = NumberFormat.currency(
    symbol: '₹',
    decimalDigits: 2,
  );

  late final TextEditingController _totalAmountController;
  late final TextEditingController _titleController;
  SplitMethod _splitMethod = SplitMethod.equal;
  late List<SplitPerson> _people;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _totalAmountController = TextEditingController(
      text: widget.initialTotalAmount.toStringAsFixed(2),
    );
    _titleController = TextEditingController(text: widget.initialTitle);

    // Initial 3 people (including host)
    _people = [
      SplitPerson(name: 'You (Host)', phoneOrUpi: '', isSettled: true),
      SplitPerson(name: 'Friend 1', phoneOrUpi: ''),
      SplitPerson(name: 'Friend 2', phoneOrUpi: ''),
    ];

    _recalculateShares();
  }

  @override
  void dispose() {
    _totalAmountController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  double get _totalAmount =>
      double.tryParse(_totalAmountController.text.replaceAll(',', '').trim()) ?? 0.0;

  void _recalculateShares() {
    final double total = _totalAmount;
    if (_people.isEmpty) return;

    if (_splitMethod == SplitMethod.equal) {
      final double perPerson = total / _people.length;
      final double defaultPct = 100.0 / _people.length;
      for (final p in _people) {
        p.shareAmount = perPerson;
        p.percentage = defaultPct;
      }
    } else {
      for (final p in _people) {
        p.shareAmount = (total * (p.percentage / 100.0));
      }
    }
  }

  void _addPerson() {
    setState(() {
      final int nextIndex = _people.length;
      _people.add(
        SplitPerson(
          name: 'Person $nextIndex',
          phoneOrUpi: '',
          percentage: _splitMethod == SplitMethod.equal ? 0.0 : 0.0,
        ),
      );
      _recalculateShares();
    });
  }

  void _removePerson(int index) {
    if (_people.length <= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least 2 participants are required to split a bill')),
      );
      return;
    }
    setState(() {
      _people.removeAt(index);
      _recalculateShares();
    });
  }

  String _generateShareSummary() {
    final String title = _titleController.text.trim().isEmpty ? 'Expense' : _titleController.text.trim();
    final double total = _totalAmount;
    final buffer = StringBuffer();

    buffer.writeln('🧾 Bill Split: $title');
    buffer.writeln('💰 Total Bill: ${_currencyFormatter.format(total)}');
    buffer.writeln('👥 Split Method: ${_splitMethod == SplitMethod.equal ? "Equal" : "Custom Percentage"}');
    buffer.writeln('------------------------------');

    for (final p in _people) {
      final String upiText = p.phoneOrUpi.isNotEmpty ? ' (${p.phoneOrUpi})' : '';
      final String status = p.isSettled ? ' [Paid]' : ' [Pending]';
      buffer.writeln('• ${p.name}$upiText: ${_currencyFormatter.format(p.shareAmount)}$status');
    }

    buffer.writeln('------------------------------');
    final double perPerson = _people.isNotEmpty ? _people.first.shareAmount : total;
    buffer.writeln('You owe ${_currencyFormatter.format(perPerson)} for $title.');

    return buffer.toString();
  }

  Future<void> _shareSummary() async {
    final String summary = _generateShareSummary();

    if (widget.onShareCallback != null) {
      await widget.onShareCallback!(summary);
    } else {
      await Share.share(
        summary,
        subject: 'Bill Split for ${_titleController.text.trim()}',
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Opening Share Sheet...'),
          backgroundColor: AppColors.accentCyan,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _saveToLedger() async {
    final double total = _totalAmount;
    if (total <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid bill amount')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final String title = _titleController.text.trim().isEmpty ? 'Group Bill' : _titleController.text.trim();
    final double hostShare = _people.isNotEmpty ? _people.first.shareAmount : total;

    final TransactionModel txn = TransactionModel(
      id: 'txn-split-${DateTime.now().millisecondsSinceEpoch}',
      title: '$title (Split)',
      amount: hostShare,
      flow: TransactionFlow.expense,
      category: widget.initialCategory,
      date: DateTime.now(),
      accountId: 'acc-1',
      accountName: 'Primary Checking',
      merchant: title,
      note: 'Total: ₹${total.toStringAsFixed(2)} split among ${_people.length} people. Host share: ₹${hostShare.toStringAsFixed(2)}.',
      isAutomated: false,
    );

    if (widget.onSaved != null) {
      await widget.onSaved!(txn);
    } else {
      await _transactionRepository.addTransaction(txn);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved your share (${_currencyFormatter.format(hostShare)}) to Ledger'),
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

    final double perPersonShare = _people.isNotEmpty ? _people.first.shareAmount : _totalAmount;

    return Container(
      key: const Key('split_bill_dialog'),
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
                    color: AppColors.warningAmber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.call_split_rounded,
                    color: AppColors.warningAmber,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Split Bill & Share',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Compute individual shares & dispatch WhatsApp reminders',
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

            // Total Amount & Title Row
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    key: const Key('split_total_amount_field'),
                    controller: _totalAmountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.accentIndigo),
                    decoration: InputDecoration(
                      labelText: 'Total Bill (₹)',
                      prefixText: '₹ ',
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E2638) : const Color(0xFFF4F6F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (_) => setState(() => _recalculateShares()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: TextField(
                    key: const Key('split_title_field'),
                    controller: _titleController,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
                    decoration: InputDecoration(
                      labelText: 'Expense / Event Title',
                      prefixIcon: const Icon(Icons.receipt_long_rounded, size: 20),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E2638) : const Color(0xFFF4F6F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Split Method Toggle (Equal vs Percentage)
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    key: const Key('split_method_equal'),
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      setState(() {
                        _splitMethod = SplitMethod.equal;
                        _recalculateShares();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _splitMethod == SplitMethod.equal
                            ? AppColors.accentIndigo.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _splitMethod == SplitMethod.equal
                              ? AppColors.accentIndigo
                              : AppColors.borderStroke.withValues(alpha: 0.4),
                          width: _splitMethod == SplitMethod.equal ? 1.5 : 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Equal Split (1/N)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: _splitMethod == SplitMethod.equal ? FontWeight.w700 : FontWeight.w500,
                          color: _splitMethod == SplitMethod.equal
                              ? AppColors.accentIndigo
                              : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    key: const Key('split_method_percentage'),
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      setState(() {
                        _splitMethod = SplitMethod.percentage;
                        final double defaultPct = 100.0 / _people.length;
                        for (final p in _people) {
                          p.percentage = defaultPct;
                        }
                        _recalculateShares();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _splitMethod == SplitMethod.percentage
                            ? AppColors.accentIndigo.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _splitMethod == SplitMethod.percentage
                              ? AppColors.accentIndigo
                              : AppColors.borderStroke.withValues(alpha: 0.4),
                          width: _splitMethod == SplitMethod.percentage ? 1.5 : 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Custom %',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: _splitMethod == SplitMethod.percentage ? FontWeight.w700 : FontWeight.w500,
                          color: _splitMethod == SplitMethod.percentage
                              ? AppColors.accentIndigo
                              : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Live Calculation Highlight Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.accentIndigo.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.accentIndigo.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Share Per Person (${_people.length} people)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _currencyFormatter.format(perPersonShare),
                        key: const Key('per_person_share_text'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accentIndigo,
                        ),
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    key: const Key('split_add_person_button'),
                    onPressed: _addPerson,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      side: const BorderSide(color: AppColors.accentIndigo),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.person_add_rounded, size: 16, color: AppColors.accentIndigo),
                    label: const Text(
                      'Add Person',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.accentIndigo),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Participants List
            Text(
              'Participants & Contact Info',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 8),

            ..._people.asMap().entries.map((entry) {
              final int index = entry.key;
              final SplitPerson person = entry.value;
              final bool isHost = index == 0;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2638) : const Color(0xFFF4F6F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: isHost
                          ? AppColors.primary
                          : AppColors.accentIndigo.withValues(alpha: 0.2),
                      child: Text(
                        isHost ? '★' : '${index + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isHost ? Colors.white : AppColors.accentIndigo,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        key: Key('split_person_name_field_$index'),
                        initialValue: person.name,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
                        decoration: const InputDecoration(
                          isDense: true,
                          hintText: 'Name',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (val) => person.name = val,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        key: Key('split_person_upi_field_$index'),
                        initialValue: person.phoneOrUpi,
                        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.8)),
                        decoration: const InputDecoration(
                          isDense: true,
                          hintText: 'UPI ID / Phone',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (val) => person.phoneOrUpi = val,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _currencyFormatter.format(person.shareAmount),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentIndigo,
                      ),
                    ),
                    if (!isHost) ...[
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline_rounded, size: 18, color: AppColors.expenseRed),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _removePerson(index),
                      ),
                    ],
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),

            // Action Buttons: Share Summary & Save
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('split_share_summary_button'),
                    onPressed: _shareSummary,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.accentCyan),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.share_rounded, size: 18, color: AppColors.accentCyan),
                    label: const Text(
                      'Share Summary',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accentCyan),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    key: const Key('split_save_button'),
                    onPressed: _isSaving ? null : _saveToLedger,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentIndigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_circle_rounded, size: 18),
                    label: Text(
                      _isSaving ? 'Saving...' : 'Save to Ledger',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
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
}
