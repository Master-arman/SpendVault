import 'package:finance_app/core/theme/app_colors.dart';
import 'package:finance_app/core/utils/currency_formatter.dart';
import 'package:finance_app/features/subscriptions/data/models/subscription.dart';
import 'package:finance_app/features/subscriptions/domain/models/subscription_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Single item representation for upcoming committed liabilities.
class CommittedLiabilityItem {
  const CommittedLiabilityItem({
    required this.id,
    required this.name,
    required this.amount,
    required this.billingDate,
    required this.categoryName,
    required this.cycle,
    this.isSettled = false,
    this.isActive = true,
  });

  final String id;
  final String name;
  final double amount;
  final DateTime billingDate;
  final String categoryName;
  final BillingCycle cycle;
  final bool isSettled;
  final bool isActive;
}

/// Aggregated calculation projection for monthly committed liabilities.
class CommittedLiabilitiesProjection {
  const CommittedLiabilitiesProjection({
    required this.referenceDate,
    required this.totalMonthlyCommitment,
    required this.upcomingMonthlyCommitment,
    required this.settledMonthlyCommitment,
    required this.availableBalance,
    required this.spendableBalance,
    required this.upcomingItems,
    required this.settledItems,
    required this.activeSubscriptionsCount,
    required this.pausedSubscriptionsCount,
  });

  final DateTime referenceDate;
  final double totalMonthlyCommitment;
  final double upcomingMonthlyCommitment;
  final double settledMonthlyCommitment;
  final double availableBalance;
  final double spendableBalance;
  final List<CommittedLiabilityItem> upcomingItems;
  final List<CommittedLiabilityItem> settledItems;
  final int activeSubscriptionsCount;
  final int pausedSubscriptionsCount;

  int get totalItemsCount => upcomingItems.length + settledItems.length;

  double get settledPercentage => totalMonthlyCommitment > 0
      ? (settledMonthlyCommitment / totalMonthlyCommitment).clamp(0.0, 1.0)
      : 1.0;

  double get commitmentOfBalanceRatio => availableBalance > 0
      ? (upcomingMonthlyCommitment / availableBalance).clamp(0.0, 1.0)
      : 1.0;

  int get daysRemainingInMonth {
    final DateTime endOfMonth = DateTime(referenceDate.year, referenceDate.month + 1, 0);
    return (endOfMonth.day - referenceDate.day + 1).clamp(1, 31);
  }

  double get safeDailySpend =>
      spendableBalance > 0 ? spendableBalance / daysRemainingInMonth : 0.0;
}

/// Calculator engine for Monthly Committed Liabilities projection.
class CommittedLiabilitiesCalculator {
  const CommittedLiabilitiesCalculator._();

