import 'package:finance_app/core/theme/app_colors.dart';
import 'package:finance_app/core/utils/currency_formatter.dart';
import 'package:finance_app/core/widgets/dashed_border_container.dart';
import 'package:finance_app/features/subscriptions/data/models/subscription.dart';
import 'package:finance_app/features/subscriptions/domain/models/subscription_model.dart';
import 'package:finance_app/features/subscriptions/domain/notification_scheduler.dart';
import 'package:finance_app/features/subscriptions/domain/subscription_freeze_service.dart';
import 'package:finance_app/features/subscriptions/domain/subscription_lifetime_calculator.dart';
import 'package:finance_app/features/subscriptions/presentation/widgets/renewal_calendar.dart';
import 'package:finance_app/features/transactions/data/models/transaction.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Phase 38 & 39: Subscription Detail, Lifetime Spend & Freeze/Pause Screen.
class SubscriptionDetailScreen extends StatefulWidget {
  const SubscriptionDetailScreen({
    super.key,
    this.subscription,
    this.subscriptionModel,
    this.historicalTransactions = const [],
    this.currencySymbol = '₹',
    this.freezeService = const SubscriptionFreezeService(),
    this.scheduler,
  }) : assert(subscription != null || subscriptionModel != null);

  final Subscription? subscription;
  final SubscriptionModel? subscriptionModel;
  final List<Transaction> historicalTransactions;
  final String currencySymbol;
  final SubscriptionFreezeService freezeService;
  final NotificationScheduler? scheduler;

  @override
  State<SubscriptionDetailScreen> createState() => _SubscriptionDetailScreenState();
}

class _SubscriptionDetailScreenState extends State<SubscriptionDetailScreen> {
  late bool _isActive;
  late final NotificationScheduler _scheduler;

  @override
  void initState() {
    super.initState();
    _isActive = widget.subscription != null
        ? widget.subscription!.isActive
        : widget.subscriptionModel!.isActive;
    _scheduler = widget.scheduler ?? NotificationScheduler();
  }

  String get _id =>
      widget.subscription != null ? widget.subscription!.id.toString() : widget.subscriptionModel!.id;

  String get _name =>
      widget.subscription != null ? widget.subscription!.name : widget.subscriptionModel!.name;

  double get _currentAmount =>
      widget.subscription != null ? widget.subscription!.amount : widget.subscriptionModel!.amount;

  BillingCycle get _cycle =>
      widget.subscription != null ? widget.subscription!.cycle : widget.subscriptionModel!.cycle;

  DateTime get _nextBillingDate => widget.subscription != null
      ? widget.subscription!.nextBillingDate
      : widget.subscriptionModel!.nextBillingDate;

  String get _categoryName => widget.subscription != null
      ? (widget.subscription!.category.value?.name ?? 'General')
      : widget.subscriptionModel!.categoryName;

