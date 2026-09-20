import 'package:finance_app/core/theme/app_colors.dart';
import 'package:finance_app/features/subscriptions/data/models/subscription.dart';
import 'package:finance_app/features/subscriptions/domain/models/subscription_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Item representation for subscriptions rendered in the Renewal Calendar.
class RenewalSubscriptionItem {
  const RenewalSubscriptionItem({
    required this.id,
    required this.name,
    required this.amount,
    required this.nextBillingDate,
    this.categoryName = 'General',
    this.cycleName = 'Monthly',
    this.categoryColor,
    this.isActive = true,
  });

  final String id;
  final String name;
  final double amount;
  final DateTime nextBillingDate;
  final String categoryName;
  final String cycleName;
  final Color? categoryColor;
  final bool isActive;

  factory RenewalSubscriptionItem.fromModel(
    SubscriptionModel model, {
    Color? color,
  }) {
    return RenewalSubscriptionItem(
      id: model.id,
      name: model.name,
      amount: model.amount,
      nextBillingDate: model.nextBillingDate,
      categoryName: model.categoryName,
      cycleName: model.cycle.name,
      categoryColor: color ?? RenewalCalendar.getCategoryColor(model.categoryName),
      isActive: model.isActive,
    );
  }

  factory RenewalSubscriptionItem.fromIsar(
    Subscription sub, {
    String? categoryName,
    Color? color,
  }) {
    final String cat = categoryName ?? sub.category.value?.name ?? 'General';
    return RenewalSubscriptionItem(
      id: sub.id.toString(),
      name: sub.name,
      amount: sub.amount,
      nextBillingDate: sub.nextBillingDate,
      categoryName: cat,
      cycleName: sub.cycle.name,
      categoryColor: color ??
          (sub.category.value != null
              ? Color(sub.category.value!.colorHex)
              : RenewalCalendar.getCategoryColor(cat)),
      isActive: sub.isActive,
    );
  }
}

/// Phase 33: Renewal Calendar Visual Matrix.
/// Displays a monthly calendar table where days with scheduled renewals show
/// distinct category-colored dots. Tapping a date opens an informative bottom modal
/// detailing the services charging that day.
class RenewalCalendar extends StatefulWidget {
  const RenewalCalendar({
    super.key,
    required this.items,
    this.initialFocusedDate,
    this.currencySymbol = '₹',
    this.onDateSelected,
  });

  final List<RenewalSubscriptionItem> items;
  final DateTime? initialFocusedDate;
  final String currencySymbol;
  final ValueChanged<DateTime>? onDateSelected;

  static Color getCategoryColor(String category) {
    switch (category.toLowerCase().trim()) {
      case 'entertainment':
        return AppColors.accentViolet; // 0xFF8B5CF6
      case 'bills & utilities':
      case 'utilities':
        return AppColors.accentCyan; // 0xFF06B6D4
      case 'health & fitness':
      case 'fitness':
        return AppColors.successGreen; // 0xFF10B981
      case 'software & tech':
      case 'software':
      case 'development':
        return AppColors.accentIndigo; // 0xFF6366F1
      case 'shopping':
        return AppColors.warningAmber; // 0xFFF59E0B
      case 'food & dining':
      case 'dining':
        return const Color(0xFFF97316); // Accent Orange
      default:
        return AppColors.indigoLight;
    }
  }

  @override
  State<RenewalCalendar> createState() => _RenewalCalendarState();
}

class _RenewalCalendarState extends State<RenewalCalendar> {
  late DateTime _focusedMonth;
  DateTime? _selectedDate;

  static const List<String> _weekDayHeaders = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  void initState() {
    super.initState();
    final DateTime initial = widget.initialFocusedDate ?? DateTime.now();
    _focusedMonth = DateTime(initial.year, initial.month, 1);
    _selectedDate = DateTime(initial.year, initial.month, initial.day);
  }

  List<RenewalSubscriptionItem> _getSubscriptionsForDate(DateTime date) {
    return widget.items.where((item) {
      if (!item.isActive) return false;
      return item.nextBillingDate.year == date.year &&
          item.nextBillingDate.month == date.month &&
          item.nextBillingDate.day == date.day;
    }).toList();
  }

