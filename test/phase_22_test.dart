import 'package:finance_app/core/theme/app_theme.dart';
import 'package:finance_app/features/automation/data/notification_listener_repo.dart';
import 'package:finance_app/features/automation/domain/models/parsed_transaction.dart';
import 'package:finance_app/features/automation/domain/payment_app_filter.dart';
import 'package:finance_app/features/automation/presentation/screens/notification_consent_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 22: Target Payment Apps Package Filter Unit Tests', () {
    test('PaymentAppFilter contains exact whitelisted packages', () {
      expect(
        PaymentAppFilter.paymentApps,
        equals(const {
          'com.google.android.apps.nbu.paisa.user': 'Google Pay',
          'com.phonepe.app': 'PhonePe',
          'net.one97.paytm': 'Paytm',
          'in.org.npci.upiapp': 'BHIM',
          'in.amazon.mShop.android.shopping': 'Amazon Pay',
        }),
      );
    });

    test('isWhitelisted returns true for verified payment apps and false for others', () {
      expect(PaymentAppFilter.isWhitelisted('com.google.android.apps.nbu.paisa.user'), isTrue);
      expect(PaymentAppFilter.isWhitelisted('com.phonepe.app'), isTrue);
      expect(PaymentAppFilter.isWhitelisted('net.one97.paytm'), isTrue);
      expect(PaymentAppFilter.isWhitelisted('in.org.npci.upiapp'), isTrue);
      expect(PaymentAppFilter.isWhitelisted('in.amazon.mShop.android.shopping'), isTrue);

      // Non-payment apps should be rejected
      expect(PaymentAppFilter.isWhitelisted('com.whatsapp'), isFalse);
      expect(PaymentAppFilter.isWhitelisted('com.facebook.orca'), isFalse);
      expect(PaymentAppFilter.isWhitelisted('org.telegram.messenger'), isFalse);
      expect(PaymentAppFilter.isWhitelisted('com.instagram.android'), isFalse);
      expect(PaymentAppFilter.isWhitelisted(null), isFalse);
    });

    test('getAppName resolves display name correctly', () {
      expect(PaymentAppFilter.getAppName('com.google.android.apps.nbu.paisa.user'), equals('Google Pay'));
      expect(PaymentAppFilter.getAppName('com.phonepe.app'), equals('PhonePe'));
      expect(PaymentAppFilter.getAppName('net.one97.paytm'), equals('Paytm'));
      expect(PaymentAppFilter.getAppName('in.org.npci.upiapp'), equals('BHIM'));
      expect(PaymentAppFilter.getAppName('in.amazon.mShop.android.shopping'), equals('Amazon Pay'));
      expect(PaymentAppFilter.getAppName('com.random.app'), isNull);
      expect(PaymentAppFilter.getAppName(null), isNull);
    });

    test('NotificationListenerRepo filters incoming events by package whitelist', () async {
      final repo = NotificationListenerRepo();
      await repo.startListening();

      final List<ParsedTransaction> emitted = [];
      final subscription = repo.onTransactionReceived.listen(emitted.add);

      // 1. Whitelisted payment app (Google Pay)
      repo.onNotificationReceived(
        title: 'Google Pay Alert',
        content: 'Paid USD 42.50 to Whole Foods. Reference 9821034',
        packageName: 'com.google.android.apps.nbu.paisa.user',
      );

      // 2. Whitelisted payment app (PhonePe)
      repo.onNotificationReceived(
        title: 'PhonePe',
        content: 'Acct debited by USD 18.00 at Uber Rides',
        packageName: 'com.phonepe.app',
      );

      // 3. Rejected non-whitelisted app (WhatsApp) even if text has financial numbers
      repo.onNotificationReceived(
        title: 'WhatsApp: Bob',
        content: 'Hey, I paid USD 50 for dinner yesterday!',
        packageName: 'com.whatsapp',
      );

      // 4. Rejected non-whitelisted app (Telegram)
      repo.onNotificationReceived(
        title: 'Telegram: Crypto Group',
        content: 'Transferred USD 500 to wallet',
        packageName: 'org.telegram.messenger',
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(emitted.length, equals(2));
      expect(emitted[0].amount, equals(42.50));
      expect(emitted[1].amount, equals(18.00));

      await subscription.cancel();
      repo.dispose();
    });
  });

  group('Phase 22: Consent UX Payment Apps Display Widget Tests', () {
    testWidgets('renders all whitelisted payment app chips', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const NotificationConsentScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Whitelisted Payment Apps (5)'), findsOneWidget);
      expect(find.text('Google Pay'), findsOneWidget);
      expect(find.text('PhonePe'), findsOneWidget);
      expect(find.text('Paytm'), findsOneWidget);
      expect(find.text('BHIM'), findsOneWidget);
      expect(find.text('Amazon Pay'), findsOneWidget);
    });
  });
}
