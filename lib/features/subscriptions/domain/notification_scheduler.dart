import 'dart:async';
import 'package:finance_app/features/subscriptions/data/models/subscription.dart';
import 'package:finance_app/features/subscriptions/domain/models/subscription_model.dart';
import 'package:intl/intl.dart';

/// Scheduling mode flags matching Android platform alarm specifications.
enum AndroidScheduleMode {
  exact,
  exactAllowWhileIdle,
  inexact,
  inexactAllowWhileIdle,
}

/// Interpretation mode for local notification scheduled date/time.
enum UILocalNotificationDateInterpretation {
  absoluteTime,
  wallClockTime,
}

/// Notification configuration details container.
class NotificationDetails {
  const NotificationDetails({
    this.channelId = 'subscription_renewals',
    this.channelName = 'Subscription Renewal Alerts',
    this.channelDescription = 'Notifies you before recurring subscriptions charge',
    this.importance = 4, // Importance.high
    this.priority = 1, // Priority.high
  });

  final String channelId;
  final String channelName;
  final String channelDescription;
  final int importance;
  final int priority;
}

/// In-memory scheduled notification record for audit, verification, and dispatch.
class ScheduledNotificationRecord {
  const ScheduledNotificationRecord({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledDate,
    required this.details,
    required this.androidScheduleMode,
    required this.uiLocalNotificationDateInterpretation,
  });

  final int id;
  final String title;
  final String body;
  final DateTime scheduledDate;
  final NotificationDetails details;
  final AndroidScheduleMode androidScheduleMode;
  final UILocalNotificationDateInterpretation uiLocalNotificationDateInterpretation;
}

/// Interface contract for local notification plugins.
abstract class INotificationPluginBridge {
  Future<void> zonedSchedule(
    int id,
    String title,
    String body,
    DateTime scheduledDate,
    NotificationDetails notificationDetails, {
    required AndroidScheduleMode androidScheduleMode,
    required UILocalNotificationDateInterpretation uiLocalNotificationDateInterpretation,
  });

  Future<void> cancel(int id);
  Future<void> cancelAll();
  Future<List<ScheduledNotificationRecord>> getPendingNotificationRequests();
}

/// Default in-memory implementation of the local notifications plugin bridge.
class DefaultNotificationPluginBridge implements INotificationPluginBridge {
  final Map<int, ScheduledNotificationRecord> _scheduledNotifications = {};

  Map<int, ScheduledNotificationRecord> get scheduledNotifications =>
      Map.unmodifiable(_scheduledNotifications);

  @override
  Future<void> zonedSchedule(
    int id,
    String title,
    String body,
    DateTime scheduledDate,
    NotificationDetails notificationDetails, {
    required AndroidScheduleMode androidScheduleMode,
    required UILocalNotificationDateInterpretation uiLocalNotificationDateInterpretation,
  }) async {
    _scheduledNotifications[id] = ScheduledNotificationRecord(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      details: notificationDetails,
      androidScheduleMode: androidScheduleMode,
      uiLocalNotificationDateInterpretation: uiLocalNotificationDateInterpretation,
    );
  }

  @override
  Future<void> cancel(int id) async {
    _scheduledNotifications.remove(id);
  }

  @override
  Future<void> cancelAll() async {
    _scheduledNotifications.clear();
  }

  @override
  Future<List<ScheduledNotificationRecord>> getPendingNotificationRequests() async {
    return _scheduledNotifications.values.toList();
  }
}

/// Phase 34: Local Scheduled Notifications Engine.
/// Schedules exact local notification reminders for upcoming subscription renewals
/// using [AndroidScheduleMode.exactAllowWhileIdle].
class NotificationScheduler {
  NotificationScheduler({
    INotificationPluginBridge? notificationsPlugin,
    NotificationDetails? defaultNotificationDetails,
  })  : _notificationsPlugin =
            notificationsPlugin ?? DefaultNotificationPluginBridge(),
        _defaultDetails =
            defaultNotificationDetails ?? const NotificationDetails();

