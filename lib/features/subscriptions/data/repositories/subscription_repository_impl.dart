import 'package:finance_app/features/subscriptions/domain/models/subscription_model.dart';
import 'package:finance_app/features/subscriptions/domain/repositories/subscription_repository.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final List<SubscriptionModel> _subscriptions = [];

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
