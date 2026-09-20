import 'package:finance_app/features/subscriptions/domain/models/subscription_model.dart';

abstract class SubscriptionRepository {
  Future<List<SubscriptionModel>> getSubscriptions();
  Future<void> addSubscription(SubscriptionModel subscription);
  Future<void> cancelSubscription(String id);
}