  final INotificationPluginBridge _notificationsPlugin;
  final NotificationDetails _defaultDetails;

  INotificationPluginBridge get notificationsPlugin => _notificationsPlugin;

  /// Calculates the exact trigger date subtracting reminder days before renewal.
  static DateTime calculateTriggerDate(
    DateTime nextBillingDate,
    int reminderDaysBefore,
  ) {
    return nextBillingDate.subtract(Duration(days: reminderDaysBefore));
  }

  /// Formats the subscription renewal message body:
  /// e.g. "₹649 will be charged on 15 Oct"
  static String formatNotificationBody(
    double amount,
    DateTime nextBillingDate, {
    String currencySymbol = '₹',
  }) {
    final String dateStr = DateFormat('dd MMM').format(nextBillingDate);
    final String amountStr = _formatAmount(amount);
    return '$currencySymbol$amountStr will be charged on $dateStr';
  }

  /// Formats the notification title:
  /// e.g. "Upcoming Renewal: Netflix"
  static String formatNotificationTitle(String subscriptionName) {
    return 'Upcoming Renewal: $subscriptionName';
  }

  static String _formatAmount(double amount) {
    if (amount == amount.roundToDouble()) {
      return amount.toInt().toString();
    }
    return amount.toStringAsFixed(2);
  }

  /// Schedules an exact local notification reminder for a [Subscription] instance.
  /// Trigger Date = nextBillingDate - reminderDaysBefore
  /// Uses [AndroidScheduleMode.exactAllowWhileIdle].
  Future<ScheduledNotificationRecord?> scheduleSubscriptionReminder(
    Subscription subscription, {
    String currencySymbol = '₹',
    NotificationDetails? customDetails,
  }) async {
    if (!subscription.isActive) {
      await cancelReminder(subscription.id);
      return null;
    }

    final DateTime triggerDate = calculateTriggerDate(
      subscription.nextBillingDate,
      subscription.reminderDaysBefore,
    );

    final String title = formatNotificationTitle(subscription.name);
    final String body = formatNotificationBody(
      subscription.amount,
      subscription.nextBillingDate,
      currencySymbol: currencySymbol,
    );

    final NotificationDetails details = customDetails ?? _defaultDetails;

    await _notificationsPlugin.zonedSchedule(
      subscription.id,
      title,
      body,
      triggerDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    return ScheduledNotificationRecord(
      id: subscription.id,
      title: title,
      body: body,
      scheduledDate: triggerDate,
      details: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Schedules a reminder from a [SubscriptionModel] entity.
  Future<ScheduledNotificationRecord?> scheduleModelReminder(
    SubscriptionModel model, {
    int? notificationId,
    int reminderDaysBefore = 3,
    String currencySymbol = '₹',
    NotificationDetails? customDetails,
  }) async {
    if (!model.isActive) return null;

    final int id = notificationId ?? model.id.hashCode.abs();
    final DateTime triggerDate = calculateTriggerDate(
      model.nextBillingDate,
      reminderDaysBefore,
    );

    final String title = formatNotificationTitle(model.name);
    final String body = formatNotificationBody(
      model.amount,
      model.nextBillingDate,
      currencySymbol: currencySymbol,
    );

    final NotificationDetails details = customDetails ?? _defaultDetails;

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      triggerDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    return ScheduledNotificationRecord(
      id: id,
      title: title,
      body: body,
      scheduledDate: triggerDate,
      details: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Cancels a scheduled renewal reminder by [id].
  Future<void> cancelReminder(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  /// Cancels all pending subscription reminders.
  Future<void> cancelAllReminders() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Retrieves all currently pending scheduled reminders.
  Future<List<ScheduledNotificationRecord>> getPendingReminders() async {
    return _notificationsPlugin.getPendingNotificationRequests();
  }
}
