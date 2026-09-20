import 'package:finance_app/features/subscriptions/data/models/subscription.dart' show BillingCycle;
export 'package:finance_app/features/subscriptions/data/models/subscription.dart' show BillingCycle;

/// Domain entity representing a recurring subscription.
class SubscriptionModel {
  const SubscriptionModel({
    required this.id,
    required this.name,
    required this.amount,
    required this.cycle,
    required this.nextBillingDate,
    required this.categoryName,
    this.isActive = true,
    this.autoLogOnRenewal = false,
    this.accountId,
    this.accountName,
  });

  final String id;
  final String name;
  final double amount;
  final BillingCycle cycle;
  final DateTime nextBillingDate;
  final String categoryName;
  final bool isActive;
  final bool autoLogOnRenewal;
  final String? accountId;
  final String? accountName;
}
