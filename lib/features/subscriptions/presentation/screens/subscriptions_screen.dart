import 'package:finance_app/core/constants/app_constants.dart';
import 'package:finance_app/core/theme/app_colors.dart';
import 'package:finance_app/core/theme/theme_toggle_button.dart';
import 'package:finance_app/core/utils/currency_formatter.dart';
import 'package:finance_app/core/widgets/dashed_border_container.dart';
import 'package:finance_app/features/subscriptions/data/repositories/subscription_repository_impl.dart';
import 'package:finance_app/features/subscriptions/domain/models/subscription_model.dart';
import 'package:finance_app/features/subscriptions/domain/repositories/subscription_repository.dart';
import 'package:finance_app/features/subscriptions/presentation/widgets/committed_liabilities_card.dart';
import 'package:finance_app/features/subscriptions/presentation/widgets/renewal_calendar.dart';
import 'package:flutter/material.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  final SubscriptionRepository _repository = SubscriptionRepositoryImpl();
  List<SubscriptionModel> _subscriptions = [];
  bool _isLoading = true;
  bool _showCalendarView = true;

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  Future<void> _loadSubscriptions() async {
    final List<SubscriptionModel> list = await _repository.getSubscriptions();
    if (mounted) {
      setState(() {
        _subscriptions = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring Subscriptions'),
        actions: [
          const ThemeToggleButton(),
          IconButton(
            key: const Key('toggle_subscription_view_button'),
            icon: Icon(
              _showCalendarView
                  ? Icons.view_list_rounded
                  : Icons.calendar_month_rounded,
              color: AppColors.indigoLight,
            ),
            tooltip: _showCalendarView ? 'Switch to List View' : 'Switch to Calendar View',
            onPressed: () {
              setState(() => _showCalendarView = !_showCalendarView);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentIndigo))
          : _showCalendarView
              ? ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    CommittedLiabilitiesCard(
                      subscriptions: _subscriptions,
                      availableBalance: 45250.75,
                    ),
                    const SizedBox(height: 16),
                    RenewalCalendar(
                      items: _subscriptions
                          .map((s) => RenewalSubscriptionItem.fromModel(s))
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'ALL SUBSCRIPTIONS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._subscriptions.map((sub) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildSubscriptionTile(sub),
                        )),
                    const SizedBox(height: 60),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: _subscriptions.length + 1,
                  separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 12),
                  itemBuilder: (BuildContext context, int index) {
                    if (index == 0) {
                      return CommittedLiabilitiesCard(
                        subscriptions: _subscriptions,
                        availableBalance: 45250.75,
                      );
                    }
                    final SubscriptionModel sub = _subscriptions[index - 1];
                    return _buildSubscriptionTile(sub);
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add_subscription_fab'),
        onPressed: () async {
          await Navigator.of(context).pushNamed(AppConstants.addSubscriptionRoute);
          _loadSubscriptions();
        },
        backgroundColor: AppColors.accentIndigo,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Subscription', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildSubscriptionTile(SubscriptionModel sub) {
    final bool isPaused = !sub.isActive;
    final Color categoryColor = isPaused
        ? AppColors.textMuted
        : RenewalCalendar.getCategoryColor(sub.categoryName);

    final Widget tileContent = Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: isPaused ? 0.08 : 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isPaused ? Icons.pause_circle_outline_rounded : Icons.repeat_rounded,
              color: categoryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      sub.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isPaused ? AppColors.textMuted : AppColors.textPrimary,
                      ),
                    ),
                    if (isPaused) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.textMuted.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: AppColors.textMuted.withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Text(
                          'PAUSED',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textMuted,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  isPaused
                      ? 'Paused • Notifications silenced'
                      : 'Renews in ${sub.nextBillingDate.difference(DateTime.now()).inDays} days • ${sub.categoryName}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isPaused ? AppColors.textDisabled : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.format(sub.amount),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isPaused ? AppColors.textMuted : AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textMuted,
            size: 20,
          ),
        ],
      ),
    );

    if (isPaused) {
      return DashedBorderContainer(
        key: Key('dashed_subscription_${sub.id}'),
        borderRadius: 16,
        color: AppColors.textMuted,
        backgroundColor: AppColors.surfaceCard.withValues(alpha: 0.6),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.of(context).pushNamed(
                AppConstants.subscriptionDetailRoute,
                arguments: {'subscriptionModel': sub},
              );
            },
            child: tileContent,
          ),
        ),
      );
    }

    return Material(
      color: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderStroke),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).pushNamed(
            AppConstants.subscriptionDetailRoute,
            arguments: {'subscriptionModel': sub},
          );
        },
        child: tileContent,
      ),
    );
  }
}

