import 'package:finance_app/core/constants/regex_patterns.dart';
import 'package:finance_app/features/automation/domain/models/parsed_transaction.dart';

/// Engine responsible for extracting financial transaction data from SMS alerts.
class BankSmsParser {
  const BankSmsParser();

  /// Parses a raw SMS text into a [ParsedTransaction] if matching financial patterns exist.
  ParsedTransaction? parse(String smsBody, {DateTime? receivedAt}) {
    final String cleanText = smsBody.replaceAll(RegExp(r'\r\n|\r|\n'), ' ').trim();
    if (cleanText.isEmpty) {
      return null;
    }

    // 1. Detect transaction amount
    final RegExpMatch? amountMatch = RegexPatterns.currencyAmount.firstMatch(cleanText);
    if (amountMatch == null) {
      return null;
    }

    final String amountStr = amountMatch.group(1)?.replaceAll(',', '') ?? '';
    final double? amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) {
      return null;
    }

    // 2. Determine debit or credit
    TransactionType type = TransactionType.unknown;
    if (RegexPatterns.debitKeywords.hasMatch(cleanText)) {
      type = TransactionType.debit;
    } else if (RegexPatterns.creditKeywords.hasMatch(cleanText)) {
      type = TransactionType.credit;
    }

    // 3. Extract masked account
    String? accountMasked;
    final RegExpMatch? accountMatch = RegexPatterns.maskedAccount.firstMatch(cleanText);
    if (accountMatch != null) {
      accountMasked = accountMatch.group(1);
    }

    // 4. Extract merchant name
    String? merchant;
    final RegExpMatch? merchantMatch = RegexPatterns.merchantName.firstMatch(cleanText);
    if (merchantMatch != null) {
      merchant = merchantMatch.group(1)?.trim();
    }

    // 5. Extract reference number / UTR
    String? referenceNumber;
    final RegExpMatch? refMatch = RegexPatterns.referenceNumber.firstMatch(cleanText);
    if (refMatch != null) {
      referenceNumber = refMatch.group(1);
    }

    return ParsedTransaction(
      amount: amount,
      type: type,
      merchant: merchant,
      accountMasked: accountMasked,
      referenceNumber: referenceNumber,
      rawMessage: smsBody,
      timestamp: receivedAt ?? DateTime.now(),
    );
  }
}
