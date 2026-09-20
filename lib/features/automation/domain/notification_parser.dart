import 'package:finance_app/features/automation/domain/models/parsed_transaction.dart';

/// Deterministic payment notification parser using targeted regex patterns
/// for major payment providers (Google Pay, PhonePe, Paytm, etc.).
class NotificationParser {
  const NotificationParser();

  // 1. Google Pay: (?:Paid|Sent)\s+[₹Rs\.]*\s*([\d,]+(?:\.\d{2})?)\s+to\s+(.+)
  static final RegExp googlePayPattern = RegExp(
    r'(?:Paid|Sent)\s+[₹Rs\.]*\s*([\d,]+(?:\.\d{2})?)\s+to\s+(.+)',
    caseSensitive: false,
  );

  // 2. PhonePe: Payment of\s+[₹Rs\.]*\s*([\d,]+(?:\.\d{2})?)\s+to\s+(.+?)\s+successful
  static final RegExp phonePePattern = RegExp(
    r'Payment of\s+[₹Rs\.]*\s*([\d,]+(?:\.\d{2})?)\s+to\s+(.+?)\s+successful',
    caseSensitive: false,
  );

  // 3. Paytm: Paid\s+[₹Rs\.]*\s*([\d,]+(?:\.\d{2})?)\s+successfully\s+to\s+(.+)
  static final RegExp paytmPattern = RegExp(
    r'Paid\s+[₹Rs\.]*\s*([\d,]+(?:\.\d{2})?)\s+successfully\s+to\s+(.+)',
    caseSensitive: false,
  );

  /// Normalizes numeric strings by stripping Indian comma formatting (e.g., 1,250.00 → 1250.00, 1,50,000.50 → 150000.50).
  static double? normalizeAmount(String? rawAmount) {
    if (rawAmount == null || rawAmount.trim().isEmpty) return null;

    // Strip currency symbols and prefixes, preserving decimal point
    final String clean = rawAmount
        .replaceAll(RegExp(r'(?:INR|Rs\.?|[₹$€£])', caseSensitive: false), '')
        .replaceAll(',', '')
        .replaceAll(' ', '')
        .trim();

    return double.tryParse(clean);
  }

  /// Parses raw notification title and content into a [ParsedTransaction].
  ParsedTransaction? parse(
    String text, {
    String? packageName,
    DateTime? timestamp,
  }) {
    final String cleanText = text.replaceAll(RegExp(r'\r\n|\r|\n'), ' ').trim();
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

    // 1. Google Pay pattern match
    final RegExpMatch? gpayMatch = googlePayPattern.firstMatch(cleanText);
    if (gpayMatch != null) {
      final double? amount = normalizeAmount(gpayMatch.group(1));
      if (amount != null && amount > 0) {
        final String merchant = _cleanMerchant(gpayMatch.group(2));
        return ParsedTransaction(
          amount: amount,
          type: TransactionType.debit,
          merchant: merchant.isEmpty ? 'Google Pay Merchant' : merchant,
          currency: currency,
          rawMessage: text,
          timestamp: timestamp ?? DateTime.now(),
        );
      }
    }

    // 2. PhonePe pattern match
    final RegExpMatch? phonePeMatch = phonePePattern.firstMatch(cleanText);
    if (phonePeMatch != null) {
      final double? amount = normalizeAmount(phonePeMatch.group(1));
      if (amount != null && amount > 0) {
        final String merchant = _cleanMerchant(phonePeMatch.group(2));
        return ParsedTransaction(
          amount: amount,
          type: TransactionType.debit,
          merchant: merchant.isEmpty ? 'PhonePe Merchant' : merchant,
          currency: currency,
          rawMessage: text,
          timestamp: timestamp ?? DateTime.now(),
        );
      }
    }

    // 3. Paytm pattern match
    final RegExpMatch? paytmMatch = paytmPattern.firstMatch(cleanText);
    if (paytmMatch != null) {
      final double? amount = normalizeAmount(paytmMatch.group(1));
      if (amount != null && amount > 0) {
        final String merchant = _cleanMerchant(paytmMatch.group(2));
        return ParsedTransaction(
          amount: amount,
          type: TransactionType.debit,
          merchant: merchant.isEmpty ? 'Paytm Merchant' : merchant,
          currency: currency,
          rawMessage: text,
          timestamp: timestamp ?? DateTime.now(),
        );
      }
    }

    return null;
  }

  /// Cleans and sanitizes extracted merchant name.
  static String _cleanMerchant(String? raw) {
    if (raw == null) return '';
    return raw
        .replaceAll(RegExp(r'[\.\,\!]+$'), '') // Trailing punctuation
        .replaceAll(RegExp(r'\s+using\s+.*$', caseSensitive: false), '') // Strip payment method suffixes
        .trim();
  }
}