  /// Computes monthly projection from a list of subscriptions (supports [SubscriptionModel] & [Subscription]).
  static CommittedLiabilitiesProjection compute({
    required List<dynamic> subscriptions,
    DateTime? referenceDate,
    double availableBalance = 0.0,
  }) {
    final DateTime refDate = referenceDate ?? DateTime.now();
    final int currentYear = refDate.year;
    final int currentMonth = refDate.month;

    double totalMonthlyCommitment = 0.0;
    double upcomingMonthlyCommitment = 0.0;
    double settledMonthlyCommitment = 0.0;

    final List<CommittedLiabilityItem> upcomingItems = [];
    final List<CommittedLiabilityItem> settledItems = [];
    int activeCount = 0;
    int pausedCount = 0;

    for (final dynamic sub in subscriptions) {
      final String id = sub is SubscriptionModel
          ? sub.id
          : (sub is Subscription ? sub.id.toString() : '');
      final String name = sub is SubscriptionModel
          ? sub.name
          : (sub is Subscription ? sub.name : '');
      final double amount = sub is SubscriptionModel
          ? sub.amount
          : (sub is Subscription ? sub.amount : 0.0);
      final BillingCycle cycle = sub is SubscriptionModel
          ? sub.cycle
          : (sub is Subscription ? sub.cycle : BillingCycle.monthly);
      final DateTime nextBillingDate = sub is SubscriptionModel
          ? sub.nextBillingDate
          : (sub is Subscription ? sub.nextBillingDate : DateTime.now());
      final String categoryName = sub is SubscriptionModel
          ? sub.categoryName
          : (sub is Subscription ? (sub.category.value?.name ?? 'General') : 'General');
      final bool isActive = sub is SubscriptionModel
          ? sub.isActive
          : (sub is Subscription ? sub.isActive : true);

      if (!isActive) {
        pausedCount++;
        continue;
      }
      activeCount++;

      // Check if this subscription has a billing occurrence in the current calendar month
      final bool isBillingInCurrentMonth =
          nextBillingDate.year == currentYear && nextBillingDate.month == currentMonth;

      // For monthly subscriptions, if next billing is next month, this month's bill may have already settled
      // If next billing is in current month:
      if (isBillingInCurrentMonth) {
        final bool isUpcoming = nextBillingDate.day >= refDate.day;
        final item = CommittedLiabilityItem(
          id: id,
          name: name,
          amount: amount,
          billingDate: nextBillingDate,
          categoryName: categoryName,
          cycle: cycle,
          isSettled: !isUpcoming,
          isActive: isActive,
        );

        totalMonthlyCommitment += amount;
        if (isUpcoming) {
          upcomingMonthlyCommitment += amount;
          upcomingItems.add(item);
        } else {
          settledMonthlyCommitment += amount;
          settledItems.add(item);
        }
      } else if (cycle == BillingCycle.monthly) {
        // If it's a monthly cycle and next billing is in a future month (e.g. next month),
        // it means the charge for current month was already settled earlier
        if (nextBillingDate.isAfter(refDate)) {
          final DateTime settledDateThisMonth =
              DateTime(currentYear, currentMonth, nextBillingDate.day.clamp(1, 28));
          if (settledDateThisMonth.isBefore(refDate) || settledDateThisMonth.day <= refDate.day) {
            totalMonthlyCommitment += amount;
            settledMonthlyCommitment += amount;
            settledItems.add(
              CommittedLiabilityItem(
                id: id,
                name: name,
                amount: amount,
                billingDate: settledDateThisMonth,
                categoryName: categoryName,
                cycle: cycle,
                isSettled: true,
                isActive: isActive,
              ),
            );
          } else {
            // Falls in the remaining part of current month
            totalMonthlyCommitment += amount;
            upcomingMonthlyCommitment += amount;
            upcomingItems.add(
              CommittedLiabilityItem(
                id: id,
                name: name,
                amount: amount,
                billingDate: settledDateThisMonth,
                categoryName: categoryName,
                cycle: cycle,
                isSettled: false,
                isActive: isActive,
              ),
            );
          }
        }
      }
    }

    // Sort upcoming items chronologically by billing date
    upcomingItems.sort((a, b) => a.billingDate.compareTo(b.billingDate));
    settledItems.sort((a, b) => a.billingDate.compareTo(b.billingDate));

    final double spendableBalance = availableBalance - upcomingMonthlyCommitment;

    return CommittedLiabilitiesProjection(
      referenceDate: refDate,
      totalMonthlyCommitment: totalMonthlyCommitment,
      upcomingMonthlyCommitment: upcomingMonthlyCommitment,
      settledMonthlyCommitment: settledMonthlyCommitment,
      availableBalance: availableBalance,
      spendableBalance: spendableBalance,
      upcomingItems: upcomingItems,
      settledItems: settledItems,
      activeSubscriptionsCount: activeCount,
      pausedSubscriptionsCount: pausedCount,
    );
  }
}

/// Phase 40: Monthly Committed Liabilities Widget.
///
/// Computes total upcoming fixed recurring payments for the current calendar month
/// to display alongside the user's spendable balance.
class CommittedLiabilitiesCard extends StatefulWidget {
  const CommittedLiabilitiesCard({
    required this.subscriptions,
    this.availableBalance = 50000.0,
    this.referenceDate,
    this.onTap,
    this.title = 'Monthly Committed Liabilities',
    this.initiallyExpanded = false,
    super.key,
  });

