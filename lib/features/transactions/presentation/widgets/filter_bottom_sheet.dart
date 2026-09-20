import 'package:finance_app/core/theme/app_colors.dart';
import 'package:finance_app/features/accounts/data/models/account.dart' hide AccountType;
import 'package:finance_app/features/accounts/domain/models/account_model.dart';
import 'package:finance_app/features/categories/data/models/category.dart';
import 'package:finance_app/features/transactions/data/models/transaction.dart';
import 'package:finance_app/features/transactions/domain/models/transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Filter criteria container combining account IDs, category IDs,
/// amount limits, and date range.
class TransactionFilterCriteria {
  const TransactionFilterCriteria({
    this.accountIds = const <int>{},
    this.categoryIds = const <int>{},
    this.minAmount,
    this.maxAmount,
    this.dateRange,
  });

  /// Selected source or destination Account IDs.
  final Set<int> accountIds;

  /// Selected Category IDs.
  final Set<int> categoryIds;

  /// Minimum transaction amount boundary.
  final double? minAmount;

  /// Maximum transaction amount boundary.
  final double? maxAmount;

  /// Date interval filter.
  final DateTimeRange? dateRange;

  /// True if at least one filter criterion is active.
  bool get hasActiveFilters =>
      accountIds.isNotEmpty ||
      categoryIds.isNotEmpty ||
      minAmount != null ||
      maxAmount != null ||
      dateRange != null;

  /// Number of active filter groups.
  int get activeFilterCount {
    int count = 0;
    if (accountIds.isNotEmpty) count++;
    if (categoryIds.isNotEmpty) count++;
    if (minAmount != null || maxAmount != null) count++;
    if (dateRange != null) count++;
    return count;
  }

  /// Evaluates whether an Isar [Transaction] meets all active filter criteria.
  bool matchesIsar(Transaction tx) {
    // 1. Account Filter
    if (accountIds.isNotEmpty) {
      final int? srcId = tx.sourceAccount.value?.id;
      final int? destId = tx.destinationAccount.value?.id;
      final bool srcMatches = srcId != null && accountIds.contains(srcId);
      final bool destMatches = destId != null && accountIds.contains(destId);
      if (!srcMatches && !destMatches) {
        return false;
      }
    }

    // 2. Category Filter
    if (categoryIds.isNotEmpty) {
      final int? catId = tx.category.value?.id;
      if (catId == null || !categoryIds.contains(catId)) {
        return false;
      }
    }

    // 3. Amount Filter
    if (minAmount != null && tx.amount < minAmount!) {
      return false;
    }
    if (maxAmount != null && tx.amount > maxAmount!) {
      return false;
    }

    // 4. Date Range Filter
    if (dateRange != null) {
      final DateTime start = DateTime(
        dateRange!.start.year,
        dateRange!.start.month,
        dateRange!.start.day,
      );
      final DateTime end = DateTime(
        dateRange!.end.year,
        dateRange!.end.month,
        dateRange!.end.day,
        23,
        59,
        59,
      );
      if (tx.timestamp.isBefore(start) || tx.timestamp.isAfter(end)) {
        return false;
      }
    }

    return true;
  }

  /// Evaluates whether a domain [TransactionModel] meets the filter criteria.
  bool matchesModel(TransactionModel model) {
    if (minAmount != null && model.amount < minAmount!) {
      return false;
    }
    if (maxAmount != null && model.amount > maxAmount!) {
      return false;
    }
    if (dateRange != null) {
      final DateTime start = DateTime(
        dateRange!.start.year,
        dateRange!.start.month,
        dateRange!.start.day,
      );
      final DateTime end = DateTime(
        dateRange!.end.year,
        dateRange!.end.month,
        dateRange!.end.day,
        23,
        59,
        59,
      );
      if (model.date.isBefore(start) || model.date.isAfter(end)) {
        return false;
      }
    }
    return true;
  }