  Future<void> _toggleFreeze(bool value) async {
    if (value) {
      // Resume
      if (widget.subscription != null) {
        await widget.freezeService.unfreezeSubscription(
          subscription: widget.subscription!,
          scheduler: _scheduler,
        );
      } else if (widget.subscriptionModel != null) {
        await widget.freezeService.unfreezeModel(
          model: widget.subscriptionModel!,
          scheduler: _scheduler,
        );
      }
      if (mounted) {
        setState(() => _isActive = true);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Subscription resumed. Renewal reminder scheduled.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    } else {
      // Freeze / Pause
      if (widget.subscription != null) {
        await widget.freezeService.freezeSubscription(
          subscription: widget.subscription!,
          scheduler: _scheduler,
        );
      } else if (widget.subscriptionModel != null) {
        await widget.freezeService.freezeModel(
          model: widget.subscriptionModel!,
          scheduler: _scheduler,
        );
      }
      if (mounted) {
        setState(() => _isActive = false);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Subscription paused. Upcoming reminders silenced.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color categoryColor = _isActive
        ? RenewalCalendar.getCategoryColor(_categoryName)
        : AppColors.textMuted;

    final SubscriptionLifetimeAnalytics analytics =
        SubscriptionLifetimeCalculator.calculateFromTransactions(
      subscriptionId: _id,
      allTransactions: widget.historicalTransactions,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_name),
        elevation: 0,
        actions: [
          IconButton(
            key: const Key('freeze_toggle_action'),
            icon: Icon(
              _isActive ? Icons.pause_circle_outline_rounded : Icons.play_circle_outline_rounded,
              color: _isActive ? AppColors.warningAmber : AppColors.successGreen,
            ),
            tooltip: _isActive ? 'Pause Subscription' : 'Resume Subscription',
            onPressed: () => _toggleFreeze(!_isActive),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── 1. Hero Total Invested Card (with Dashed Border when paused) ───
          _buildHeroInvestedCard(context, analytics, categoryColor),
          const SizedBox(height: 16),

          // ─── 2. Freeze / Pause Control Bar ───
          _buildPauseControlCard(context),
          const SizedBox(height: 20),

          // ─── 3. Price Hike Trajectory Chart ───
          _buildPriceHikeChartSection(context, analytics),
          const SizedBox(height: 24),

          // ─── 4. Historical Transactions Ledger ───
          _buildHistoricalLedgerSection(context, analytics),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildPauseControlCard(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (_isActive ? AppColors.successGreen : AppColors.warningAmber)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _isActive ? Icons.alarm_on_rounded : Icons.alarm_off_rounded,
                color: _isActive ? AppColors.successGreen : AppColors.warningAmber,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isActive ? 'Subscription Active' : 'Subscription Paused',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    _isActive
                        ? 'Renewal notifications and auto-logging active'
                        : 'Alarms silenced • Past transaction logs preserved',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              key: const Key('freeze_switch'),
              value: _isActive,
              activeTrackColor: AppColors.accentIndigo,
              onChanged: _toggleFreeze,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroInvestedCard(
    BuildContext context,
    SubscriptionLifetimeAnalytics analytics,
    Color categoryColor,
  ) {
    final theme = Theme.of(context);
    final double totalDisplay = analytics.totalInvested > 0
        ? analytics.totalInvested
        : _currentAmount;

    final Widget content = Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _isActive ? Icons.repeat_rounded : Icons.pause_circle_outline_rounded,
                      color: categoryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          color: _isActive ? null : AppColors.textMuted,
                        ),
                      ),
                      Text(
                        _categoryName,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _isActive
                      ? AppColors.successGreen.withValues(alpha: 0.15)
                      : AppColors.textMuted.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isActive
                        ? AppColors.successGreen.withValues(alpha: 0.4)
                        : AppColors.textMuted.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  _isActive ? 'ACTIVE' : 'PAUSED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: _isActive ? AppColors.successGreen : AppColors.textMuted,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),

          // TOTAL INVESTED
          Text(
            'TOTAL INVESTED',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.format(totalDisplay, currencySymbol: widget.currencySymbol),
            key: const Key('total_invested_value'),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.0,
              color: _isActive ? AppColors.accentIndigo : AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),

          // Grid metrics
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  context,
                  label: 'Current Rate',
                  value:
                      '${CurrencyFormatter.format(_currentAmount, currencySymbol: widget.currencySymbol)} / ${_cycle.name}',
                ),
              ),
              Expanded(
                child: _buildMetricTile(
                  context,
                  label: _isActive ? 'Next Renewal' : 'Status',
                  value: _isActive
                      ? DateFormat('dd MMM yyyy').format(_nextBillingDate)
                      : 'Paused',
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (!_isActive) {
      return DashedBorderContainer(
        key: const Key('paused_hero_dashed_container'),
        borderRadius: 16,
        color: AppColors.textMuted,
        backgroundColor: theme.cardTheme.color?.withValues(alpha: 0.7) ??
            AppColors.surfaceCard.withValues(alpha: 0.7),
        child: content,
      );
    }

    return Card(child: content);
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceHikeChartSection(
    BuildContext context,
    SubscriptionLifetimeAnalytics analytics,
  ) {
    final theme = Theme.of(context);
    final points = analytics.pricePoints.isNotEmpty
        ? analytics.pricePoints
        : [
            SubscriptionPricePoint(
              date: DateTime.now().subtract(const Duration(days: 90)),
              amount: _currentAmount,
            ),
            SubscriptionPricePoint(
              date: DateTime.now(),
              amount: _currentAmount,
            ),
          ];

    final spots = SubscriptionLifetimeCalculator.generateChartSpots(points);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'PRICE HIKE & RATE TRAJECTORY',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                if (analytics.hasPriceHikes)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warningAmber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.warningAmber.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      '+${analytics.lifetimeHikePercentage.toStringAsFixed(1)}% hike',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.warningAmber,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.successGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.successGreen.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Text(
                      'Stable Price',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.successGreen,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: _currentAmount > 0 ? _currentAmount / 2 : 100,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                      strokeWidth: 1,
                      dashArray: const [4, 4],
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 46,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${widget.currencySymbol}${value.toInt()}',
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final int idx = value.toInt();
                          if (idx >= 0 && idx < points.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                DateFormat('MMM yy').format(points[idx].date),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: false,
                      color: _isActive ? AppColors.accentIndigo : AppColors.textMuted,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          final bool isHike =
                              index < points.length && points[index].isHike;
                          return FlDotCirclePainter(
                            radius: isHike ? 5 : 4,
                            color: isHike ? AppColors.warningAmber : (_isActive ? AppColors.accentIndigo : AppColors.textMuted),
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            (_isActive ? AppColors.accentIndigo : AppColors.textMuted)
                                .withValues(alpha: 0.25),
                            (_isActive ? AppColors.accentIndigo : AppColors.textMuted)
                                .withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoricalLedgerSection(
    BuildContext context,
    SubscriptionLifetimeAnalytics analytics,
  ) {
    final theme = Theme.of(context);
    final transactions = analytics.matchingTransactions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'HISTORICAL RENEWALS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
            Text(
              '${transactions.length} records',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (transactions.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.history_toggle_off_rounded,
                      size: 36,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No historical renewals logged yet',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Renewal deductions will automatically be cataloged here as billing dates pass.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...transactions.reversed.map((dynamic item) {
            final DateTime date =
                item is Transaction ? item.timestamp : ((item as dynamic).date as DateTime);
            final double amount =
                item is Transaction ? item.amount : (((item as dynamic).amount as num).toDouble());
            final String note = (item is Transaction ? item.note : (item as dynamic).note?.toString()) ??
                'Recurring Renewal: $_name';

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Card(
                child: ListTile(
                  dense: true,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accentIndigo.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: AppColors.accentIndigo,
                      size: 18,
                    ),
                  ),
                  title: Text(
                    note,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    DateFormat('dd MMM yyyy, hh:mm a').format(date),
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  trailing: Text(
                    CurrencyFormatter.format(amount, currencySymbol: widget.currencySymbol),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.expenseRed,
                    ),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}
