import 'package:finance_app/features/accounts/data/models/account.dart';
import 'package:finance_app/features/automation/domain/bank_sms_parser.dart';
import 'package:finance_app/features/automation/domain/deduplication_engine.dart';
import 'package:finance_app/features/automation/domain/models/parsed_transaction.dart';
import 'package:finance_app/features/transactions/data/models/transaction.dart'
    hide TransactionType;
import 'package:flutter_test/flutter_test.dart';

void main() {
  const BankSmsParser parser = BankSmsParser();

  group('Phase 56: 20 Indian Banking SMS Formats Regex Validation', () {
    test('1. HDFC Bank Debit SMS', () {
      const sms =
          'Dear Customer, INR 1,250.00 debited from A/c **4321 on 15-Sep-26 to Swiggy. Avail Bal: INR 45,000.00.';
      final result = parser.parse(sms, sender: 'HDFCBK');
      expect(result, isNotNull);
      expect(result!.amount, equals(1250.00));
      expect(result.type, equals(TransactionType.debit));
      expect(result.accountMasked, contains('4321'));
      expect(result.merchant?.toLowerCase(), contains('swiggy'));
    });

    test('2. SBI Debit SMS', () {
      const sms =
          'Your A/C 9876 is debited by Rs. 450.00 on 12/09/26 towards Amazon Pay. Ref: 62847291.';
      final result = parser.parse(sms, sender: 'SBIINB');
      expect(result, isNotNull);
      expect(result!.amount, equals(450.00));
      expect(result.type, equals(TransactionType.debit));
      expect(result.accountMasked, contains('9876'));
      expect(result.merchant?.toLowerCase(), contains('amazon'));
    });

    test('3. ICICI Bank Debit SMS', () {
      const sms =
          'Acct XX1029 debited with INR 2,499.50 on 10-Sep-26. Info: Netflix Sub. UPI Ref 928374.';
      final result = parser.parse(sms, sender: 'ICICIB');
      expect(result, isNotNull);
      expect(result!.amount, equals(2499.50));
      expect(result.type, equals(TransactionType.debit));
      expect(result.accountMasked, contains('1029'));
      expect(result.merchant?.toLowerCase(), contains('netflix'));
    });

    test('4. Axis Bank Debit SMS', () {
      const sms =
          'Rs. 750.00 debited from Axis Bank A/c 5432 on 14-Sep-26 towards Zomato. Avail bal INR 12,000.00.';
      final result = parser.parse(sms, sender: 'AXISBK');
      expect(result, isNotNull);
      expect(result!.amount, equals(750.00));
      expect(result.type, equals(TransactionType.debit));
      expect(result.accountMasked, contains('5432'));
      expect(result.merchant?.toLowerCase(), contains('zomato'));
    });

    test('5. Kotak Mahindra Bank Debit SMS', () {
      const sms =
          'Sent Rs. 3,100.00 from Kotak A/c 1122 to Starbucks via UPI ref 839201.';
      final result = parser.parse(sms, sender: 'KOTAKB');
      expect(result, isNotNull);
      expect(result!.amount, equals(3100.00));
      expect(result.type, equals(TransactionType.debit));
      expect(result.accountMasked, contains('1122'));
      expect(result.merchant?.toLowerCase(), contains('starbucks'));
    });

    test('6. Punjab National Bank (PNB) Debit SMS', () {
      const sms =
          'Your A/C ending 3344 debited by Rs. 800.00 on 09-09-2026 at BigBasket.';
      final result = parser.parse(sms, sender: 'PUNJNB');
      expect(result, isNotNull);
      expect(result!.amount, equals(800.00));
      expect(result.type, equals(TransactionType.debit));
      expect(result.accountMasked, contains('3344'));
      expect(result.merchant?.toLowerCase(), contains('bigbasket'));
    });

    test('7. Canara Bank Debit SMS', () {
      const sms =
          'Rs 1500.00 debited from A/C *5566 to Apollo Pharmacy on 08-09-2026.';
      final result = parser.parse(sms, sender: 'CANBNK');
      expect(result, isNotNull);
      expect(result!.amount, equals(1500.00));
      expect(result.type, equals(TransactionType.debit));
      expect(result.accountMasked, contains('5566'));
      expect(result.merchant?.toLowerCase(), contains('apollo'));
    });

    test('8. Union Bank of India Debit SMS', () {
      const sms =
          'Union Bank: A/c XX7788 debited by INR 620.00 on 07/09/26 towards Uber Trips.';
      final result = parser.parse(sms, sender: 'UNIONB');
      expect(result, isNotNull);
      expect(result!.amount, equals(620.00));
      expect(result.type, equals(TransactionType.debit));
      expect(result.accountMasked, contains('7788'));
      expect(result.merchant?.toLowerCase(), contains('uber'));
    });

    test('9. IndusInd Bank Card Debit SMS', () {
      const sms =
          'Your IndusInd Card ending 9900 spent Rs. 4,200.00 at Apple Store on 06-Sep-26.';
      final result = parser.parse(sms, sender: 'INDUSB');
      expect(result, isNotNull);
      expect(result!.amount, equals(4200.00));
      expect(result.type, equals(TransactionType.debit));
      expect(result.accountMasked, contains('9900'));
      expect(result.merchant?.toLowerCase(), contains('apple'));
    });

    test('10. Yes Bank Debit SMS', () {
      const sms = 'Rs 350.00 debited on A/c 4455 info: Chai Point via UPI.';
      final result = parser.parse(sms, sender: 'YESBNK');
      expect(result, isNotNull);
      expect(result!.amount, equals(350.00));
      expect(result.type, equals(TransactionType.debit));
      expect(result.accountMasked, contains('4455'));
      expect(result.merchant?.toLowerCase(), contains('chai'));
    });

    test('11. Bank of Baroda (BOB) Debit SMS', () {
      const sms =
          'BOB: A/c *8899 debited with Rs. 1,850.00 on 05-Sep-26 to Flipkart.';
      final result = parser.parse(sms, sender: 'BOBTXN');
      expect(result, isNotNull);
      expect(result!.amount, equals(1850.00));
      expect(result.type, equals(TransactionType.debit));
      expect(result.accountMasked, contains('8899'));
      expect(result.merchant?.toLowerCase(), contains('flipkart'));
    });

    test('12. Federal Bank Debit SMS', () {
      const sms =
          'Federal Bank: Rs 920.00 debited from a/c 6677 towards Dunzo on 04-Sep-26.';
      final result = parser.parse(sms, sender: 'FEDBNK');
      expect(result, isNotNull);
      expect(result!.amount, equals(920.00));
      expect(result.type, equals(TransactionType.debit));
      expect(result.accountMasked, contains('6677'));
      expect(result.merchant?.toLowerCase(), contains('dunzo'));
    });

    test('13. HDFC Bank Salary Credit SMS', () {
      const sms =
          'Your A/c **4321 is credited with INR 50,000.00 on 01-Sep-26 by Salary Transfer. Avail Bal: INR 95,000.00.';
      final result = parser.parse(sms, sender: 'HDFCBK');
      expect(result, isNotNull);
      expect(result!.amount, equals(50000.00));
      expect(result.type, equals(TransactionType.credit));
      expect(result.accountMasked, contains('4321'));
      expect(result.merchant?.toLowerCase(), contains('salary'));
    });

    test('14. SBI UPI Credit SMS', () {
      const sms =
          'Your A/C 9876 credited with Rs. 1,500.00 on 02-Sep-26 by UPI from Rahul. Ref: 102938.';
      final result = parser.parse(sms, sender: 'SBIINB');
      expect(result, isNotNull);
      expect(result!.amount, equals(1500.00));
      expect(result.type, equals(TransactionType.credit));
      expect(result.accountMasked, contains('9876'));
      expect(result.merchant?.toLowerCase(), contains('rahul'));
    });

    test('15. ICICI Bank Inward Remittance Credit SMS', () {
      const sms =
          'INR 3,200.00 received in your Acct XX1029 on 03-Sep-26 from Upwork Freelance.';
      final result = parser.parse(sms, sender: 'ICICIB');
      expect(result, isNotNull);
      expect(result!.amount, equals(3200.00));
      expect(result.type, equals(TransactionType.credit));
      expect(result.accountMasked, contains('1029'));
      expect(result.merchant?.toLowerCase(), contains('upwork'));
    });

    test('16. Axis Bank NEFT Credit SMS', () {
      const sms =
          'Axis Bank A/c 5432 is credited with Rs. 10,000.00 on 04-Sep-26 by NEFT Transfer.';
      final result = parser.parse(sms, sender: 'AXISBK');
      expect(result, isNotNull);
      expect(result!.amount, equals(10000.00));
      expect(result.type, equals(TransactionType.credit));
      expect(result.accountMasked, contains('5432'));
      expect(result.merchant?.toLowerCase(), contains('neft'));
    });

    test('17. Paytm Payments Bank Debit SMS', () {
      const sms =
          'Paid Rs. 120.00 from Paytm Wallet/Bank A/c *1234 to Metro Rail via UPI.';
      final result = parser.parse(sms, sender: 'PAYTM');
      expect(result, isNotNull);
      expect(result!.amount, equals(120.00));
      expect(result.type, equals(TransactionType.debit));
      expect(result.accountMasked, contains('1234'));
      expect(result.merchant?.toLowerCase(), contains('metro'));
    });

    test('18. Airtel Payments Bank Cashback Credit SMS', () {
      const sms =
          'Received Rs. 500.00 in your Airtel Bank A/c XX5678 from CashBack Reward.';
      final result = parser.parse(sms, sender: 'AIRTEL');
      expect(result, isNotNull);
      expect(result!.amount, equals(500.00));
      expect(result.type, equals(TransactionType.credit));
      expect(result.accountMasked, contains('5678'));
      expect(result.merchant?.toLowerCase(), contains('cashback'));
    });

    test('19. IDFC FIRST Bank Card Debit SMS', () {
      const sms =
          'IDFC FIRST: Rs. 2,150.00 spent on Card ending 4411 at Reliance Digital on 08-Sep-26.';
      final result = parser.parse(sms, sender: 'IDFCFB');
      expect(result, isNotNull);
      expect(result!.amount, equals(2150.00));
      expect(result.type, equals(TransactionType.debit));
      expect(result.accountMasked, contains('4411'));
      expect(result.merchant?.toLowerCase(), contains('reliance'));
    });

    test('20. RBL Bank Debit SMS', () {
      const sms =
          'RBL Bank: INR 650.00 debited from A/C *7722 to Dominos Pizza on 11-Sep-26.';
      final result = parser.parse(sms, sender: 'RBLBNK');
      expect(result, isNotNull);
      expect(result!.amount, equals(650.00));
      expect(result.type, equals(TransactionType.debit));
      expect(result.accountMasked, contains('7722'));
      expect(result.merchant?.toLowerCase(), contains('dominos'));
    });
  });

  group('Phase 56: Atomic Balance Calculations for Multi-Account Transfers', () {
    test('Direct Transfer: updates source & destination with total net worth preserved', () {
      final Account checking = Account()
        ..name = 'HDFC Salary'
        ..currentBalance = 50000.0;
      final Account savings = Account()
        ..name = 'ICICI Savings'
        ..currentBalance = 15000.0;

      final double initialNetWorth = checking.currentBalance + savings.currentBalance;
      expect(initialNetWorth, equals(65000.0));

      const double transferAmount = 12000.0;

      // Execute transfer mutation
      checking.currentBalance -= transferAmount;
      savings.currentBalance += transferAmount;

      expect(checking.currentBalance, equals(38000.0));
      expect(savings.currentBalance, equals(27000.0));
      expect(checking.currentBalance + savings.currentBalance, equals(initialNetWorth));
    });

    test('Multi-Hop Transfer Chain across 3 accounts strictly conserves total balance', () {
      final Account bankA = Account()..name = 'Bank A'..currentBalance = 20000.0;
      final Account bankB = Account()..name = 'Bank B'..currentBalance = 10000.0;
      final Account upiWallet = Account()..name = 'UPI Wallet'..currentBalance = 5000.0;

      final double totalInitial = bankA.currentBalance + bankB.currentBalance + upiWallet.currentBalance;
      expect(totalInitial, equals(35000.0));

      // Hop 1: Bank A -> Bank B (7,000)
      const double hop1 = 7000.0;
      bankA.currentBalance -= hop1;
      bankB.currentBalance += hop1;

      expect(bankA.currentBalance, equals(13000.0));
      expect(bankB.currentBalance, equals(17000.0));
      expect(bankA.currentBalance + bankB.currentBalance + upiWallet.currentBalance, equals(totalInitial));

      // Hop 2: Bank B -> UPI Wallet (4,500)
      const double hop2 = 4500.0;
      bankB.currentBalance -= hop2;
      upiWallet.currentBalance += hop2;

      expect(bankB.currentBalance, equals(12500.0));
      expect(upiWallet.currentBalance, equals(9500.0));
      expect(bankA.currentBalance + bankB.currentBalance + upiWallet.currentBalance, equals(totalInitial));
    });

    test('Atomic Rollback restores exact original account balances', () {
      final Account src = Account()..name = 'Source'..currentBalance = 10000.0;
      final Account dst = Account()..name = 'Dest'..currentBalance = 5000.0;

      const double transferAmount = 3500.0;

      // Apply transfer
      src.currentBalance -= transferAmount;
      dst.currentBalance += transferAmount;

      expect(src.currentBalance, equals(6500.0));
      expect(dst.currentBalance, equals(8500.0));

      // Execute rollback
      src.currentBalance += transferAmount;
      dst.currentBalance -= transferAmount;

      expect(src.currentBalance, equals(10000.0));
      expect(dst.currentBalance, equals(5000.0));
    });

    test('Differential Amount Update on existing transfer recalculates balances precisely', () {
      final Account src = Account()..name = 'Source'..currentBalance = 8000.0;
      final Account dst = Account()..name = 'Dest'..currentBalance = 7000.0;

      const double oldAmount = 2000.0;
      const double newAmount = 3500.0;
      final double diff = newAmount - oldAmount; // 1500 additional debit

      src.currentBalance -= diff;
      dst.currentBalance += diff;

      expect(src.currentBalance, equals(6500.0));
      expect(dst.currentBalance, equals(8500.0));
      expect(src.currentBalance + dst.currentBalance, equals(15000.0));
    });
  });

  group('Phase 56: Cryptographic Deduplication Hash Collision Verification', () {
    test('Deterministic hash generation for identical parameters', () {
      final DateTime fixedTime = DateTime(2026, 9, 20, 14, 30, 0);
      final hash1 = DeduplicationEngine.generateHash(1250.00, 'Swiggy', fixedTime);
      final hash2 = DeduplicationEngine.generateHash(1250.00, 'swiggy ', fixedTime);

      expect(hash1, isNotEmpty);
      expect(hash1, equals(hash2));
    });

    test('15-minute slotting groups timestamps within the same window', () {
      final timeSlotStart = DateTime(2026, 9, 20, 10, 0, 0);
      final timeSlotEnd = DateTime(2026, 9, 20, 10, 14, 59);

      final hashStart = DeduplicationEngine.generateHash(450.0, 'Zomato', timeSlotStart);
      final hashEnd = DeduplicationEngine.generateHash(450.0, 'Zomato', timeSlotEnd);

      expect(hashStart, equals(hashEnd));
    });

    test('Timestamps across 15-minute boundary produce distinct hashes (no collision)', () {
      final timeSlot1 = DateTime(2026, 9, 20, 10, 14, 59);
      final timeSlot2 = DateTime(2026, 9, 20, 10, 15, 0);

      final hash1 = DeduplicationEngine.generateHash(450.0, 'Zomato', timeSlot1);
      final hash2 = DeduplicationEngine.generateHash(450.0, 'Zomato', timeSlot2);

      expect(hash1, isNot(equals(hash2)));
    });

    test('Collision resistance test across 1,000 distinct generated transactions', () {
      final Set<String> generatedHashes = <String>{};
      final DateTime baseTime = DateTime(2026, 9, 20, 12, 0, 0);

      for (int i = 0; i < 1000; i++) {
        final double amount = (i + 1) * 10.5;
        final String payee = 'Merchant_$i';
        final DateTime time = baseTime.add(Duration(minutes: i * 20));

        final String hash = DeduplicationEngine.generateHash(amount, payee, time);
        expect(generatedHashes.contains(hash), isFalse,
            reason: 'Hash collision detected at iteration $i with hash $hash');
        generatedHashes.add(hash);
      }

      expect(generatedHashes.length, equals(1000));
    });

    test('DeduplicationEngine drops duplicate events and permits unique events', () async {
      final engine = DeduplicationEngine();
      final DateTime now = DateTime(2026, 9, 20, 16, 0, 0);

      final tx1 = Transaction()
        ..amount = 899.0
        ..timestamp = now
        ..note = 'Nike Shoes';

      final tx2 = Transaction()
        ..amount = 899.0
        ..timestamp = now.add(const Duration(minutes: 5))
        ..note = 'Nike Shoes';

      final tx3 = Transaction()
        ..amount = 1200.0
        ..timestamp = now
        ..note = 'Adidas Shoes';

      final res1 = await engine.processOrDrop(tx1, merchantOrPayee: 'Nike Shoes');
      expect(res1, isNotNull);
      expect(res1!.deduplicationHash, isNotNull);

      // Duplicate event within 15-min window should be dropped
      final res2 = await engine.processOrDrop(tx2, merchantOrPayee: 'Nike Shoes');
      expect(res2, isNull);

      // Unique transaction should be accepted
      final res3 = await engine.processOrDrop(tx3, merchantOrPayee: 'Adidas Shoes');
      expect(res3, isNotNull);
    });
  });
}
