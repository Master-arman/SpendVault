import 'package:finance_app/core/theme/app_colors.dart';
import 'package:finance_app/core/utils/currency_formatter.dart';
import 'package:finance_app/features/subscriptions/data/repositories/subscription_repository_impl.dart';
import 'package:finance_app/features/subscriptions/domain/models/subscription_model.dart';
import 'package:finance_app/features/subscriptions/domain/repositories/subscription_repository.dart';
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentIndigo))
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _subscriptions.length,
              separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 12),
              itemBuilder: (BuildContext context, int index) {
                final SubscriptionModel sub = _subscriptions[index];
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
                          color: AppColors.accentIndigo.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.repeat_rounded, color: AppColors.indigoLight, size: 20),
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
                              'Renews in ${sub.nextBillingDate.difference(DateTime.now()).inDays} days • ${sub.cycle.name}',
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
              },
            ),
    );
  }
}
