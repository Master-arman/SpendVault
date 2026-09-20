import 'package:finance_app/core/constants/app_constants.dart';
import 'package:finance_app/core/theme/app_colors.dart';
import 'package:finance_app/core/utils/currency_formatter.dart';
import 'package:finance_app/features/subscriptions/data/repositories/subscription_repository_impl.dart';
import 'package:finance_app/features/subscriptions/domain/models/subscription_model.dart';
import 'package:finance_app/features/subscriptions/domain/repositories/subscription_repository.dart';
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
                  itemCount: _subscriptions.length,
                  separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 12),
                  itemBuilder: (BuildContext context, int index) {
                    final SubscriptionModel sub = _subscriptions[index];
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
    final Color categoryColor =
        RenewalCalendar.getCategoryColor(sub.categoryName);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderStroke),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.repeat_rounded, color: categoryColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sub.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Renews in ${sub.nextBillingDate.difference(DateTime.now()).inDays} days • ${sub.categoryName}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.format(sub.amount),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
