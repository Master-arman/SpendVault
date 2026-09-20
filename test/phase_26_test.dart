import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:finance_app/features/automation/domain/deduplication_engine.dart';
import 'package:finance_app/features/transactions/data/models/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 26: Deduplication Engine (Cryptographic Hash Collision) Tests', () {
    late DeduplicationEngine engine;

    setUp(() {
      engine = DeduplicationEngine();
    });

    group('Hash Generation Algorithm', () {
      test('generates expected MD5 hash for 15-minute window', () {
        final DateTime time = DateTime(2026, 9, 20, 14, 10, 0); // 14:10 slot
        const double amount = 1250.0;
        const String payee = 'Chai Point';

        final int cleanTime = time.millisecondsSinceEpoch ~/ (1000 * 60 * 15);
        final String expectedPayload = '$amount-${payee.toLowerCase().trim()}-$cleanTime';
        final String expectedHash = md5.convert(utf8.encode(expectedPayload)).toString();

        final String actualHash = DeduplicationEngine.generateHash(amount, payee, time);
        expect(actualHash, equals(expectedHash));
      });

      test('produces identical hash for events within same 15-minute window', () {
        final DateTime timePush = DateTime(2026, 9, 20, 10, 5, 12);
        final DateTime timeSms = DateTime(2026, 9, 20, 10, 11, 45); // Same 10:00-10:15 slot

        final String hash1 = DeduplicationEngine.generateHash(450.0, 'Starbucks Coffee', timePush);
        final String hash2 = DeduplicationEngine.generateHash(450.0, '  starbucks coffee  ', timeSms);

        expect(hash1, equals(hash2));
      });

      test('produces different hash for events in different 15-minute windows', () {
        final DateTime time1 = DateTime(2026, 9, 20, 10, 5, 0); // Slot 10:00-10:15
        final DateTime time2 = DateTime(2026, 9, 20, 10, 25, 0); // Slot 10:15-10:30

        final String hash1 = DeduplicationEngine.generateHash(450.0, 'Starbucks', time1);
        final String hash2 = DeduplicationEngine.generateHash(450.0, 'Starbucks', time2);

        expect(hash1, isNot(equals(hash2)));
      });

      test('produces different hash for different amounts or payees', () {
        final DateTime time = DateTime(2026, 9, 20, 12, 0, 0);

        final String hash1 = DeduplicationEngine.generateHash(100.0, 'Uber', time);
        final String hash2 = DeduplicationEngine.generateHash(200.0, 'Uber', time);
        final String hash3 = DeduplicationEngine.generateHash(100.0, 'Ola', time);

        expect(hash1, isNot(equals(hash2)));
        expect(hash1, isNot(equals(hash3)));
      });
    });

    group('Duplicate Detection and Silent Drop Logic', () {
      test('first event processed, duplicate event dropped silently within 15-minute slot', () async {
        final DateTime timePush = DateTime(2026, 9, 20, 15, 2, 0);
        final DateTime timeSms = DateTime(2026, 9, 20, 15, 3, 30);

        final Transaction pushTx = Transaction()
          ..amount = 850.0
          ..type = TransactionType.expense
          ..note = 'Swiggy'
          ..timestamp = timePush;

        final Transaction smsTx = Transaction()
          ..amount = 850.0
          ..type = TransactionType.expense
          ..note = 'Swiggy'
          ..timestamp = timeSms;

        // 1. Process initial push notification
        final Transaction? result1 = await engine.processOrDrop(pushTx, merchantOrPayee: 'Swiggy');
        expect(result1, isNotNull);
        expect(result1!.deduplicationHash, isNotNull);

        // 2. Process duplicate SMS received within 15-minute slot
        final Transaction? result2 = await engine.processOrDrop(smsTx, merchantOrPayee: 'Swiggy');
        expect(result2, isNull, reason: 'Duplicate event should be silently dropped');
      });

      test('accepts new transaction outside of the 15-minute window', () async {
        final DateTime time1 = DateTime(2026, 9, 20, 9, 0, 0);
        final DateTime time2 = DateTime(2026, 9, 20, 9, 30, 0);

        final Transaction tx1 = Transaction()
          ..amount = 250.0
          ..type = TransactionType.expense
          ..note = 'Metro Recharge'
          ..timestamp = time1;

        final Transaction tx2 = Transaction()
          ..amount = 250.0
          ..type = TransactionType.expense
          ..note = 'Metro Recharge'
          ..timestamp = time2;

        final Transaction? result1 = await engine.processOrDrop(tx1);
        final Transaction? result2 = await engine.processOrDrop(tx2);

        expect(result1, isNotNull);
        expect(result2, isNotNull);
        expect(result1!.deduplicationHash, isNot(equals(result2!.deduplicationHash)));
      });
    });
  });
}
