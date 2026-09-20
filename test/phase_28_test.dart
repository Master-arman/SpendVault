import 'package:finance_app/features/automation/data/models/sms_audit_log.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 28: Automation Logs & Audit Record Schema Tests', () {
    test('SmsAuditLog model instantiates and stores all required audit properties', () {
      final DateTime now = DateTime.now();
      final log = SmsAuditLog()
        ..rawPayload = 'Paid ₹1,250.00 to Chai Point Bangalore'
        ..parsedAmount = 1250.0
        ..detectedPayee = 'Chai Point Bangalore'
        ..sourcePackageOrSender = 'com.google.android.apps.nbu.paisa.user'
        ..executionState = AuditExecutionState.parsed
        ..timestamp = now
        ..deduplicationHash = 'a1b2c3d4e5f6'
        ..inferredCategory = 'Food & Dining';

      expect(log.rawPayload, equals('Paid ₹1,250.00 to Chai Point Bangalore'));
      expect(log.parsedAmount, equals(1250.0));
      expect(log.detectedPayee, equals('Chai Point Bangalore'));
      expect(log.sourcePackageOrSender, equals('com.google.android.apps.nbu.paisa.user'));
      expect(log.executionState, equals(AuditExecutionState.parsed));
      expect(log.timestamp, equals(now));
      expect(log.deduplicationHash, equals('a1b2c3d4e5f6'));
      expect(log.inferredCategory, equals('Food & Dining'));
    });

    test('AuditExecutionState supports parsed, ignored, and duplicate states', () {
      expect(AuditExecutionState.values, contains(AuditExecutionState.parsed));
      expect(AuditExecutionState.values, contains(AuditExecutionState.ignored));
      expect(AuditExecutionState.values, contains(AuditExecutionState.duplicate));
      expect(AuditExecutionState.values.length, equals(3));
    });

    test('SmsAuditLog handles ignored non-financial payloads', () {
      final log = SmsAuditLog()
        ..rawPayload = 'Your OTP for Google is 481902'
        ..sourcePackageOrSender = 'Google'
        ..executionState = AuditExecutionState.ignored;

      expect(log.parsedAmount, isNull);
      expect(log.detectedPayee, isNull);
      expect(log.executionState, equals(AuditExecutionState.ignored));
    });

    test('SmsAuditLog handles duplicate events detected within 15-minute window', () {
      final log = SmsAuditLog()
        ..rawPayload = 'Acct XX1234 debited by USD 45.00 to Starbucks'
        ..parsedAmount = 45.0
        ..detectedPayee = 'Starbucks'
        ..sourcePackageOrSender = 'HDFCBK'
        ..executionState = AuditExecutionState.duplicate
        ..deduplicationHash = 'md5hash12345';

      expect(log.executionState, equals(AuditExecutionState.duplicate));
      expect(log.deduplicationHash, equals('md5hash12345'));
    });
  });
}
