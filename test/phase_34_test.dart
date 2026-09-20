import 'package:finance_app/features/subscriptions/data/models/subscription.dart';
import 'package:finance_app/features/subscriptions/domain/models/subscription_model.dart';
import 'package:finance_app/features/subscriptions/domain/notification_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  group('Phase 34: Local Scheduled Notifications Engine Tests', () {
    late NotificationScheduler scheduler;
    late DefaultNotificationPluginBridge pluginBridge;

    setUp(() {
      pluginBridge = DefaultNotificationPluginBridge();
      scheduler = NotificationScheduler(notificationsPlugin: pluginBridge);
    });

    test('scheduleSubscriptionReminder calculates correct trigger date and payload with exactAllowWhileIdle',
        () async {
      final nextBillingDate = DateTime(2026, 10, 15);
      final sub = Subscription()
        ..id = 101
        ..name = 'Netflix 4K'
        ..amount = 649.0
        ..cycle = BillingCycle.monthly
        ..nextBillingDate = nextBillingDate
        ..reminderDaysBefore = 3
        ..isActive = true;

      final record = await scheduler.scheduleSubscriptionReminder(sub);

      expect(record, isNotNull);
      expect(record?.id, 101);
      expect(record?.title, 'Upcoming Renewal: Netflix 4K');
      expect(
        record?.body,
        '₹649 will be charged on ${DateFormat('dd MMM').format(nextBillingDate)}',
      );
      // Trigger date = 15 Oct - 3 days = 12 Oct 2026
      expect(record?.scheduledDate, DateTime(2026, 10, 12));
      expect(record?.androidScheduleMode, AndroidScheduleMode.exactAllowWhileIdle);
      expect(
        record?.uiLocalNotificationDateInterpretation,
        UILocalNotificationDateInterpretation.absoluteTime,
      );

      // Verify plugin received the scheduled item
      final pending = await scheduler.getPendingReminders();
      expect(pending.length, 1);
      expect(pending.first.id, 101);
    });

    test('scheduleSubscriptionReminder formats decimal amounts and custom currency symbols',
        () async {
      final nextBillingDate = DateTime(2026, 11, 20);
      final sub = Subscription()
        ..id = 202
        ..name = 'Spotify Family'
        ..amount = 179.99
        ..cycle = BillingCycle.monthly
        ..nextBillingDate = nextBillingDate
        ..reminderDaysBefore = 2
        ..isActive = true;

      final record = await scheduler.scheduleSubscriptionReminder(
        sub,
        currencySymbol: '\$',
      );

      expect(record, isNotNull);
      expect(record?.id, 202);
      expect(
        record?.body,
        '\$179.99 will be charged on ${DateFormat('dd MMM').format(nextBillingDate)}',
      );
      expect(record?.scheduledDate, DateTime(2026, 11, 18));
    });

    test('scheduleSubscriptionReminder cancels reminder if subscription is inactive',
        () async {
      final sub = Subscription()
        ..id = 303
        ..name = 'Gym Membership'
        ..amount = 2000.0
        ..cycle = BillingCycle.monthly
        ..nextBillingDate = DateTime(2026, 10, 1)
        ..reminderDaysBefore = 1
        ..isActive = false;

      final record = await scheduler.scheduleSubscriptionReminder(sub);
      expect(record, isNull);

      final pending = await scheduler.getPendingReminders();
      expect(pending, isEmpty);
    });

    test('cancelReminder and cancelAllReminders remove scheduled notifications properly',
        () async {
      final sub1 = Subscription()
        ..id = 1
        ..name = 'Sub 1'
        ..amount = 100
        ..cycle = BillingCycle.monthly
        ..nextBillingDate = DateTime(2026, 10, 5)
        ..reminderDaysBefore = 1
        ..isActive = true;

      final sub2 = Subscription()
        ..id = 2
        ..name = 'Sub 2'
        ..amount = 200
        ..cycle = BillingCycle.monthly
        ..nextBillingDate = DateTime(2026, 10, 10)
        ..reminderDaysBefore = 2
        ..isActive = true;

      await scheduler.scheduleSubscriptionReminder(sub1);
      await scheduler.scheduleSubscriptionReminder(sub2);

      var pending = await scheduler.getPendingReminders();
      expect(pending.length, 2);

      // Cancel sub 1
      await scheduler.cancelReminder(1);
      pending = await scheduler.getPendingReminders();
      expect(pending.length, 1);
      expect(pending.first.id, 2);

      // Cancel all
      await scheduler.cancelAllReminders();
      pending = await scheduler.getPendingReminders();
      expect(pending, isEmpty);
    });

    test('scheduleModelReminder works for domain SubscriptionModel entity',
        () async {
      final nextBillingDate = DateTime(2026, 12, 1);
      final model = SubscriptionModel(
        id: 'model-404',
        name: 'Amazon Prime',
        amount: 1499.0,
        cycle: BillingCycle.yearly,
        nextBillingDate: nextBillingDate,
        categoryName: 'Shopping',
        isActive: true,
      );

      final record = await scheduler.scheduleModelReminder(
        model,
        notificationId: 404,
        reminderDaysBefore: 7,
      );

      expect(record, isNotNull);
      expect(record?.id, 404);
      expect(record?.title, 'Upcoming Renewal: Amazon Prime');
      expect(
        record?.body,
        '₹1499 will be charged on ${DateFormat('dd MMM').format(nextBillingDate)}',
      );
      // 1 Dec 2026 - 7 days = 24 Nov 2026
      expect(record?.scheduledDate, DateTime(2026, 11, 24));
    });
  });
}
