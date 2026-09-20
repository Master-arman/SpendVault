import 'package:finance_app/core/theme/app_theme.dart';
import 'package:finance_app/features/automation/data/notification_listener_repo.dart';
import 'package:finance_app/features/automation/domain/models/parsed_transaction.dart';
import 'package:finance_app/features/automation/presentation/screens/notification_consent_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 21: Android Notification Listener Repo Unit Tests', () {
    late NotificationListenerRepo repo;

    setUp(() {
      repo = NotificationListenerRepo();
    });

    tearDown(() {
      repo.dispose();
    });

    test('initial state and permission request', () async {
      expect(repo.isListening, isFalse);
      final bool granted = await repo.requestPermission();
      expect(granted, isTrue);

      await repo.startListening();
      expect(repo.isListening, isTrue);

      await repo.stopListening();
      expect(repo.isListening, isFalse);
    });

    test('onNotificationReceived parses bank debit alert when listening', () async {
      await repo.startListening();

      final List<ParsedTransaction> emitted = [];
      final subscription = repo.onTransactionReceived.listen((tx) {
        emitted.add(tx);
      });

      repo.onNotificationReceived(
        title: 'HDFC Bank Alert',
        content: 'Acct XX1234 debited by USD 85.50 on 12-05-2026 at Starbucks. Avl Bal USD 1200.00',
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(emitted.length, equals(1));
      expect(emitted.first.amount, equals(85.50));
      expect(emitted.first.type, equals(TransactionType.debit));

      await subscription.cancel();
    });

    test('onNotificationReceived ignores personal chat messages and OTPs', () async {
      await repo.startListening();

      final List<ParsedTransaction> emitted = [];
      final subscription = repo.onTransactionReceived.listen((tx) {
        emitted.add(tx);
      });

      // Personal chat message
      repo.onNotificationReceived(
        title: 'WhatsApp: Mom',
        content: 'Hey honey, let me know when you reach home!',
      );

      // OTP password message
      repo.onNotificationReceived(
        title: 'Google Security',
        content: 'Your Google verification code is 492810. Do not share this OTP with anyone.',
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(emitted, isEmpty);

      await subscription.cancel();
    });

    test('onNotificationReceived does not emit when listener is stopped', () async {
      final List<ParsedTransaction> emitted = [];
      final subscription = repo.onTransactionReceived.listen((tx) {
        emitted.add(tx);
      });

      repo.onNotificationReceived(
        title: 'HDFC Bank Alert',
        content: 'Acct XX1234 debited by USD 45.00 at Grocery Mart',
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(emitted, isEmpty);

      await subscription.cancel();
    });
  });

  group('Phase 21: Notification Consent Screen Widget Tests', () {
    testWidgets('renders privacy guarantees, illustration, and handles permission grant',
        (WidgetTester tester) async {
      final repo = NotificationListenerRepo();
      bool callbackFired = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: NotificationConsentScreen(
            repository: repo,
            onPermissionGranted: () {
              callbackFired = true;
            },
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Check key privacy text
      expect(find.text('100% On-Device Privacy'), findsOneWidget);
      expect(find.text('Local Computation Engine'), findsOneWidget);
      expect(find.text('Never Reads Chats, OTPs or Passwords'), findsOneWidget);
      expect(find.text('Bank & UPI Alerts Only'), findsOneWidget);
      expect(find.text('Skip for now'), findsOneWidget);

      // Check Enable button
      final enableButton = find.text('Enable Notification Access');
      expect(enableButton, findsOneWidget);

      // Scroll into view & tap enable button
      await tester.ensureVisible(enableButton);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(enableButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(callbackFired, isTrue);
      expect(repo.isListening, isTrue);
      expect(find.text('Notification Access Active'), findsOneWidget);
    });
  });
}
