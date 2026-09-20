import 'package:finance_app/features/accounts/data/models/account.dart';
import 'package:finance_app/features/categories/data/models/category.dart';
import 'package:isar/isar.dart';

part 'subscription.g.dart';

/// Billing frequency cycle for recurring subscriptions.
enum BillingCycle {
  weekly,
  monthly,
  quarterly,
  yearly,
}

/// Isar database collection model representing a recurring subscription.
@collection
class Subscription {
  Id id = Isar.autoIncrement;

  /// Subscription display name e.g., "Netflix", "Spotify", "Gym".
  late String name;

  /// Recurring billing cost amount.
  late double amount;

  /// Frequency cycle: weekly, monthly, quarterly, yearly.
  @Enumerated(EnumType.name)
  late BillingCycle cycle;

  /// Next scheduled billing charge date.
  late DateTime nextBillingDate;

  /// Number of days before the billing date to notify the user.
  late int reminderDaysBefore;

  /// Active status flag of the subscription.
  bool isActive = true;

  /// Linked expense category.
  final category = IsarLink<Category>();

  /// Linked payment source account.
  final account = IsarLink<Account>();
}