  final List<dynamic> subscriptions;
  final double availableBalance;
  final DateTime? referenceDate;
  final VoidCallback? onTap;
  final String title;
  final bool initiallyExpanded;

  @override
  State<CommittedLiabilitiesCard> createState() => _CommittedLiabilitiesCardState();
}

class _CommittedLiabilitiesCardState extends State<CommittedLiabilitiesCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final CommittedLiabilitiesProjection projection = CommittedLiabilitiesCalculator.compute(
      subscriptions: widget.subscriptions,
      referenceDate: widget.referenceDate,
      availableBalance: widget.availableBalance,
    );

    final DateFormat monthFormat = DateFormat('MMMM yyyy');
    final String currentMonthLabel = monthFormat.format(projection.referenceDate);

    return Container(
      key: const Key('committed_liabilities_card'),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderStroke, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: widget.onTap ?? () => setState(() => _isExpanded = !_isExpanded),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header badge and month label
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.accentIndigo.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.shield_outlined,
                            size: 18,
                            color: AppColors.accentIndigo,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.2,
                              ),
                            ),
                            Text(
                              currentMonthLabel,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      key: const Key('toggle_breakdown_button'),
                      icon: Icon(
                        _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        color: AppColors.indigoLight,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Primary Metrics Split: Spendable Balance & Upcoming Committed
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.darkSlateBackground.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.borderStroke.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Spendable Balance
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SAFE SPENDABLE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: AppColors.indigoLight,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              CurrencyFormatter.format(projection.spendableBalance),
                              key: const Key('spendable_balance_text'),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${CurrencyFormatter.format(projection.safeDailySpend)}/day safe',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 40,
                        width: 1,
                        color: AppColors.borderStroke,
                      ),
                      const SizedBox(width: 14),

                      // Upcoming Committed
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'UPCOMING BILLS',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: AppColors.warningAmber,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              CurrencyFormatter.format(projection.upcomingMonthlyCommitment),
                              key: const Key('upcoming_commitments_text'),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.warningAmber,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${projection.upcomingItems.length} recurring due',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Visual Progress Gauge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Commitment: ${CurrencyFormatter.format(projection.totalMonthlyCommitment)}',
                          key: const Key('total_monthly_commitment_text'),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '${(projection.settledPercentage * 100).toInt()}% Discharged',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.indigoLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Stack(
                        children: [
                          Container(
                            height: 6,
                            width: double.infinity,
                            color: AppColors.borderStroke,
                          ),
                          FractionallySizedBox(
                            widthFactor: projection.settledPercentage,
                            child: Container(
                              height: 6,
                              decoration: const BoxDecoration(
                                gradient: AppColors.primaryGradient,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Expanded Breakdown List of Upcoming Obligations
                if (_isExpanded) ...[
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.borderStroke, height: 1),
                  const SizedBox(height: 12),
                  const Text(
                    'UPCOMING COMMITMENTS BREAKDOWN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.9,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (projection.upcomingItems.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                      decoration: BoxDecoration(
                        color: AppColors.successGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle_rounded, size: 16, color: AppColors.successGreen),
                          SizedBox(width: 8),
                          Text(
                            'All committed liabilities for this month are settled!',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.successGreen,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...projection.upcomingItems.map((item) => _buildBreakdownRow(item)),

                  if (projection.settledItems.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'SETTLED EARLIER THIS MONTH',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.7,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...projection.settledItems.map((item) => _buildBreakdownRow(item, isSettled: true)),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBreakdownRow(CommittedLiabilityItem item, {bool isSettled = false}) {
    final DateFormat dayFormat = DateFormat('MMM d');
    final String dateStr = dayFormat.format(item.billingDate);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSettled ? AppColors.successGreen : AppColors.warningAmber,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                item.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSettled ? AppColors.textMuted : AppColors.textPrimary,
                  decoration: isSettled ? TextDecoration.lineThrough : null,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.borderStroke.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.indigoLight,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                CurrencyFormatter.format(item.amount),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isSettled ? AppColors.textMuted : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
