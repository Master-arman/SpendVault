import 'package:finance_app/core/constants/regex_patterns.dart';
import 'package:finance_app/features/automation/domain/models/parsed_transaction.dart';
import 'package:finance_app/features/automation/domain/notification_parser.dart';

/// Direct Bank SMS listener & fallback parser engine.
/// Extracts financial debit/credit alerts from Indian banking codes (e.g., HDFCBK, SBIINB, AXISBK, ICICIB).
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
    'BOBTXN',
    'FEDBNK',
    'IDFCFB',
    'RBLBNK',
    'PAYTM',
    'AIRTEL',
  ];

  /// Comprehensive regex for detecting debit transactions across bank SMS formats.
  static final RegExp debitRegex = RegExp(
    r'(?:debited\s*(?:by|with|from)?|spent\s*(?:on)?|vpa|paid|transferred\s*rs\.?|sent)\s*(?:rs\.?|inr|₹|usd|\$|eur|€|gbp|£)?\s*([\d,]+(?:\.\d{2})?)\s*(?:from|on|at)?\s*(?:a\/c|ac|account|card|wallet\/bank\s*a\/c)?\s*(?:ending)?\s*([x\d\*]+)?\s*(?:to|at|info|towards|for)?\s+([^.\n]+)',
    caseSensitive: false,
  );

  /// Supplementary credit regex pattern for incoming bank deposits/credits.
  static final RegExp creditRegex = RegExp(
    r'(?:credited\s*(?:with|by|to)?|deposited|received|transferred\s*to\s*your\s*a\/c)\s*(?:rs\.?|inr|₹|usd|\$|eur|€|gbp|£)?\s*([\d,]+(?:\.\d{2})?)\s*(?:to|in|from|by|on)?\s*(?:your)?\s*(?:a\/c|ac|account)?\s*(?:ending)?\s*([x\d\*]+)?\s*(?:from|by|info|towards)?\s+([^.\n]+)',
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
    if (debitMatch != null && !_isExplicitCredit(cleanText)) {
      final double? amount = NotificationParser.normalizeAmount(debitMatch.group(1));
      if (amount != null && amount > 0) {
        String? rawAccount = debitMatch.group(2)?.trim();
        rawAccount ??= RegexPatterns.maskedAccount.firstMatch(cleanText)?.group(1);

        final String rawMerchant = debitMatch.group(3) ?? '';
        final String merchant = _resolveMerchant(cleanText, rawMerchant, sender ?? 'Bank Debit');
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
        final String merchant = _resolveMerchant(cleanText, rawMerchant, sender ?? 'Bank Credit');
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
      final bool isCredit = _isExplicitCredit(cleanText);
      final String? account = RegexPatterns.maskedAccount.firstMatch(cleanText)?.group(1);
      final String? reference = RegexPatterns.referenceNumber.firstMatch(cleanText)?.group(1);
      final String merchant = _resolveMerchant(cleanText, '', sender ?? (isCredit ? 'Bank Credit' : 'Bank Debit'));

      return ParsedTransaction(
        amount: fallbackAmount,
        type: isCredit ? TransactionType.credit : TransactionType.debit,
        accountMasked: account,
        referenceNumber: reference,
        merchant: merchant,
        currency: currency,
        rawMessage: smsBody,
        timestamp: receivedAt ?? DateTime.now(),
      );
    }

    return null;
  }

  static bool _isExplicitCredit(String text) {
    final lower = text.toLowerCase();
    return lower.contains('credited') ||
        lower.contains('received in') ||
        lower.contains('deposited') ||
        lower.contains('refunded') ||
        lower.contains('cashback');
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

  static String _resolveMerchant(String fullText, String capturedRaw, String fallback) {
    final String merchant = _cleanMerchant(capturedRaw);
    if (merchant.isNotEmpty && !_isDateString(merchant)) {
      return merchant;
    }

    // Check specific Info:/towards/to/from/at tokens in fullText
    final RegExp explicitTokens = RegExp(
      r'(?:info\s*[:\-]|towards|to|at|from|by)\s+([A-Za-z0-9\s&_\.\-]{2,30})(?:\s+on|\s+via|\s+ref|\s+avail|\s+upi|\.|$)',
      caseSensitive: false,
    );
    final matches = explicitTokens.allMatches(fullText);
    for (final m in matches) {
      final candidate = _cleanMerchant(m.group(1) ?? '');
      if (candidate.isNotEmpty && !_isDateString(candidate) && !_isNoise(candidate)) {
        return candidate;
      }
    }

    return fallback;
  }

  static bool _isDateString(String s) {
    final lower = s.toLowerCase().trim();
    return RegExp(r'^\d{1,2}[\/\-\.]\w{3,}[\/\-\.]\d{2,4}$').hasMatch(lower) ||
        RegExp(r'^\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4}$').hasMatch(lower) ||
        RegExp(r'^\d{1,2}\s+(?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)', caseSensitive: false).hasMatch(lower);
  }

  static bool _isNoise(String s) {
    final lower = s.toLowerCase().trim();
    return lower.startsWith('your') ||
        lower.startsWith('a/c') ||
        lower.startsWith('acct') ||
        lower.startsWith('axis bank') ||
        lower.startsWith('hdfc') ||
        lower.startsWith('sbi');
  }

  static String _cleanMerchant(String raw) {
    return raw
        .replaceAll(RegExp(r'(?:info\s*[:\-])\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'(?:via\s+upi.*)$', caseSensitive: false), '')
        .replaceAll(RegExp(r'(?:upi\s+ref.*)$', caseSensitive: false), '')
        .replaceAll(RegExp(r'(?:Avl|Avail|Available)\s+Bal.*$', caseSensitive: false), '')
        .replaceAll(RegExp(r'(?:Ref|Reference|UTR|Txn).*$', caseSensitive: false), '')
        .replaceAll(RegExp(r'[\.\,\!]+$'), '')
        .trim();
  }
}
