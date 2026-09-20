import 'package:flutter/foundation.dart';

/// Utility class for scrubbing personal identifiable information (PII) and
/// financial data (balances, account numbers, cards, UPI IDs, notes, SMS text)
/// prior to transmitting crash reports to monitoring sinks (Sentry, Firebase Crashlytics).
class CrashDataSanitizer {
  const CrashDataSanitizer._();

  // Patterns for Sensitive Financial & Personal Data

  // 1. Currency Balances and Amounts
  static final RegExp _balancePattern = RegExp(
    r'(?:bal(?:ance)?|avbl\s+bal(?:ance)?|a\/c\s+bal(?:ance)?|closing\s+bal(?:ance)?|clear\s+bal(?:ance)?|available\s+limit)\s*[:=]?\s*(?:rs\.?|inr|₹|\$|eur|€|gbp|£)?\s*[0-9,]+(?:\.[0-9]{1,2})?',
    caseSensitive: false,
  );

  static final RegExp _currencyAmountPattern = RegExp(
    r'(?:₹|Rs\.?|INR|\$|EUR|€|GBP|£)\s*[0-9,]+(?:\.[0-9]{1,2})?',
    caseSensitive: false,
  );

  static final RegExp _transactionVerbAmountPattern = RegExp(
    r'\b(?:credited|debited|spent|paid|withdrawn|transferred|received|sent|charged)\s+(?:by|for|of|with|amount)?\s*(?:rs\.?|inr|₹|\$|eur|€|gbp|£)?\s*[0-9,]+(?:\.[0-9]{1,2})?',
    caseSensitive: false,
  );

  // 2. Bank Accounts and Credit/Debit Cards
  static final RegExp _accountPattern = RegExp(
    r'\b(?:a\/c|acct|account(?:\s+no)?)\s*[:#.]?\s*(?:ending\s+in\s+)?(?:x{2,}|[*]{2,}|[0-9]{2,})?[0-9]{3,18}\b',
    caseSensitive: false,
  );

  static final RegExp _cardPattern = RegExp(
    r'\b(?:card(?:\s+ending\s+in|\s+ending|\s+no)?)\s*[:#.]?\s*(?:x{2,}|[*]{2,}|[0-9]{2,})?[0-9]{4,16}\b',
    caseSensitive: false,
  );

  // Standard raw 13-19 digit credit card numbers (e.g. 4111 2222 3333 4444 or 4111-2222-3333-4444)
  static final RegExp _rawCardDigitsPattern = RegExp(
    r'\b(?:\d{4}[ -]){3}\d{4}\b|\b(?:\d[ -]*?){13,19}\b',
  );

  // 3. UPI Handles & Virtual Payment Addresses (VPAs)
  static final RegExp _upiVpaPattern = RegExp(
    r'\b[a-zA-Z0-9.\-_]{2,}@(okhdfcbank|okaxis|oksbi|okicici|paytm|upi|ybl|ibl|axl|apl|barodampay|pnb|federal|kotak|sbi|postbank|jupiteraxis|fi)\b',
    caseSensitive: false,
  );

  static final RegExp _genericVpaPattern = RegExp(
    r'\b[a-zA-Z0-9.\-_]{3,}@[a-zA-Z]{3,}\b',
  );

  // 4. OTPs & SMS Notification Bodies
  static final RegExp _otpPattern = RegExp(
    r'\b(?:otp|one\s+time\s+password|secret\s+code|verification\s+code|security\s+code)\s*(?:is|:|=)?\s*[0-9]{4,8}\b',
    caseSensitive: false,
  );

  static final RegExp _smsBodyPayloadPattern = RegExp(
    r'(?:sms\s*(?:payload|msg)?|notification\s*(?:body|msg)?)\s*[:=]\s*["\x27]?([^\n\r"\x27]+)["\x27]?',
    caseSensitive: false,
  );

  // 5. User Notes & Remarks
  static final RegExp _userNotePattern = RegExp(
    r'(?:note|user_note|remarks?|description|narration|memo)\s*[:=]\s*["\x27]?([^\n\r"\x27,{}]+)["\x27]?',
    caseSensitive: false,
  );