  TransactionFilterCriteria copyWith({
    Set<int>? accountIds,
    Set<int>? categoryIds,
    double? minAmount,
    double? maxAmount,
    DateTimeRange? dateRange,
    bool clearMinAmount = false,
    bool clearMaxAmount = false,
    bool clearDateRange = false,
  }) {
    return TransactionFilterCriteria(
      accountIds: accountIds ?? this.accountIds,
      categoryIds: categoryIds ?? this.categoryIds,
      minAmount: clearMinAmount ? null : (minAmount ?? this.minAmount),
      maxAmount: clearMaxAmount ? null : (maxAmount ?? this.maxAmount),
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
    );
  }

  static const TransactionFilterCriteria empty = TransactionFilterCriteria();
}

/// Phase 42: Dynamic Multi-Filter Bottom Sheet.
///
/// Combines Account IDs (`Set<int>`), Category IDs (`Set<int>`),
/// Minimum/Maximum Amount limits, and Date Range (`DateTimeRange`).
class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({
    this.initialFilters = const TransactionFilterCriteria(),
    this.accounts = const [],
    this.categories = const [],
    this.onApply,
    this.onReset,
    super.key,
  });

  final TransactionFilterCriteria initialFilters;
  final List<dynamic> accounts;
  final List<dynamic> categories;
  final ValueChanged<TransactionFilterCriteria>? onApply;
  final VoidCallback? onReset;

  /// Helper static method to open the modal bottom sheet smoothly.
  static Future<TransactionFilterCriteria?> show({
    required BuildContext context,
    TransactionFilterCriteria initialFilters = const TransactionFilterCriteria(),
    List<dynamic> accounts = const [],
    List<dynamic> categories = const [],
  }) {
    return showModalBottomSheet<TransactionFilterCriteria>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FilterBottomSheet(
        initialFilters: initialFilters,
        accounts: accounts,
        categories: categories,
      ),
    );
  }

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late Set<int> _selectedAccountIds;
  late Set<int> _selectedCategoryIds;
  late TextEditingController _minAmountController;
  late TextEditingController _maxAmountController;
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _selectedAccountIds = Set<int>.from(widget.initialFilters.accountIds);
    _selectedCategoryIds = Set<int>.from(widget.initialFilters.categoryIds);
    _minAmountController = TextEditingController(
      text: widget.initialFilters.minAmount != null
          ? widget.initialFilters.minAmount!.toStringAsFixed(0)
          : '',
    );
    _maxAmountController = TextEditingController(
      text: widget.initialFilters.maxAmount != null
          ? widget.initialFilters.maxAmount!.toStringAsFixed(0)
          : '',
    );
    _selectedDateRange = widget.initialFilters.dateRange;
  }

  @override
  void dispose() {
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  TransactionFilterCriteria _buildCurrentCriteria() {
    final double? minVal = double.tryParse(_minAmountController.text.trim());
    final double? maxVal = double.tryParse(_maxAmountController.text.trim());

    return TransactionFilterCriteria(
      accountIds: Set<int>.unmodifiable(_selectedAccountIds),
      categoryIds: Set<int>.unmodifiable(_selectedCategoryIds),
      minAmount: minVal,
      maxAmount: maxVal,
      dateRange: _selectedDateRange,
    );
  }

  void _resetFilters() {
    setState(() {
      _selectedAccountIds.clear();
      _selectedCategoryIds.clear();
      _minAmountController.clear();
      _maxAmountController.clear();
      _selectedDateRange = null;
    });
    widget.onReset?.call();
  }

  void _applyFilters() {
    final criteria = _buildCurrentCriteria();
    if (widget.onApply != null) {
      widget.onApply!(criteria);
    }
    Navigator.of(context).pop(criteria);
  }

  Future<void> _pickDateRange() async {
    final DateTime now = DateTime.now();
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _selectedDateRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
          ),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.accentIndigo,
                  onPrimary: Colors.white,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  void _applyDatePreset(int days) {
    final DateTime now = DateTime.now();
    setState(() {
      _selectedDateRange = DateTimeRange(
        start: now.subtract(Duration(days: days)),
        end: now,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentCriteria = _buildCurrentCriteria();
    final int activeCount = currentCriteria.activeFilterCount;
    final DateFormat formatter = DateFormat('MMM d, yyyy');

    return Container(
      key: const Key('filter_bottom_sheet'),
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppColors.borderStroke, width: 1.5),
        ),
      ),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header with Title & Reset Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'Filter Transactions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (activeCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accentIndigo.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.accentIndigo.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          '$activeCount active',
                          key: const Key('active_filters_count_badge'),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.indigoLight,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                TextButton(
                  key: const Key('reset_filters_button'),
                  onPressed: _resetFilters,
                  child: const Text(
                    'Reset All',
                    style: TextStyle(
                      color: AppColors.expenseRed,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.borderStroke, height: 1),

          // Scrollable Filter Sections
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // SECTION 1: Date Range Filter
                _buildSectionHeader(
                  title: 'Date Range',
                  icon: Icons.calendar_month_rounded,
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.darkSlateBackground.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderStroke),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.date_range_rounded,
                                  size: 16, color: AppColors.indigoLight),
                              const SizedBox(width: 8),
                              Text(
                                _selectedDateRange != null
                                    ? '${formatter.format(_selectedDateRange!.start)} - ${formatter.format(_selectedDateRange!.end)}'
                                    : 'All Recorded Time',
                                key: const Key('selected_date_range_text'),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              if (_selectedDateRange != null)
                                IconButton(
                                  icon: const Icon(Icons.close_rounded,
                                      size: 16, color: AppColors.textMuted),
                                  onPressed: () =>
                                      setState(() => _selectedDateRange = null),
                                ),
                              OutlinedButton(
                                key: const Key('pick_date_range_button'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  minimumSize: Size.zero,
                                ),
                                onPressed: _pickDateRange,
                                child: const Text('Change',
                                    style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Quick date presets
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _buildPresetChip('7 Days', () => _applyDatePreset(7)),
                          _buildPresetChip('30 Days', () => _applyDatePreset(30)),
                          _buildPresetChip('90 Days', () => _applyDatePreset(90)),
                          _buildPresetChip('This Year', () => _applyDatePreset(365)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // SECTION 2: Amount Boundaries
                _buildSectionHeader(
                  title: 'Amount Limits (₹)',
                  icon: Icons.payments_outlined,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('min_amount_input'),
                        controller: _minAmountController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Min Amount',
                          hintText: '0',
                          prefixText: '₹ ',
                          prefixStyle: const TextStyle(
                              color: AppColors.indigoLight, fontSize: 13),
                          suffixIcon: _minAmountController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 14),
                                  onPressed: () {
                                    _minAmountController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextField(
                        key: const Key('max_amount_input'),
                        controller: _maxAmountController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Max Amount',
                          hintText: 'Any',
                          prefixText: '₹ ',
                          prefixStyle: const TextStyle(
                              color: AppColors.indigoLight, fontSize: 13),
                          suffixIcon: _maxAmountController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 14),
                                  onPressed: () {
                                    _maxAmountController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildAmountPreset('< ₹500', max: 500),
                    _buildAmountPreset('₹500 - ₹2,000', min: 500, max: 2000),
                    _buildAmountPreset('₹2,000 - ₹10,000', min: 2000, max: 10000),
                    _buildAmountPreset('> ₹10,000', min: 10000),
                  ],
                ),
                const SizedBox(height: 24),

                // SECTION 3: Account Multi-Selector
                _buildSectionHeader(
                  title: 'Accounts (${_selectedAccountIds.length} selected)',
                  icon: Icons.account_balance_wallet_outlined,
                ),
                const SizedBox(height: 10),
                _buildAccountsList(),
                const SizedBox(height: 24),

                // SECTION 4: Category Multi-Selector
                _buildSectionHeader(
                  title: 'Categories (${_selectedCategoryIds.length} selected)',
                  icon: Icons.category_outlined,
                ),
                const SizedBox(height: 10),
                _buildCategoriesList(),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // Sticky Bottom Apply Bar
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            decoration: const BoxDecoration(
              color: AppColors.darkSlateBackground,
              border: Border(
                top: BorderSide(color: AppColors.borderStroke, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    key: const Key('apply_filters_button'),
                    onPressed: _applyFilters,
                    child: Text(
                      activeCount > 0
                          ? 'Apply Filters ($activeCount)'
                          : 'Apply Filters',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({required String title, required IconData icon}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.accentIndigo),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildPresetChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      backgroundColor: AppColors.surfaceCard,
      side: const BorderSide(color: AppColors.borderStroke),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      onPressed: onTap,
    );
  }

  Widget _buildAmountPreset(String label, {double? min, double? max}) {
    return ActionChip(
      label: Text(label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      backgroundColor: AppColors.surfaceCard,
      side: const BorderSide(color: AppColors.borderStroke),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      onPressed: () {
        setState(() {
          _minAmountController.text = min != null ? min.toStringAsFixed(0) : '';
          _maxAmountController.text = max != null ? max.toStringAsFixed(0) : '';
        });
      },
    );
  }

  Widget _buildAccountsList() {
    final List<dynamic> list = widget.accounts.isNotEmpty
        ? widget.accounts
        : [
            const AccountModel(
              id: '1',
              name: 'Primary Checking',
              institutionName: 'HDFC',
              accountNumberMasked: '****4592',
              balance: 45250.75,
              type: AccountType.bank,
            ),
            const AccountModel(
              id: '2',
              name: 'Platinum Credit Card',
              institutionName: 'ICICI',
              accountNumberMasked: '****8901',
              balance: -3320.40,
              type: AccountType.creditCard,
            ),
            const AccountModel(
              id: '3',
              name: 'Savings Reserve',
              institutionName: 'SBI',
              accountNumberMasked: '****7124',
              balance: 185900.00,
              type: AccountType.bank,
            ),
          ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: list.map((dynamic acc) {
        final int id = acc is Account
            ? acc.id
            : (acc is AccountModel ? (int.tryParse(acc.id) ?? acc.id.hashCode) : 0);
        final String name = acc is Account ? acc.name : (acc is AccountModel ? acc.name : '');
        final bool isSelected = _selectedAccountIds.contains(id);

        return FilterChip(
          key: Key('account_filter_chip_$id'),
          label: Text(
            name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
          ),
          selected: isSelected,
          selectedColor: AppColors.accentIndigo,
          backgroundColor: AppColors.darkSlateBackground.withValues(alpha: 0.6),
          side: BorderSide(
            color: isSelected ? AppColors.accentIndigo : AppColors.borderStroke,
          ),
          showCheckmark: true,
          checkmarkColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          onSelected: (bool selected) {
            setState(() {
              if (selected) {
                _selectedAccountIds.add(id);
              } else {
                _selectedAccountIds.remove(id);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildCategoriesList() {
    final List<dynamic> list = widget.categories.isNotEmpty
        ? widget.categories
        : [
            Category()..id = 1..name = 'Food & Dining'..colorHex = 0xFFF59E0B,
            Category()..id = 2..name = 'Shopping'..colorHex = 0xFF14B8A6,
            Category()..id = 3..name = 'Bills & Utilities'..colorHex = 0xFFEF4444,
            Category()..id = 4..name = 'Transport'..colorHex = 0xFF10B981,
            Category()..id = 5..name = 'Entertainment'..colorHex = 0xFFEC4899,
            Category()..id = 6..name = 'Income'..colorHex = 0xFF10B981,
          ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: list.map((dynamic cat) {
        final int id = cat is Category ? cat.id : 0;
        final String name = cat is Category ? cat.name : '';
        final bool isSelected = _selectedCategoryIds.contains(id);

        return FilterChip(
          key: Key('category_filter_chip_$id'),
          label: Text(
            name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
          ),
          selected: isSelected,
          selectedColor: AppColors.accentIndigo,
          backgroundColor: AppColors.darkSlateBackground.withValues(alpha: 0.6),
          side: BorderSide(
            color: isSelected ? AppColors.accentIndigo : AppColors.borderStroke,
          ),
          showCheckmark: true,
          checkmarkColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          onSelected: (bool selected) {
            setState(() {
              if (selected) {
                _selectedCategoryIds.add(id);
              } else {
                _selectedCategoryIds.remove(id);
              }
            });
          },
        );
      }).toList(),
    );
  }
}
