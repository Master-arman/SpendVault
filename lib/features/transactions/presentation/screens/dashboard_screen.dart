import 'dart:ui';
import 'package:finance_app/core/constants/app_constants.dart';
import 'package:finance_app/core/theme/app_colors.dart';
import 'package:finance_app/core/theme/interactive_card.dart';
import 'package:finance_app/core/theme/theme_toggle_button.dart';
import 'package:finance_app/core/utils/currency_formatter.dart';
import 'package:finance_app/core/widgets/rolling_counter.dart';
import 'package:finance_app/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:finance_app/features/transactions/domain/models/transaction_model.dart';
import 'package:finance_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:finance_app/features/transactions/presentation/widgets/transaction_tile.dart';
import 'package:finance_app/features/reports/presentation/widgets/export_report_bottom_sheet.dart';
import 'package:finance_app/features/tour/domain/feature_tour_service.dart';
import 'package:finance_app/features/tour/presentation/widgets/feature_spotlight_overlay.dart';
import 'package:finance_app/shared/widgets/empty_state_view.dart';
import 'package:finance_app/shared/widgets/shimmer_loading.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Fast Action Item representation for quick executive triggers.
class FastActionItem {
  const FastActionItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.key,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final Key? key;
}

/// Executive Balance Dashboard screen with sticky glassmorphic app bar,
/// 7-day mini-sparkline, fast action carousel, and first-launch Feature Discovery Tour.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    this.initialNetWorth = 0.0,
    this.sevenDaysSpend = const [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
    this.forceShowTour = false,
    this.disableTour = false,
  });

  final double initialNetWorth;
  final List<double> sevenDaysSpend;
  final bool forceShowTour;
  final bool disableTour;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TransactionRepository _repository = TransactionRepositoryImpl();
  List<TransactionModel> _recentTransactions = [];
  double _calculatedNetWorth = 0.0;
  List<double> _calculatedSevenDaysSpend = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
  bool _isLoading = true;
  bool _showTour = false;

  // GlobalKeys for targeting elements in the Feature Discovery Tour
  final GlobalKey _addTransactionKey = GlobalKey(debugLabel: 'tour_add_transaction');
  final GlobalKey _analyticsDrillDownKey = GlobalKey(debugLabel: 'tour_analytics_drilldown');
  final GlobalKey _notificationToggleKey = GlobalKey(debugLabel: 'tour_notification_toggle');

  @override
  void initState() {
    super.initState();
    _calculatedNetWorth = widget.initialNetWorth;
    _calculatedSevenDaysSpend = List.from(widget.sevenDaysSpend);
    _loadRecentTransactions();
    _checkTourStatus();
  }

  void _checkTourStatus() {
    if (widget.disableTour) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.forceShowTour) {
        if (mounted) setState(() => _showTour = true);
        return;
      }

      final bool hasSeen = await FeatureTourService.instance.hasSeenTour();
      if (!hasSeen && mounted) {
        setState(() => _showTour = true);
      }
    });
  }

  Future<void> _loadRecentTransactions() async {
    final List<TransactionModel> list = await _repository.getTransactions(limit: 500);

    // Calculate dynamic net worth and 7-day spend
    double income = 0.0;
    double expense = 0.0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final List<double> spendPerDay = List.filled(7, 0.0);

    for (final txn in list) {
      if (txn.flow == TransactionFlow.income) {
        income += txn.amount;
      } else if (txn.flow == TransactionFlow.expense) {
        expense += txn.amount;
      }

      final txnDay = DateTime(txn.date.year, txn.date.month, txn.date.day);
      final daysDiff = today.difference(txnDay).inDays;
      if (daysDiff >= 0 && daysDiff < 7 && txn.flow == TransactionFlow.expense) {
        // daysDiff = 0 means today (slot 6), daysDiff = 6 means 6 days ago (slot 0)
        final slot = 6 - daysDiff;
        spendPerDay[slot] += txn.amount;
      }
    }

    final double computedNetWorth = widget.initialNetWorth != 0.0
        ? widget.initialNetWorth
        : (income - expense);

    final bool allZerosWidget = widget.sevenDaysSpend.every((v) => v == 0.0);
    final List<double> finalSpend = allZerosWidget ? spendPerDay : widget.sevenDaysSpend;

    if (mounted) {
      setState(() {
        _recentTransactions = list.take(5).toList();
        _calculatedNetWorth = computedNetWorth;
        _calculatedSevenDaysSpend = finalSpend;
        _isLoading = false;
      });
    }
  }

  List<FeatureTourStep> get _tourSteps => [
        FeatureTourStep(
          targetKey: _addTransactionKey,
          title: 'Quick Add Transaction',
          description:
              'Tap + or Add Expense to instantly record cash, UPI, or card purchases with smart categorization.',
          icon: Icons.add_circle_outline_rounded,
        ),
        FeatureTourStep(
          targetKey: _analyticsDrillDownKey,
          title: 'Analytics Drill-Down',
          description:
              'Tap your 7-day sparkline to inspect detailed cash flow trends, burn rates, and spending distributions.',
          icon: Icons.insights_rounded,
        ),
        FeatureTourStep(
          targetKey: _notificationToggleKey,
          title: 'Smart Notification Sync',
          description:
              'Configure on-device notification parsing to automatically log bank and UPI alerts with 100% privacy.',
          icon: Icons.notifications_active_rounded,
        ),
      ];

  List<FastActionItem> _getFastActions(BuildContext context) {
    return [
      FastActionItem(
        key: const Key('fast_action_add_expense'),
        label: 'Add Expense',
        icon: Icons.add_circle_outline_rounded,
        color: AppColors.expenseRed,
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quick Add Expense Triggered')),
          );
        },
      ),
      FastActionItem(
        label: 'Transfer',
        icon: Icons.swap_horiz_rounded,
        color: AppColors.accentIndigo,
        onTap: () async {
          final result = await Navigator.of(context).pushNamed(AppConstants.transferRoute);
          if (result == true && mounted) {
            _loadRecentTransactions();
          }
        },
      ),
      FastActionItem(
        label: 'Split Bill',
        icon: Icons.call_split_rounded,
        color: AppColors.warningAmber,
        onTap: () {
          Navigator.of(context).pushNamed(AppConstants.splitBillRoute);
        },
      ),
      FastActionItem(
        label: 'Scan SMS',
        icon: Icons.sms_outlined,
        color: AppColors.accentCyan,
        onTap: () async {
          final result = await Navigator.of(context).pushNamed(AppConstants.scanMessageRoute);
          if (result != null && mounted) {
            _loadRecentTransactions();
          }
        },
      ),
      FastActionItem(
        label: 'Export Report',
        icon: Icons.file_download_outlined,
        color: AppColors.successGreen,
        onTap: () async {
          final txns = await _repository.getTransactions();
          if (context.mounted) {
            ExportReportBottomSheet.show(
              context: context,
              transactions: txns,
            );
          }
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final double total7Days = _calculatedSevenDaysSpend.fold(0.0, (sum, val) => sum + val);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = theme.cardTheme.color ?? (isDark ? AppColors.darkCard : AppColors.lightCard);
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Stack(
      children: [
        Scaffold(
          body: CustomScrollView(
            slivers: [
              // Sticky App Bar showing aggregated Net Worth
              SliverAppBar(
                pinned: true,
                expandedHeight: 180,
                backgroundColor: theme.scaffoldBackgroundColor.withValues(alpha: 0.85),
                elevation: 0,
                actions: [
                  IconButton(
                    key: _notificationToggleKey,
                    icon: Icon(
                      Icons.notifications_active_outlined,
                      key: const Key('feature_tour_notification_toggle'),
                      color: theme.colorScheme.onSurface,
                    ),
                    tooltip: 'Notification Consent & Auto-Sync',
                    onPressed: () {
                      Navigator.of(context).pushNamed(AppConstants.notificationConsentRoute);
                    },
                  ),
                  const ThemeToggleButton(),
                  const SizedBox(width: 8),
                ],
                flexibleSpace: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: FlexibleSpaceBar(
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.accentIndigo.withValues(alpha: 0.12),
                              theme.scaffoldBackgroundColor,
                            ],
                          ),
                          border: Border(
                            bottom: BorderSide(
                              color: borderColor,
                              width: 1,
                            ),
                          ),
                        ),
                        padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'AGGREGATED NET WORTH',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.successGreen.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: AppColors.successGreen.withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.arrow_upward_rounded, size: 10, color: AppColors.successGreen),
                                      SizedBox(width: 3),
                                      Text(
                                        '+12.4% MoM',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.successGreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            RollingCounter(
                              value: _calculatedNetWorth,
                              style: theme.textTheme.displayMedium?.copyWith(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.onSurface,
                                letterSpacing: -1,
                              ) ?? const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Main Dashboard Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Visual Mini-Sparkline Card of Last 7 Days' Expenditures
                      GestureDetector(
                        key: const Key('feature_tour_analytics_drilldown'),
                        onTap: () {
                          Navigator.of(context).pushNamed(AppConstants.analyticsRoute);
                        },
                        child: Container(
                          key: _analyticsDrillDownKey,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '7-Day Outflow Sparkline',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Total: ${CurrencyFormatter.format(total7Days)}',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          fontSize: 12,
                                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.accentIndigo.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.show_chart_rounded,
                                      color: AppColors.indigoLight,
                                      size: 18,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                height: 90,
                                child: LineChart(
                                  LineChartData(
                                    gridData: const FlGridData(show: false),
                                    titlesData: const FlTitlesData(show: false),
                                    borderData: FlBorderData(show: false),
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: List.generate(
                                          _calculatedSevenDaysSpend.length,
                                          (i) => FlSpot(i.toDouble(), _calculatedSevenDaysSpend[i]),
                                        ),
                                        isCurved: true,
                                        curveSmoothness: 0.35,
                                        color: AppColors.accentIndigo,
                                        barWidth: 2.8,
                                        isStrokeCapRound: true,
                                        dotData: const FlDotData(show: false),
                                        belowBarData: BarAreaData(
                                          show: true,
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              AppColors.accentIndigo.withValues(alpha: 0.35),
                                              AppColors.accentIndigo.withValues(alpha: 0.0),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('D-6', style: TextStyle(fontSize: 10, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
                                  Text('D-5', style: TextStyle(fontSize: 10, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
                                  Text('D-4', style: TextStyle(fontSize: 10, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
                                  Text('D-3', style: TextStyle(fontSize: 10, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
                                  Text('D-2', style: TextStyle(fontSize: 10, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
                                  Text('Yesterday', style: TextStyle(fontSize: 10, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
                                  const Text('Today', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.indigoLight)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Fast Action Carousel (Add Expense, Transfer, Scan SMS, Export Report)
                      Text(
                        'Fast Actions',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 105,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _getFastActions(context).length,
                          separatorBuilder: (context, index) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final action = _getFastActions(context)[index];
                            final isFirstAction = index == 0;
                            return SizedBox(
                              key: isFirstAction ? _addTransactionKey : null,
                              width: 110,
                              child: InteractiveCard(
                                key: isFirstAction ? const Key('feature_tour_add_transaction') : null,
                                onTap: action.onTap,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                                borderRadius: BorderRadius.circular(16),
                                backgroundColor: cardBg,
                                border: Border.all(color: borderColor),
                                hoverBorder: Border.all(color: action.color),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: action.color.withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(action.icon, color: action.color, size: 20),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      action.label,
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.labelMedium?.copyWith(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Recent Transactions Preview
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Activity',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pushNamed(AppConstants.transactionsRoute);
                            },
                            child: const Text(
                              'View All',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.indigoLight,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildRecentTransactionsSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Feature Discovery Tour Spotlight Overlay
        if (_showTour)
          Positioned.fill(
            child: FeatureSpotlightOverlay(
              steps: _tourSteps,
              onComplete: () {
                FeatureTourService.instance.markTourSeen();
                if (mounted) {
                  setState(() => _showTour = false);
                }
              },
              onSkip: () {
                FeatureTourService.instance.markTourSeen();
                if (mounted) {
                  setState(() => _showTour = false);
                }
              },
            ),
          ),
      ],
    );
  }

  Widget _buildRecentTransactionsSection() {
    if (_isLoading) {
      return const TransactionListSkeleton(itemCount: 3, padding: EdgeInsets.zero);
    }

    if (_recentTransactions.isEmpty) {
      return EmptyStateView.transactions(
        onAddTransaction: () {
          Navigator.of(context).pushNamed(AppConstants.scanMessageRoute);
        },
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _recentTransactions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return TransactionTile(transaction: _recentTransactions[index]);
      },
    );
  }
}