  void _onMonthChanged(int delta) {
    HapticFeedback.selectionClick();
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + delta, 1);
    });
  }

  void _jumpToToday() {
    HapticFeedback.mediumImpact();
    final DateTime now = DateTime.now();
    setState(() {
      _focusedMonth = DateTime(now.year, now.month, 1);
      _selectedDate = DateTime(now.year, now.month, now.day);
    });
  }

  void _handleDayTapped(DateTime date) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedDate = date;
    });

    widget.onDateSelected?.call(date);

    final List<RenewalSubscriptionItem> renewals = _getSubscriptionsForDate(date);
    if (renewals.isNotEmpty) {
      _showRenewalDetailsModal(date, renewals);
    }
  }

  void _showRenewalDetailsModal(
    DateTime date,
    List<RenewalSubscriptionItem> renewals,
  ) {
    final DateFormat fullDateFormat = DateFormat('EEEE, dd MMMM yyyy');
    final double totalDayAmount = renewals.fold(0.0, (sum, i) => sum + i.amount);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext ctx) {
        final formatter = NumberFormat('#,##,##0.00', 'en_IN');
        final formattedTotal =
            '${widget.currencySymbol}${formatter.format(totalDayAmount)}';

        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: AppColors.borderStroke, width: 1.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 20,
                offset: Offset(0, -6),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag handle pill
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderStroke,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Modal Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.accentIndigo.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.event_repeat_rounded,
                                  size: 16,
                                  color: AppColors.indigoLight,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Scheduled Renewals',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            fullDateFormat.format(date),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCardElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.borderStroke),
                      ),
                      child: Text(
                        '$formattedTotal due',
                        key: const Key('modal_total_amount_text'),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppColors.borderStroke),
                const SizedBox(height: 12),

                // Subscriptions List charging that day
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: renewals.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = renewals[index];
                    final Color dotColor = item.categoryColor ??
                        RenewalCalendar.getCategoryColor(item.categoryName);
                    final String itemFormatted =
                        '${widget.currencySymbol}${formatter.format(item.amount)}';

                    return Material(
                      color: AppColors.surfaceCardHover,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: AppColors.borderStroke),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            // Category colored dot indicator
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: dotColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: dotColor.withValues(alpha: 0.4),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${item.categoryName} • ${item.cycleName}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              itemFormatted,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.borderStroke),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat monthFormat = DateFormat('MMMM yyyy');

    final int daysInMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final int firstWeekday =
        DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday; // 1 = Mon, 7 = Sun
    final int prefixEmptyDays = firstWeekday - 1;

    final DateTime now = DateTime.now();

    return Material(
      color: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
        side: BorderSide(color: AppColors.borderStroke),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Month Navigation Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      monthFormat.format(_focusedMonth),
                      key: const Key('calendar_month_year_text'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: _jumpToToday,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accentIndigo.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Today',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.indigoLight,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      key: const Key('prev_month_button'),
                      icon: const Icon(Icons.chevron_left_rounded, color: AppColors.textSecondary, size: 20),
                      onPressed: () => _onMonthChanged(-1),
                      tooltip: 'Previous Month',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                    IconButton(
                      key: const Key('next_month_button'),
                      icon: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
                      onPressed: () => _onMonthChanged(1),
                      tooltip: 'Next Month',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Weekday Abbreviation Headers
            Row(
              children: _weekDayHeaders.map((day) {
                return Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 6),
            const Divider(height: 1, color: AppColors.borderStroke),
            const SizedBox(height: 6),

            // Calendar Visual Matrix Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: prefixEmptyDays + daysInMonth,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                childAspectRatio: 1.15,
              ),
              itemBuilder: (context, index) {
                if (index < prefixEmptyDays) {
                  return const SizedBox.shrink();
                }

                final int dayNumber = index - prefixEmptyDays + 1;
                final DateTime dayDate =
                    DateTime(_focusedMonth.year, _focusedMonth.month, dayNumber);

                final bool isToday = now.year == dayDate.year &&
                    now.month == dayDate.month &&
                    now.day == dayDate.day;

                final bool isSelected = _selectedDate != null &&
                    _selectedDate!.year == dayDate.year &&
                    _selectedDate!.month == dayDate.month &&
                    _selectedDate!.day == dayDate.day;

                final List<RenewalSubscriptionItem> dayRenewals =
                    _getSubscriptionsForDate(dayDate);

                return InkWell(
                  key: Key('calendar_day_$dayNumber'),
                  onTap: () => _handleDayTapped(dayDate),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.accentIndigo.withValues(alpha: 0.25)
                          : isToday
                              ? AppColors.surfaceCardElevated
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.accentIndigo
                            : isToday
                                ? AppColors.indigoLight.withValues(alpha: 0.6)
                                : Colors.transparent,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$dayNumber',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isToday || isSelected
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : isToday
                                    ? AppColors.indigoLight
                                    : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),

                        // Renewal Category Distinct Colored Dots
                        if (dayRenewals.isNotEmpty)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: dayRenewals.take(3).map((item) {
                              final Color dotColor = item.categoryColor ??
                                  RenewalCalendar.getCategoryColor(
                                      item.categoryName);
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 1.0),
                                width: 4.5,
                                height: 4.5,
                                decoration: BoxDecoration(
                                  color: dotColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: dotColor.withValues(alpha: 0.6),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          )
                        else
                          const SizedBox(height: 4.5),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
