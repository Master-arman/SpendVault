import 'package:finance_app/features/automation/data/notification_listener_repo.dart';
import 'package:finance_app/features/automation/domain/models/parsed_transaction.dart';
import 'package:finance_app/features/automation/domain/notification_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 23: Deterministic Payment Notification Parser Unit Tests', () {
    const parser = NotificationParser();

    group('Indian Numeric Comma Normalizer', () {
      test('strips commas in standard and Indian numbering formats', () {
        expect(NotificationParser.normalizeAmount('1,250.00'), equals(1250.00));
        expect(NotificationParser.normalizeAmount('1,50,000.50'), equals(150000.50));
        expect(NotificationParser.normalizeAmount('₹12,34,567.89'), equals(1234567.89));
        expect(NotificationParser.normalizeAmount('Rs. 500'), equals(500.0));
        expect(NotificationParser.normalizeAmount('  ₹ 99.00  '), equals(99.00));
        expect(NotificationParser.normalizeAmount('invalid'), isNull);
        expect(NotificationParser.normalizeAmount(''), isNull);
        expect(NotificationParser.normalizeAmount(null), isNull);
      });
    });

    group('Google Pay Deterministic Parsing', () {
      test('parses Paid ₹X to Merchant correctly', () {
        final result = parser.parse(
          'Paid ₹1,250.00 to Chai Point',
          packageName: 'com.google.android.apps.nbu.paisa.user',
        );

        expect(result, isNotNull);
        expect(result!.amount, equals(1250.00));
        expect(result.merchant, equals('Chai Point'));
        expect(result.type, equals(TransactionType.debit));
        expect(result.currency, equals('INR'));
      });

      test('parses Sent Rs. X to Merchant correctly', () {
        final result = parser.parse(
          'Sent Rs. 500 to Ramesh Kumar',
          packageName: 'com.google.android.apps.nbu.paisa.user',
        );

        expect(result, isNotNull);
        expect(result!.amount, equals(500.0));
        expect(result.merchant, equals('Ramesh Kumar'));
        expect(result.type, equals(TransactionType.debit));
      });

      test('parses Paid X to Merchant without symbol', () {
        final result = parser.parse(
          'Paid 3,450.50 to Flipkart',
        );

        expect(result, isNotNull);
        expect(result!.amount, equals(3450.50));
        expect(result.merchant, equals('Flipkart'));
        expect(result.type, equals(TransactionType.debit));
      });
    });

    group('PhonePe Deterministic Parsing', () {
      test('parses Payment of ₹X to Merchant successful', () {
        final result = parser.parse(
          'Payment of ₹2,500.00 to Starbucks successful',
          packageName: 'com.phonepe.app',
        );

        expect(result, isNotNull);
        expect(result!.amount, equals(2500.00));
        expect(result.merchant, equals('Starbucks'));
        expect(result.type, equals(TransactionType.debit));
      });

      test('parses Payment of Rs. X to Merchant successful with commas', () {
        final result = parser.parse(
          'Payment of Rs. 15,200.75 to Apple Store successful',
          packageName: 'com.phonepe.app',
        );

        expect(result, isNotNull);
        expect(result!.amount, equals(15200.75));
        expect(result.merchant, equals('Apple Store'));
        expect(result.type, equals(TransactionType.debit));
      });
    });

    group('Paytm Deterministic Parsing', () {
      test('parses Paid ₹X successfully to Merchant', () {
        final result = parser.parse(
          'Paid ₹1,250.00 successfully to Grocery Mart',
          packageName: 'net.one97.paytm',
        );

        expect(result, isNotNull);
        expect(result!.amount, equals(1250.00));
        expect(result.merchant, equals('Grocery Mart'));
        expect(result.type, equals(TransactionType.debit));
      });

      test('parses Paid Rs. X successfully to Merchant', () {
        final result = parser.parse(
          'Paid Rs. 40.00 successfully to Tea Stall',
          packageName: 'net.one97.paytm',
        );

        expect(result, isNotNull);
        expect(result!.amount, equals(40.00));
        expect(result.merchant, equals('Tea Stall'));
        expect(result.type, equals(TransactionType.debit));
      });
    });

    group('Invalid & Non-Transaction Notifications', () {
      test('returns null for non-matching notifications', () {
        expect(parser.parse('Reminder: Pay your electricity bill soon'), isNull);
        expect(parser.parse('OTP for payment is 4821'), isNull);
        expect(parser.parse(''), isNull);
      });
    });
  });

  group('Phase 23: NotificationListenerRepo Integration with Deterministic Parser', () {
    test('receives and emits transactions for all payment app templates', () async {
      final repo = NotificationListenerRepo();
      await repo.startListening();

      final List<ParsedTransaction> emitted = [];
      final subscription = repo.onTransactionReceived.listen(emitted.add);

      // Google Pay
      repo.onNotificationReceived(
        title: 'Google Pay',
        content: 'Paid ₹1,250.00 to Cafe Coffee Day',
        packageName: 'com.google.android.apps.nbu.paisa.user',
      );

      // PhonePe
      repo.onNotificationReceived(
        title: 'PhonePe',
        content: 'Payment of ₹850.00 to Swiggy successful',
        packageName: 'com.phonepe.app',
      );

      // Paytm
      repo.onNotificationReceived(
        title: 'Paytm',
        content: 'Paid ₹350.00 successfully to Uber',
        packageName: 'net.one97.paytm',
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(emitted.length, equals(3));
      expect(emitted[0].amount, equals(1250.00));
      expect(emitted[0].merchant, equals('Cafe Coffee Day'));
      expect(emitted[1].amount, equals(850.00));
      expect(emitted[1].merchant, equals('Swiggy'));
      expect(emitted[2].amount, equals(350.00));
      expect(emitted[2].merchant, equals('Uber'));

      await subscription.cancel();
      repo.dispose();
    });
  });
}
