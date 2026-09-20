import 'package:finance_app/features/automation/domain/bank_sms_parser.dart';
import 'package:finance_app/features/automation/domain/models/parsed_transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 24: Direct Bank SMS Listener (Fallback Engine) Tests', () {
    const parser = BankSmsParser();

    group('Bank Sender Verification', () {
      test('validates authentic bank header sender codes', () {
        expect(BankSmsParser.isVerifiedBankSender('HDFCBK'), isTrue);
        expect(BankSmsParser.isVerifiedBankSender('AD-HDFCBK-S'), isTrue);
        expect(BankSmsParser.isVerifiedBankSender('VM-SBIINB'), isTrue);
        expect(BankSmsParser.isVerifiedBankSender('AXISBK'), isTrue);
        expect(BankSmsParser.isVerifiedBankSender('ICICIB'), isTrue);
        expect(BankSmsParser.isVerifiedBankSender('KOTAKB'), isTrue);

        expect(BankSmsParser.isVerifiedBankSender('+919876543210'), isFalse);
        expect(BankSmsParser.isVerifiedBankSender('FRIEND'), isFalse);
        expect(BankSmsParser.isVerifiedBankSender(null), isFalse);
      });
    });

    group('Debit Regex Multi-Bank Pattern Extraction', () {
      test('parses HDFC Bank debit alert', () {
        final result = parser.parse(
          'Acct XX1234 debited by Rs. 1,450.00 on a/c x1234 to AMAZON INDIA. Avl Bal Rs. 25,000.00',
          sender: 'HDFCBK',
        );

        expect(result, isNotNull);
        expect(result!.amount, equals(1450.00));
        expect(result.type, equals(TransactionType.debit));
        expect(result.accountMasked, equals('x1234'));
        expect(result.merchant, equals('AMAZON INDIA'));
      });

      test('parses SBI (SBIINB) card spent alert', () {
        final result = parser.parse(
          'Spent INR 850.50 on card x9876 at STARBUCKS COFFEE. Avail Bal INR 12,000.00',
          sender: 'SBIINB',
        );

        expect(result, isNotNull);
        expect(result!.amount, equals(850.50));
        expect(result.type, equals(TransactionType.debit));
        expect(result.accountMasked, equals('x9876'));
        expect(result.merchant, equals('STARBUCKS COFFEE'));
      });

      test('parses Axis Bank (AXISBK) a/c payment alert', () {
        final result = parser.parse(
          'Paid ₹ 3,200.00 from a/c xx4321 to Swiggy Bangalore',
          sender: 'AXISBK',
        );

        expect(result, isNotNull);
        expect(result!.amount, equals(3200.00));
        expect(result.type, equals(TransactionType.debit));
        expect(result.accountMasked, equals('xx4321'));
        expect(result.merchant, equals('Swiggy Bangalore'));
      });

      test('parses VPA UPI debit alert', () {
        final result = parser.parse(
          'VPA debited by ₹500.00 to rahul@okaxis. Ref 982104',
          sender: 'UPIALERT',
        );

        expect(result, isNotNull);
        expect(result!.amount, equals(500.00));
        expect(result.type, equals(TransactionType.debit));
        expect(result.merchant, equals('rahul@okaxis'));
      });
    });

    group('Credit Transaction & Fallback Detection', () {
      test('parses incoming salary credit alert', () {
        final result = parser.parse(
          'A/C XX4321 credited with Rs. 50,000.00 by TECH CORP SALARY. Avl Bal Rs. 85,000.00',
          sender: 'HDFCBK',
        );

        expect(result, isNotNull);
        expect(result!.amount, equals(50000.00));
        expect(result.type, equals(TransactionType.credit));
        expect(result.merchant, equals('TECH CORP SALARY'));
      });

      test('returns null for empty or non-financial messages', () {
        expect(parser.parse(''), isNull);
        expect(parser.parse('Your OTP for netbanking is 392019'), isNull);
      });
    });
  });
}
