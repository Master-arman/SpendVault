import 'package:finance_app/core/widgets/dashed_border_container.dart';
import 'package:finance_app/features/categories/data/models/category.dart';
import 'package:finance_app/features/subscriptions/data/models/subscription.dart';
import 'package:finance_app/features/subscriptions/domain/models/subscription_model.dart';
import 'package:finance_app/features/subscriptions/domain/notification_scheduler.dart';
import 'package:finance_app/features/subscriptions/domain/subscription_freeze_service.dart';
import 'package:finance_app/features/subscriptions/presentation/screens/subscription_detail_screen.dart';
import 'package:finance_app/features/transactions/data/models/transaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class MockNotificationPluginBridge implements INotificationPluginBridge {
  final Map<int, ScheduledNotificationRecord> scheduled = {};
  final List<int> cancelledIds = [];

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
    scheduled[id] = ScheduledNotificationRecord(
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
    scheduled.remove(id);
    cancelledIds.add(id);
  }

  @override
  Future<void> cancelAll() async {
    scheduled.clear();
  }

  @override
  Future<List<ScheduledNotificationRecord>> getPendingNotificationRequests() async {
    return scheduled.values.toList();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 39: Subscription Freezing / Pause Protocol Unit Tests', () {
    late MockNotificationPluginBridge mockBridge;
    late NotificationScheduler scheduler;
    late SubscriptionFreezeService freezeService;

    setUp(() {
      mockBridge = MockNotificationPluginBridge();
      scheduler = NotificationScheduler(notificationsPlugin: mockBridge);
      freezeService = const SubscriptionFreezeService();
    });

    test('Freezing an active Subscription sets isActive=false and cancels scheduled alarms', () async {
      final sub = Subscription()
        ..id = 42
        ..name = 'Netflix Premium'
        ..amount = 649.0
        ..cycle = BillingCycle.monthly
        ..nextBillingDate = DateTime(2026, 10, 1)
        ..reminderDaysBefore = 3
        ..isActive = true;

      // First schedule a reminder
      await scheduler.scheduleSubscriptionReminder(sub);
      expect(mockBridge.scheduled.containsKey(42), isTrue);

      // Now freeze the subscription
      final result = await freezeService.freezeSubscription(
        subscription: sub,
        scheduler: scheduler,
      );

      expect(result.success, isTrue);
      expect(result.isPaused, isTrue);
      expect(result.alarmsSilenced, isTrue);
      expect(sub.isActive, isFalse);
      expect(mockBridge.scheduled.containsKey(42), isFalse);
      expect(mockBridge.cancelledIds, contains(42));
    });

    test('Unfreezing a paused Subscription sets isActive=true and re-schedules reminder', () async {
      final sub = Subscription()
        ..id = 88
        ..name = 'Spotify Family'
        ..amount = 179.0
        ..cycle = BillingCycle.monthly
        ..nextBillingDate = DateTime(2026, 11, 15)
        ..reminderDaysBefore = 2
        ..isActive = false;

      final result = await freezeService.unfreezeSubscription(
        subscription: sub,
        scheduler: scheduler,
      );

      expect(result.success, isTrue);
      expect(result.isPaused, isFalse);
      expect(result.alarmsSilenced, isFalse);
      expect(sub.isActive, isTrue);
      expect(mockBridge.scheduled.containsKey(88), isTrue);
      expect(mockBridge.scheduled[88]!.title, 'Upcoming Renewal: Spotify Family');
    });

    test('freezeModel and unfreezeModel correctly update SubscriptionModel entity', () async {
      final model = SubscriptionModel(
        id: 'sub-gym-100',
        name: 'Gold\'s Gym',
        amount: 2500.0,
        cycle: BillingCycle.monthly,
        nextBillingDate: DateTime(2026, 12, 1),
        categoryName: 'Fitness',
        isActive: true,
      );

      final frozenModel = await freezeService.freezeModel(
        model: model,
        scheduler: scheduler,
        notificationId: 1001,
      );

      expect(frozenModel.isActive, isFalse);
      expect(mockBridge.cancelledIds, contains(1001));

      final resumedModel = await freezeService.unfreezeModel(
        model: frozenModel,
        scheduler: scheduler,
        notificationId: 1001,
      );

      expect(resumedModel.isActive, isTrue);
      expect(mockBridge.scheduled.containsKey(1001), isTrue);
    });

    test('Freezing subscription preserves all past historical transaction records intact', () async {
      final sub = Subscription()
        ..id = 99
        ..name = 'Disney+ Hotstar'
        ..amount = 299.0
        ..cycle = BillingCycle.monthly
        ..nextBillingDate = DateTime(2026, 10, 10)
        ..reminderDaysBefore = 3
        ..isActive = true;

      final historicalTx1 = Transaction()
        ..id = 1
        ..amount = 299.0
        ..timestamp = DateTime(2026, 8, 10)
        ..tags = ['#subscription_99', '#recurring']
        ..note = 'Subscription Renewal: Disney+ Hotstar';

      final historicalTx2 = Transaction()
        ..id = 2
        ..amount = 299.0
        ..timestamp = DateTime(2026, 9, 10)
        ..tags = ['#subscription_99', '#recurring']
        ..note = 'Subscription Renewal: Disney+ Hotstar';

      final historyList = [historicalTx1, historicalTx2];

      // Freeze subscription
      await freezeService.freezeSubscription(
        subscription: sub,
        scheduler: scheduler,
      );

      // Verify records remain intact and unchanged
      expect(historyList.length, 2);
      expect(historyList.first.amount, 299.0);
      expect(historyList.last.amount, 299.0);
      expect(historyList.first.tags, contains('#subscription_99'));
    });
  });

  group('Phase 39: Dashed Border Container & UI Widget Tests', () {
    testWidgets('DashedBorderContainer renders child widget with custom dashed border', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DashedBorderContainer(
              key: Key('test_dashed_box'),
              color: Colors.grey,
              borderRadius: 12,
              child: Text('Paused Item Content'),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('test_dashed_box')), findsOneWidget);
      expect(find.text('Paused Item Content'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('SubscriptionDetailScreen renders DashedBorderContainer when subscription is paused', (tester) async {
      final pausedModel = SubscriptionModel(
        id: 'sub-paused-1',
        name: 'Amazon Prime Video',
        amount: 1499.0,
        cycle: BillingCycle.yearly,
        nextBillingDate: DateTime(2027, 1, 1),
        categoryName: 'Entertainment',
        isActive: false, // PAUSED
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SubscriptionDetailScreen(
            subscriptionModel: pausedModel,
            currencySymbol: '₹',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify PAUSED badge is visible
      expect(find.text('PAUSED'), findsOneWidget);
      expect(find.text('Subscription Paused'), findsOneWidget);

      // Verify dashed border container is rendered for paused hero card
      expect(find.byKey(const Key('paused_hero_dashed_container')), findsOneWidget);
    });

    testWidgets('SubscriptionDetailScreen toggles freeze switch to pause/resume dynamically', (tester) async {
      final mockBridge = MockNotificationPluginBridge();
      final scheduler = NotificationScheduler(notificationsPlugin: mockBridge);

      final activeModel = SubscriptionModel(
        id: 'sub-active-1',
        name: 'YouTube Premium',
        amount: 149.0,
        cycle: BillingCycle.monthly,
        nextBillingDate: DateTime(2026, 10, 5),
        categoryName: 'Entertainment',
        isActive: true, // ACTIVE
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SubscriptionDetailScreen(
            subscriptionModel: activeModel,
            scheduler: scheduler,
            currencySymbol: '₹',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially ACTIVE
      expect(find.text('ACTIVE'), findsOneWidget);
      expect(find.text('Subscription Active'), findsOneWidget);
      expect(find.byKey(const Key('paused_hero_dashed_container')), findsNothing);

      // Tap freeze toggle switch to pause
      final switchFinder = find.byKey(const Key('freeze_switch'));
      expect(switchFinder, findsOneWidget);
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // Now PAUSED
      expect(find.text('PAUSED'), findsOneWidget);
      expect(find.text('Subscription Paused'), findsOneWidget);
      expect(find.byKey(const Key('paused_hero_dashed_container')), findsOneWidget);
      expect(find.text('Subscription paused. Upcoming reminders silenced.'), findsOneWidget);

      // Tap freeze toggle switch again to resume
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // Back to ACTIVE
      expect(find.text('ACTIVE'), findsOneWidget);
      expect(find.text('Subscription Active'), findsOneWidget);
      expect(find.byKey(const Key('paused_hero_dashed_container')), findsNothing);
      expect(find.text('Subscription resumed. Renewal reminder scheduled.'), findsOneWidget);
    });
  });
}
