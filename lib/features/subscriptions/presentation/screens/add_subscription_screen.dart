import 'package:finance_app/core/theme/app_colors.dart';
import 'package:finance_app/features/subscriptions/data/models/subscription.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Phase 32: Subscription Lifecycle Form & Annual Cost Calculator.
/// Dynamically calculates and displays live annual commitment metrics:
/// e.g. "Annual commitment: ₹7,788.00/year" when entering ₹649/month.
class AddSubscriptionScreen extends StatefulWidget {
  const AddSubscriptionScreen({
    super.key,
    this.initialName = '',
    this.initialAmount = 649.0,
    this.initialCycle = BillingCycle.monthly,
    this.initialNextBillingDate,
    this.initialReminderDays = 3,
    this.currencySymbol = '₹',
    this.onSave,
    this.initialAutoLog = false,
  });

  final String initialName;
  final double initialAmount;
  final BillingCycle initialCycle;
  final DateTime? initialNextBillingDate;
  final int initialReminderDays;
  final bool initialAutoLog;
  final String currencySymbol;
  final Future<void> Function(Subscription subscription)? onSave;

  @override
  State<AddSubscriptionScreen> createState() => _AddSubscriptionScreenState();
}

class _AddSubscriptionScreenState extends State<AddSubscriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;

  late BillingCycle _selectedCycle;
  late DateTime _nextBillingDate;
  late int _reminderDaysBefore;
  late bool _autoLogOnRenewal;
  String _selectedCategory = 'Entertainment';
  String _selectedAccount = 'HDFC Bank';
  bool _isSubmitting = false;

  static const List<Map<String, dynamic>> _subscriptionPresets = [
    {
      'name': 'Netflix',
      'amount': 649.0,
      'cycle': BillingCycle.monthly,
      'category': 'Entertainment',
      'icon': Icons.movie_filter_rounded,
    },
    {
      'name': 'Spotify',
      'amount': 199.0,
      'cycle': BillingCycle.monthly,
      'category': 'Entertainment',
      'icon': Icons.music_note_rounded,
    },
    {
      'name': 'Amazon Prime',
      'amount': 1499.0,
      'cycle': BillingCycle.yearly,
      'category': 'Shopping',
      'icon': Icons.shopping_bag_rounded,
    },
    {
      'name': 'Gym & Fitness',
      'amount': 2000.0,
      'cycle': BillingCycle.monthly,
      'category': 'Health & Fitness',
      'icon': Icons.fitness_center_rounded,
    },
    {
      'name': 'YouTube Premium',
      'amount': 149.0,
      'cycle': BillingCycle.monthly,
      'category': 'Entertainment',
      'icon': Icons.play_circle_fill_rounded,
    },
    {
      'name': 'iCloud+ Storage',
      'amount': 219.0,
      'cycle': BillingCycle.monthly,
      'category': 'Bills & Utilities',
      'icon': Icons.cloud_rounded,
    },
  ];

  static const List<String> _categoryOptions = [
    'Entertainment',
    'Bills & Utilities',
    'Health & Fitness',
    'Software & Tech',
    'Shopping',
    'Education',
  ];

  static const List<String> _accountOptions = [
    'HDFC Bank',
    'SBI Savings',
    'Axis Bank',
    'Credit Card',
    'Cash Wallet',
  ];

  static const List<int> _reminderDayOptions = [1, 2, 3, 5, 7];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _amountController = TextEditingController(
      text: widget.initialAmount > 0
          ? _formatNumber(widget.initialAmount)
          : '649',
    );
    _selectedCycle = widget.initialCycle;
    _nextBillingDate = widget.initialNextBillingDate ??
        DateTime.now().add(const Duration(days: 30));
    _reminderDaysBefore = widget.initialReminderDays;
    _autoLogOnRenewal = widget.initialAutoLog;

    _amountController.addListener(_onAmountChanged);
  }

  void _onAmountChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  String _formatNumber(double amount) {
    if (amount == amount.roundToDouble()) {
      return amount.toInt().toString();
    }
    return amount.toStringAsFixed(2);
  }

  double get _currentAmount {
    final clean = _amountController.text.replaceAll(',', '').trim();
    return double.tryParse(clean) ?? 0.0;
  }

  double get _annualCost {
    switch (_selectedCycle) {
      case BillingCycle.weekly:
        return _currentAmount * 52;
      case BillingCycle.monthly:
        return _currentAmount * 12;
      case BillingCycle.quarterly:
        return _currentAmount * 4;
      case BillingCycle.yearly:
        return _currentAmount * 1;
    }
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##,##0.00', 'en_IN');
    return '${widget.currencySymbol}${formatter.format(amount)}';
  }

  String get _annualCommitmentDisplay {
    return 'Annual commitment: ${_formatCurrency(_annualCost)}/year';
  }

  void _applyPreset(Map<String, dynamic> preset) {
    HapticFeedback.lightImpact();
    setState(() {
      _nameController.text = preset['name'] as String;
      final double amt = preset['amount'] as double;
      _amountController.text = _formatNumber(amt);
      _selectedCycle = preset['cycle'] as BillingCycle;
      _selectedCategory = preset['category'] as String;
    });
  }

  Future<void> _pickNextBillingDate() async {
    HapticFeedback.selectionClick();
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _nextBillingDate,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.accentIndigo,
              onPrimary: Colors.white,
              surface: AppColors.surfaceCard,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _nextBillingDate = picked;
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.vibrate();
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isSubmitting = true);

    final sub = Subscription()
      ..name = _nameController.text.trim()
      ..amount = _currentAmount
      ..cycle = _selectedCycle
      ..nextBillingDate = _nextBillingDate
      ..reminderDaysBefore = _reminderDaysBefore
      ..autoLogOnRenewal = _autoLogOnRenewal
      ..isActive = true;

    try {
      if (widget.onSave != null) {
        await widget.onSave!(sub);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${sub.name} subscription saved (${_formatCurrency(_annualCost)}/yr)',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
        Navigator.of(context).pop(sub);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.expenseRed,
            content: Text('Failed to save subscription: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      backgroundColor: AppColors.darkSlateBackground,
      appBar: AppBar(
        title: const Text(
          'New Subscription',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.surfaceCard,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                children: [
                  // Quick Preset Chips Section
                  _buildPresetsSection(),

                  const SizedBox(height: 20),

                  // Subscription Name & Amount Card
                  _buildNameAndAmountCard(),

                  const SizedBox(height: 16),

                  // Billing Cycle Segmented Selector
                  _buildCycleSelectorCard(),

                  const SizedBox(height: 16),

                  // Renewal Date & Reminder Card
                  _buildScheduleCard(dateFormat),

                  const SizedBox(height: 16),

                  // Category & Account Metadata
                  _buildMetadataCard(),

                  const SizedBox(height: 24),
                ],
              ),
            ),

            // Dynamic Annual Metric Footer Card
            _buildAnnualCommitmentFooterCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'POPULAR PRESETS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _subscriptionPresets.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final preset = _subscriptionPresets[index];
              final bool isSelected = _nameController.text.trim() == preset['name'];

              return ChoiceChip(
                key: Key('preset_${preset['name']}'),
                selected: isSelected,
                avatar: Icon(
                  preset['icon'] as IconData,
                  size: 16,
                  color: isSelected ? Colors.white : AppColors.indigoLight,
                ),
                label: Text(
                  preset['name'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                backgroundColor: AppColors.surfaceCard,
                selectedColor: AppColors.accentIndigo,
                side: BorderSide(
                  color: isSelected ? AppColors.accentIndigo : AppColors.borderStroke,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                onSelected: (_) => _applyPreset(preset),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNameAndAmountCard() {
    return Material(
      color: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        side: BorderSide(color: AppColors.borderStroke),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subscription Name Input
            const Text(
              'Subscription Name',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: const Key('subscription_name_input'),
              controller: _nameController,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'e.g. Netflix, Spotify, Gym',
                hintStyle: const TextStyle(color: AppColors.textDisabled),
                prefixIcon: const Icon(Icons.stars_rounded, color: AppColors.accentIndigo),
                filled: true,
                fillColor: AppColors.surfaceCardHover,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderStroke),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderStroke),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.accentIndigo, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a subscription name';
                }
                return null;
              },
            ),

            const SizedBox(height: 18),

            // Billing Amount Input
            const Text(
              'Billing Amount',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: const Key('subscription_amount_input'),
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: 0.5,
              ),
              decoration: InputDecoration(
                prefixIcon: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Text(
                    widget.currencySymbol,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.accentIndigo,
                    ),
                  ),
                ),
                suffixText: '/ ${_selectedCycle.name}',
                suffixStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
                hintText: '0.00',
                hintStyle: const TextStyle(color: AppColors.textDisabled),
                filled: true,
                fillColor: AppColors.surfaceCardHover,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderStroke),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderStroke),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.accentIndigo, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter billing amount';
                }
                final double? parsed = double.tryParse(value.replaceAll(',', ''));
                if (parsed == null || parsed <= 0) {
                  return 'Please enter a valid amount greater than 0';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCycleSelectorCard() {
    return Material(
      color: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        side: BorderSide(color: AppColors.borderStroke),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.repeat_rounded, size: 16, color: AppColors.indigoLight),
                SizedBox(width: 8),
                Text(
                  'BILLING FREQUENCY',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: BillingCycle.values.map((cycle) {
                final bool isSelected = _selectedCycle == cycle;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: InkWell(
                      key: Key('cycle_option_${cycle.name}'),
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedCycle = cycle);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.accentIndigo
                              : AppColors.surfaceCardHover,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.accentIndigo
                                : AppColors.borderStroke,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          cycle.name[0].toUpperCase() + cycle.name.substring(1),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleCard(DateFormat dateFormat) {
    return Material(
      color: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        side: BorderSide(color: AppColors.borderStroke),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.event_note_rounded, size: 16, color: AppColors.indigoLight),
                SizedBox(width: 8),
                Text(
                  'RENEWAL SCHEDULE & REMINDERS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Next Billing Date Button
            InkWell(
              key: const Key('next_billing_date_button'),
              borderRadius: BorderRadius.circular(12),
              onTap: _pickNextBillingDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCardHover,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderStroke),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.accentIndigo),
                        SizedBox(width: 10),
                        Text(
                          'Next Billing Date',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      dateFormat.format(_nextBillingDate),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.indigoLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Reminder selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Remind me before renewal:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                Row(
                  children: _reminderDayOptions.map((days) {
                    final bool isSelected = _reminderDaysBefore == days;
                    return Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: InkWell(
                        key: Key('reminder_days_$days'),
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _reminderDaysBefore = days);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.accentIndigo.withValues(alpha: 0.2)
                                : AppColors.surfaceCardHover,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.accentIndigo
                                  : AppColors.borderStroke,
                            ),
                          ),
                          child: Text(
                            '${days}d',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected ? AppColors.indigoLight : AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataCard() {
    return Material(
      color: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        side: BorderSide(color: AppColors.borderStroke),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Selector
            const Text(
              'Expense Category',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceCardHover,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderStroke),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  key: const Key('category_dropdown'),
                  value: _selectedCategory,
                  isExpanded: true,
                  dropdownColor: AppColors.surfaceCardElevated,
                  icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textSecondary),
                  items: _categoryOptions.map((cat) {
                    return DropdownMenuItem<String>(
                      value: cat,
                      child: Text(
                        cat,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedCategory = val);
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Payment Account Selector
            const Text(
              'Payment Source Account',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceCardHover,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderStroke),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  key: const Key('account_dropdown'),
                  value: _selectedAccount,
                  isExpanded: true,
                  dropdownColor: AppColors.surfaceCardElevated,
                  icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textSecondary),
                  items: _accountOptions.map((acc) {
                    return DropdownMenuItem<String>(
                      value: acc,
                      child: Text(
                        acc,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedAccount = val);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.borderStroke),
            const SizedBox(height: 12),
            // Phase 37: Auto-Log on Renewal Date Toggle
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Auto-Log on Renewal Date',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Automatically record transaction & deduct ledger balance on billing date without manual prompt',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Switch.adaptive(
                  key: const Key('switch_auto_log_renewal'),
                  value: _autoLogOnRenewal,
                  activeColor: AppColors.accentIndigo,
                  onChanged: (bool val) {
                    HapticFeedback.selectionClick();
                    setState(() => _autoLogOnRenewal = val);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnualCommitmentFooterCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: const Border(top: BorderSide(color: AppColors.borderStroke, width: 1.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dynamic Live Metric Highlight Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E294B), Color(0xFF19223D)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accentIndigo.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accentIndigo.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_graph_rounded,
                      color: AppColors.indigoLight,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _annualCommitmentDisplay,
                      key: const Key('annual_commitment_text'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Save Subscription Primary Button
            ElevatedButton(
              key: const Key('save_subscription_button'),
              onPressed: _isSubmitting ? null : _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentIndigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Save Subscription',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
