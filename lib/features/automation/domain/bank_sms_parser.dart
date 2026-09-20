import 'package:finance_app/core/constants/regex_patterns.dart';
import 'package:finance_app/features/automation/domain/models/parsed_transaction.dart';
import 'package:finance_app/features/automation/domain/notification_parser.dart';

/// Direct Bank SMS listener & fallback parser engine.
/// Extracts financial debit alerts from major banking codes (e.g., HDFCBK, SBIINB, AXISBK, ICICIB).
class BankSmsParser {
  const BankSmsParser();

  /// Known verified Indian Bank SMS sender codes.
  static const List<String> verifiedBankSenders = [
    'HDFCBK',
    'SBIINB',
    'AXISBK',
    'ICICIB',
    'KOTAKB',
    'PUNJNB',
    'CANBNK',
    'UNIONB',
    'INDUSB',
    'YESBNK',
    'BOIBNK',
    'FEDBNK',
  ];

  /// Comprehensive regex for detecting debit transactions across bank SMS formats:
  /// Captures: Group 1: Amount, Group 2: Account/Card, Group 3: Merchant/Payee.
  static final RegExp debitRegex = RegExp(
    r'(?:debited\s+by|spent|vpa|paid|transferred\s+rs\.?)\s*(?:rs\.?|inr|₹|usd|\$|eur|€|gbp|£)?\s*([\d,]+(?:\.\d{2})?)\s*(?:from|on)?\s*(?:a\/c|ac|card)?\s*([x\d\*]+)?\s*(?:to|at|info|towards)\s+([^.\n]+)',
    caseSensitive: false,
  );

  /// Supplementary credit regex pattern for incoming bank deposits/credits.
  static final RegExp creditRegex = RegExp(
    r'(?:credited\s+with|deposited|received|transferred\s+to\s+your\s+a\/c)\s*(?:rs\.?|inr|₹|usd|\$|eur|€|gbp|£)?\s*([\d,]+(?:\.\d{2})?)\s*(?:to|in)?\s*(?:a\/c|ac)?\s*([x\d\*]+)?\s*(?:from|by|info)\s+([^.\n]+)',
    caseSensitive: false,
  );

  /// Validates whether sender header matches a known bank sender code.
  static bool isVerifiedBankSender(String? sender) {
    if (sender == null) return false;
    final String cleanSender = sender.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
    return verifiedBankSenders.any((bank) => cleanSender.contains(bank));
  }

  /// Parses a bank SMS text into a [ParsedTransaction].
  ParsedTransaction? parse(
    String smsBody, {
    String? sender,
    DateTime? receivedAt,
  }) {
    final String cleanText = smsBody.replaceAll(RegExp(r'\r\n|\r|\n'), ' ').trim();
    if (cleanText.isEmpty) return null;

    // Detect currency symbol
    String currency = 'INR';
    if (cleanText.contains('\$')) {
      currency = 'USD';
    } else if (cleanText.contains('€')) {
      currency = 'EUR';
    } else if (cleanText.contains('£')) {
      currency = 'GBP';
    }

    // 1. Try primary comprehensive debit regex
    final RegExpMatch? debitMatch = debitRegex.firstMatch(cleanText);
    if (debitMatch != null) {
      final double? amount = NotificationParser.normalizeAmount(debitMatch.group(1));
      if (amount != null && amount > 0) {
        String? rawAccount = debitMatch.group(2)?.trim();
        rawAccount ??= RegexPatterns.maskedAccount.firstMatch(cleanText)?.group(1);

        final String rawMerchant = debitMatch.group(3) ?? '';
        String merchant = _cleanMerchant(rawMerchant);
        if (merchant.isEmpty) {
          merchant = RegexPatterns.merchantName.firstMatch(cleanText)?.group(1)?.trim() ??
              (sender ?? 'Bank Debit');
        }

        final String? reference = RegexPatterns.referenceNumber.firstMatch(cleanText)?.group(1);

        return ParsedTransaction(
          amount: amount,
          type: TransactionType.debit,
          accountMasked: rawAccount,
          referenceNumber: reference,
          merchant: merchant,
          currency: currency,
          rawMessage: smsBody,
          timestamp: receivedAt ?? DateTime.now(),
        );
      }
    }

    // 2. Try credit regex
    final RegExpMatch? creditMatch = creditRegex.firstMatch(cleanText);
    if (creditMatch != null) {
      final double? amount = NotificationParser.normalizeAmount(creditMatch.group(1));
      if (amount != null && amount > 0) {
        String? rawAccount = creditMatch.group(2)?.trim();
        rawAccount ??= RegexPatterns.maskedAccount.firstMatch(cleanText)?.group(1);

        final String rawMerchant = creditMatch.group(3) ?? '';
        String merchant = _cleanMerchant(rawMerchant);
        if (merchant.isEmpty) {
          merchant = RegexPatterns.merchantName.firstMatch(cleanText)?.group(1)?.trim() ??
              (sender ?? 'Bank Credit');
        }

        final String? reference = RegexPatterns.referenceNumber.firstMatch(cleanText)?.group(1);

        return ParsedTransaction(
          amount: amount,
          type: TransactionType.credit,
          accountMasked: rawAccount,
          referenceNumber: reference,
          merchant: merchant,
          currency: currency,
          rawMessage: smsBody,
          timestamp: receivedAt ?? DateTime.now(),
        );
      }
    }

    // 3. Fallback heuristic pattern matching
    final double? fallbackAmount = _extractFallbackAmount(cleanText);
    if (fallbackAmount != null && fallbackAmount > 0) {
      final bool isCredit = cleanText.toLowerCase().contains('credited') ||
          cleanText.toLowerCase().contains('received');
      final String? account = RegexPatterns.maskedAccount.firstMatch(cleanText)?.group(1);
      final String? reference = RegexPatterns.referenceNumber.firstMatch(cleanText)?.group(1);
      final String? merchant = RegexPatterns.merchantName.firstMatch(cleanText)?.group(1)?.trim();

      return ParsedTransaction(
        amount: fallbackAmount,
        type: isCredit ? TransactionType.credit : TransactionType.debit,
        accountMasked: account,
        referenceNumber: reference,
        merchant: merchant ?? sender ?? (isCredit ? 'Bank Credit' : 'Bank Debit'),
        currency: currency,
        rawMessage: smsBody,
        timestamp: receivedAt ?? DateTime.now(),
      );
    }

    return null;
  }

  static double? _extractFallbackAmount(String text) {
    final RegExp amountReg = RegExp(
      r'(?:rs\.?|inr|₹|usd|\$)\s*([\d,]+(?:\.\d{2})?)',
      caseSensitive: false,
    );
    final RegExpMatch? match = amountReg.firstMatch(text);
    if (match != null) {
      return NotificationParser.normalizeAmount(match.group(1));
    }
    return null;
  }

  static String _cleanMerchant(String raw) {
    return raw
        .replaceAll(RegExp(r'(?:Avl|Avail|Available)\s+Bal.*$', caseSensitive: false), '')
        .replaceAll(RegExp(r'(?:Ref|Reference|UTR|Txn).*$', caseSensitive: false), '')
        .replaceAll(RegExp(r'[\.\,\!]+$'), '')
        .trim();
  }
}
