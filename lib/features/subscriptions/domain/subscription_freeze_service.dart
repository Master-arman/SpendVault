import 'package:finance_app/features/subscriptions/data/models/subscription.dart';
import 'package:finance_app/features/subscriptions/domain/models/subscription_model.dart';
import 'package:finance_app/features/subscriptions/domain/notification_scheduler.dart';
import 'package:isar/isar.dart';

/// Result container for subscription freezing/unfreezing operations.
class FreezeResult {
  const FreezeResult({
    required this.success,
    required this.isPaused,
    required this.alarmsSilenced,
    required this.subscriptionId,
    required this.message,
  });

  final bool success;
  final bool isPaused;
  final bool alarmsSilenced;
  final String subscriptionId;
  final String message;
}

/// Phase 39: Subscription Freezing / Pause Protocol Service.
///
/// Handles toggling [isActive] status:
/// - Pausing (`isActive = false`): Un-schedules upcoming Android alarms, silences notifications,
///   and preserves all historical transaction records without deletion.
/// - Resuming (`isActive = true`): Re-schedules the upcoming renewal reminder.
class SubscriptionFreezeService {
  const SubscriptionFreezeService();

  /// Freezes (pauses) an active [Subscription].
  /// Un-schedules upcoming reminder alarms while keeping past transaction records intact.
  Future<FreezeResult> freezeSubscription({
    required Subscription subscription,
    required NotificationScheduler scheduler,
    Isar? isar,
  }) async {
    subscription.isActive = false;

    // Un-schedule upcoming alarm / local notification
    await scheduler.cancelReminder(subscription.id);

    if (isar != null) {
      await isar.writeTxn(() async {
        await isar.subscriptions.put(subscription);
      });
    }

    return FreezeResult(
      success: true,
      isPaused: true,
      alarmsSilenced: true,
      subscriptionId: subscription.id.toString(),
      message: 'Subscription paused. Upcoming reminders silenced.',
    );
  }

  /// Unfreezes (resumes) a paused [Subscription].
  /// Re-schedules the renewal alarm for the next billing date.
  Future<FreezeResult> unfreezeSubscription({
    required Subscription subscription,
    required NotificationScheduler scheduler,
    Isar? isar,
  }) async {
    subscription.isActive = true;

    // Re-schedule upcoming reminder
    await scheduler.scheduleSubscriptionReminder(subscription);

    if (isar != null) {
      await isar.writeTxn(() async {
        await isar.subscriptions.put(subscription);
      });
    }

    return FreezeResult(
      success: true,
      isPaused: false,
      alarmsSilenced: false,
      subscriptionId: subscription.id.toString(),
      message: 'Subscription resumed. Renewal reminder scheduled.',
    );
  }

  /// Freezes a domain [SubscriptionModel] entity.
  Future<SubscriptionModel> freezeModel({
    required SubscriptionModel model,
    required NotificationScheduler scheduler,
    int? notificationId,
  }) async {
    final int id = notificationId ?? model.id.hashCode.abs();
    await scheduler.cancelReminder(id);

    return SubscriptionModel(
      id: model.id,
      name: model.name,
      amount: model.amount,
      cycle: model.cycle,
      nextBillingDate: model.nextBillingDate,
      categoryName: model.categoryName,
      isActive: false,
      autoLogOnRenewal: model.autoLogOnRenewal,
      accountId: model.accountId,
      accountName: model.accountName,
    );
  }

  /// Resumes a paused domain [SubscriptionModel] entity.
  Future<SubscriptionModel> unfreezeModel({
    required SubscriptionModel model,
    required NotificationScheduler scheduler,
    int? notificationId,
  }) async {
    final int id = notificationId ?? model.id.hashCode.abs();
    final updated = SubscriptionModel(
      id: model.id,
      name: model.name,
      amount: model.amount,
      cycle: model.cycle,
      nextBillingDate: model.nextBillingDate,
      categoryName: model.categoryName,
      isActive: true,
      autoLogOnRenewal: model.autoLogOnRenewal,
      accountId: model.accountId,
      accountName: model.accountName,
    );

    await scheduler.scheduleModelReminder(
      updated,
      notificationId: id,
    );

    return updated;
  }
}
