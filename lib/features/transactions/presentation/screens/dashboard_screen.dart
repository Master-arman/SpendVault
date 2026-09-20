import 'dart:ui';
import 'package:finance_app/core/constants/app_constants.dart';
import 'package:finance_app/core/theme/app_colors.dart';
import 'package:finance_app/core/theme/interactive_card.dart';
import 'package:finance_app/core/utils/currency_formatter.dart';
import 'package:finance_app/core/widgets/rolling_counter.dart';
import 'package:finance_app/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:finance_app/features/transactions/domain/models/transaction_model.dart';
import 'package:finance_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:finance_app/features/transactions/presentation/widgets/transaction_tile.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Fast Action Item representation for quick executive triggers.
class FastActionItem {
  const FastActionItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

/// Executive Balance Dashboard screen with sticky glassmorphic app bar,
/// 7-day mini-sparkline, and fast action carousel.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    this.initialNetWorth = 51830.35,
    this.sevenDaysSpend = const [45.0, 120.0, 85.0, 240.0, 110.0, 310.0, 195.0],
  });

  final double initialNetWorth;
  final List<double> sevenDaysSpend;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TransactionRepository _repository = TransactionRepositoryImpl();
  List<TransactionModel> _recentTransactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentTransactions();
  }

  Future<void> _loadRecentTransactions() async {
    final List<TransactionModel> list = await _repository.getTransactions();
    if (mounted) {
      setState(() {
        _recentTransactions = list.take(5).toList();
        _isLoading = false;
      });
    }
  }

  List<FastActionItem> _getFastActions(BuildContext context) {
    return [
      FastActionItem(
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
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Inter-Account Transfer Triggered')),
          );
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
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Scanning Inbox for Bank SMS...')),
          );
        },
      ),
      FastActionItem(
        label: 'Export Report',
        icon: Icons.file_download_outlined,
        color: AppColors.successGreen,
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Exporting Financial Ledger Report (PDF/CSV)...')),
          );
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final double total7Days = widget.sevenDaysSpend.fold(0.0, (sum, val) => sum + val);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Sticky Glassmorphic App Bar showing aggregated Net Worth
          SliverAppBar(
            pinned: true,
            expandedHeight: 180,
            backgroundColor: AppColors.darkSlateBackground.withValues(alpha: 0.85),
            elevation: 0,
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
                          AppColors.accentIndigo.withValues(alpha: 0.18),
                          AppColors.darkSlateBackground.withValues(alpha: 0.9),
                        ],
                      ),
                      border: const Border(
                        bottom: BorderSide(
                          color: AppColors.borderStroke,
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
                            const Text(
                              'AGGREGATED NET WORTH',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: AppColors.textMuted,
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
                          value: widget.initialNetWorth,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
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
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderStroke),
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
                                const Text(
                                  '7-Day Outflow Sparkline',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Total: ${CurrencyFormatter.format(total7Days)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
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
                                    widget.sevenDaysSpend.length,
                                    (i) => FlSpot(i.toDouble(), widget.sevenDaysSpend[i]),
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
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('D-6', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                            Text('D-5', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                            Text('D-4', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                            Text('D-3', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                            Text('D-2', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                            Text('Yesterday', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                            Text('Today', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.indigoLight)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Fast Action Carousel (Add Expense, Transfer, Scan SMS, Export Report)
                  const Text(
                    'Fast Actions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
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
                        return SizedBox(
                          width: 110,
                          child: InteractiveCard(
                            onTap: action.onTap,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                            borderRadius: BorderRadius.circular(16),
                            backgroundColor: AppColors.surfaceCard,
                            border: Border.all(color: AppColors.borderStroke),
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
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
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
                      const Text(
                        'Recent Activity',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
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
                  _isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.accentIndigo))
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _recentTransactions.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            return TransactionTile(transaction: _recentTransactions[index]);
                          },
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
