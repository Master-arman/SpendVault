import 'package:finance_app/features/subscriptions/domain/models/subscription_model.dart';
import 'package:finance_app/features/subscriptions/domain/repositories/subscription_repository.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final List<SubscriptionModel> _subscriptions = [
    SubscriptionModel(
      id: 'sub-1',
      name: 'Netflix Premium (4K)',
      amount: 22.99,
      cycle: BillingCycle.monthly,
      nextBillingDate: DateTime.now().add(const Duration(days: 8)),
      categoryName: 'Entertainment',
    ),
    SubscriptionModel(
      id: 'sub-2',
      name: 'Spotify Family',
      amount: 16.99,
      cycle: BillingCycle.monthly,
      nextBillingDate: DateTime.now().add(const Duration(days: 14)),
      categoryName: 'Entertainment',
    ),
    SubscriptionModel(
      id: 'sub-3',
      name: 'GitHub Copilot / Cloud',
      amount: 19.00,
      cycle: BillingCycle.monthly,
      nextBillingDate: DateTime.now().add(const Duration(days: 21)),
      categoryName: 'Development',
    ),
    SubscriptionModel(
      id: 'sub-4',
      name: 'Amazon Prime Annual',
      amount: 139.00,
      cycle: BillingCycle.yearly,
      nextBillingDate: DateTime.now().add(const Duration(days: 160)),
      categoryName: 'Shopping',
    ),
  ];

  @override
  Future<List<SubscriptionModel>> getSubscriptions() async {
    return List<SubscriptionModel>.unmodifiable(_subscriptions);
  }

  @override
  Future<void> addSubscription(SubscriptionModel subscription) async {
    _subscriptions.add(subscription);
  }

  @override
  Future<void> cancelSubscription(String id) async {
    _subscriptions.removeWhere((SubscriptionModel s) => s.id == id);
  }
}
