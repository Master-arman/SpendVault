import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/core/errors/crash_data_sanitizer.dart';
import 'package:finance_app/core/errors/crash_reporting_service.dart';

void main() {
  group('Phase 58 - CrashDataSanitizer Tests', () {
    test('Scrubs Indian Rupee amounts and multi-currency balances', () {
      final input = 'Error in txn: Debited ₹ 1,450.50 from A/C XX9876. Avbl Bal: Rs. 94,320.00, USD \$50.00, EUR 40.00';
      final sanitized = CrashDataSanitizer.sanitize(input);

      expect(sanitized, isNot(contains('1,450.50')));
      expect(sanitized, isNot(contains('94,320.00')));
      expect(sanitized, isNot(contains('50.00')));
      expect(sanitized, isNot(contains('40.00')));
      expect(sanitized, contains('[REDACTED_AMOUNT]'));
      expect(sanitized, contains('[REDACTED_BALANCE]'));
      expect(sanitized, contains('[REDACTED_ACCOUNT]'));
    });

    test('Scrubs bank account numbers and credit/debit card numbers', () {
      final input = 'Failed to charge Card ending in 4321 or raw card 4111-2222-3333-4444 on Account No: 1234567890123';
      final sanitized = CrashDataSanitizer.sanitize(input);

      expect(sanitized, isNot(contains('4321')));
      expect(sanitized, isNot(contains('4111-2222-3333-4444')));
      expect(sanitized, isNot(contains('1234567890123')));
      expect(sanitized, contains('[REDACTED_CARD]'));
      expect(sanitized, contains('[REDACTED_ACCOUNT]'));
    });

    test('Scrubs UPI handles and VPAs', () {
      final input = 'Payment sent to merchant.store@okhdfcbank and john_doe12@paytm via gpay@upi';
      final sanitized = CrashDataSanitizer.sanitize(input);

      expect(sanitized, isNot(contains('merchant.store@okhdfcbank')));
      expect(sanitized, isNot(contains('john_doe12@paytm')));
      expect(sanitized, isNot(contains('gpay@upi')));
      expect(sanitized, contains('[REDACTED_UPI]'));
    });

    test('Scrubs OTPs and SMS notification text', () {
      final input = 'Received SMS body: Your secret OTP is 492810 for txn of Rs. 300. Do not share.';
      final sanitized = CrashDataSanitizer.sanitize(input);

      expect(sanitized, isNot(contains('492810')));
      expect(sanitized, isNot(contains('Rs. 300')));
      expect(sanitized, contains('[REDACTED_OTP]'));
    });

    test('Scrubs user transaction notes and custom remarks', () {
      final input = 'Sqlite exception for note: "Dinner with Sarah and gifts" amount: 450';
      final sanitized = CrashDataSanitizer.sanitize(input);

      expect(sanitized, isNot(contains('Dinner with Sarah and gifts')));
      expect(sanitized, contains('[REDACTED_USER_NOTE]'));
    });

    test('Deeply sanitizes nested Map and List structures', () {
      final metadata = {
        'user_note': 'Secret business trip',
        'account_number': '9876543210',
        'current_balance': '₹ 50,000.00',
        'sms_payload': 'Sent Rs. 500 to rahul@okaxis. Avbl Bal: Rs. 10,000',
        'tags': ['finance', 'Paid Rs. 100 to shop@upi'],
      };

      final sanitized = CrashDataSanitizer.sanitizeValue(metadata) as Map<String, dynamic>;

      expect(sanitized['user_note'], equals('[REDACTED_USER_NOTE]'));
      expect(sanitized['account_number'], equals('[REDACTED_FINANCIAL_ID]'));
      expect(sanitized['current_balance'], equals('[REDACTED_AMOUNT]'));
      expect(sanitized['sms_payload'], equals('[REDACTED_SMS_BODY]'));
      expect(sanitized['tags'][1], contains('[REDACTED_UPI]'));
      expect(sanitized['tags'][1], isNot(contains('rahul@okaxis')));
    });

    test('Sanitizes FlutterErrorDetails without leaking sensitive message info', () {
      final details = FlutterErrorDetails(
        exception: Exception('Database update failed for txn note: Private doctor visit balance: ₹15000'),
        library: 'FinanceLedgerService',
        context: ErrorDescription('Processing transaction with card 4111 2222 3333 4444'),
      );

      final sanitized = CrashDataSanitizer.sanitizeFlutterErrorDetails(details);

      expect(sanitized['exception'], isNot(contains('Private doctor visit')));
      expect(sanitized['exception'], isNot(contains('15000')));
      expect(sanitized['context'], isNot(contains('4111 2222 3333 4444')));
    });
  });

  group('Phase 58 - CrashReportingService Integration', () {
    late InMemoryCrashSink inMemorySink;
    late SentryCrashSink sentrySink;
    late FirebaseCrashlyticsSink firebaseSink;

    setUp(() {
      inMemorySink = InMemoryCrashSink();
      sentrySink = SentryCrashSink();
      firebaseSink = FirebaseCrashlyticsSink();

      CrashReportingService.instance.initialize(
        sinks: [inMemorySink, sentrySink, firebaseSink],
        enableGlobalHandlers: false,
      );
    });

    test('Dispatches sanitized crash reports across all sinks', () async {
      await CrashReportingService.instance.recordError(
        'Transaction failed: Debited Rs. 5000 from A/C 9876543210 for note: Luxury watch',
        StackTrace.current,
        reason: 'Payment to seller@okaxis failed',
        customKeys: {
          'user_note': 'Secret birthday present',
          'amount': 5000,
          'account': 'XX9876',
        },
      );

      // Verify InMemorySink
      expect(inMemorySink.recordedErrors.length, 1);
      final error = inMemorySink.recordedErrors.first;
      expect(error['message'], isNot(contains('5000')));
      expect(error['message'], isNot(contains('9876543210')));
      expect(error['message'], isNot(contains('Luxury watch')));
      expect(error['reason'], isNot(contains('seller@okaxis')));
      expect(error['customKeys']['user_note'], equals('[REDACTED_USER_NOTE]'));

      // Verify SentrySink
      expect(sentrySink.dispatchedEvents.length, 1);
      final sentryEvent = sentrySink.dispatchedEvents.first;
      expect(sentryEvent['message'], isNot(contains('5000')));
      expect(sentryEvent['exception']['value'], isNot(contains('Luxury watch')));

      // Verify FirebaseCrashlyticsSink
      expect(firebaseSink.nonFatalErrors.length, 1);
      final fbError = firebaseSink.nonFatalErrors.first;
      expect(fbError['message'], isNot(contains('9876543210')));
    });

    test('Dispatches sanitized breadcrumbs', () async {
      await CrashReportingService.instance.recordBreadcrumb(
        'Navigated to payment screen with VPA test@okhdfcbank and balance Rs. 10,000',
        category: 'navigation',
        data: {'note': 'Trip expenses'},
      );

      expect(inMemorySink.breadcrumbs.length, 1);
      final bc = inMemorySink.breadcrumbs.first;
      expect(bc['message'], isNot(contains('test@okhdfcbank')));
      expect(bc['message'], isNot(contains('10,000')));
      expect(bc['data']['note'], equals('[REDACTED_USER_NOTE]'));
    });
  });
}