  /// Sanitize a raw string of any sensitive data (balances, accounts, cards, UPIs, SMS, notes).
  static String sanitize(String? raw) {
    if (raw == null || raw.isEmpty) {
      return '';
    }

    String result = raw;

    // 1. Strip OTPs first
    result = result.replaceAllMapped(_otpPattern, (match) => '[REDACTED_OTP]');

    // 2. Strip Account & Card Numbers
    result = result.replaceAllMapped(_accountPattern, (match) => '[REDACTED_ACCOUNT]');
    result = result.replaceAllMapped(_cardPattern, (match) => '[REDACTED_CARD]');
    result = result.replaceAllMapped(_rawCardDigitsPattern, (match) => '[REDACTED_CARD]');

    // 3. Strip UPI VPAs
    result = result.replaceAllMapped(_upiVpaPattern, (match) => '[REDACTED_UPI]');
    result = result.replaceAllMapped(_genericVpaPattern, (match) {
      final str = match.group(0)!;
      // Do not redact common email domains if they are stack trace identifiers, but redact VPAs
      if (str.contains('@google.com') || str.contains('@flutter.dev') || str.contains('@dart.dev')) {
        return str;
      }
      return '[REDACTED_UPI]';
    });

    // 4. Strip Balances & Transaction Verb Amounts
    result = result.replaceAllMapped(_balancePattern, (match) => '[REDACTED_BALANCE]');
    result = result.replaceAllMapped(_transactionVerbAmountPattern, (match) => '[REDACTED_AMOUNT]');
    result = result.replaceAllMapped(_currencyAmountPattern, (match) => '[REDACTED_AMOUNT]');

    // 5. Strip SMS notification fields
    result = result.replaceAllMapped(_smsBodyPayloadPattern, (match) => 'sms_body: [REDACTED_SMS_BODY]');

    // 6. Strip User notes & descriptions
    result = result.replaceAllMapped(_userNotePattern, (match) => 'note: [REDACTED_USER_NOTE]');

    return result;
  }

  /// Deeply sanitizes any Object (Maps, Lists, Strings, Numbers, Booleans, etc.).
  static dynamic sanitizeValue(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      return sanitize(value);
    }
    if (value is Map) {
      final sanitizedMap = <String, dynamic>{};
      for (final entry in value.entries) {
        final keyStr = sanitize(entry.key.toString());
        final lowerKey = entry.key.toString().toLowerCase();

        // If key itself explicitly suggests sensitive field, redact entire value
        if (lowerKey.contains('note') ||
            lowerKey.contains('remark') ||
            lowerKey.contains('memo') ||
            lowerKey.contains('description')) {
          sanitizedMap[keyStr] = '[REDACTED_USER_NOTE]';
        } else if (lowerKey.contains('balance') ||
            lowerKey.contains('amount') ||
            lowerKey.contains('total') ||
            lowerKey.contains('price')) {
          sanitizedMap[keyStr] = '[REDACTED_AMOUNT]';
        } else if (lowerKey.contains('account') ||
            lowerKey.contains('card') ||
            lowerKey.contains('vpa') ||
            lowerKey.contains('upi')) {
          sanitizedMap[keyStr] = '[REDACTED_FINANCIAL_ID]';
        } else if (lowerKey.contains('sms') ||
            lowerKey.contains('otp') ||
            lowerKey.contains('notification')) {
          sanitizedMap[keyStr] = '[REDACTED_SMS_BODY]';
        } else {
          sanitizedMap[keyStr] = sanitizeValue(entry.value);
        }
      }
      return sanitizedMap;
    }
    if (value is List) {
      return value.map(sanitizeValue).toList();
    }
    if (value is Set) {
      return value.map(sanitizeValue).toSet();
    }
    return value;
  }

  /// Sanitizes a [StackTrace] by scrubbing variable representations and identifiers while keeping frame lines intact.
  static String sanitizeStackTrace(StackTrace? stackTrace) {
    if (stackTrace == null) return '';
    return sanitize(stackTrace.toString());
  }

  /// Sanitizes a [FlutterErrorDetails] object into a clean map representation.
  static Map<String, dynamic> sanitizeFlutterErrorDetails(FlutterErrorDetails details) {
    return {
      'exception': sanitize(details.exceptionAsString()),
      'library': sanitize(details.library),
      'context': details.context != null ? sanitize(details.context.toString()) : null,
      'stackTrace': sanitizeStackTrace(details.stack),
      'summary': details.summary.name,
    };
  }
}
