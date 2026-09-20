enum TransactionType {
  debit,
  credit,
  transfer,
  unknown,
}

/// Represents a parsed transaction extracted from a bank SMS or notification.
class ParsedTransaction {
  const ParsedTransaction({
    required this.amount,
    required this.type,
    this.merchant,
    this.category,
    this.accountMasked,
    this.referenceNumber,
    this.rawMessage,
    this.timestamp,
    this.currency = 'USD',
  });

  final double amount;
  final TransactionType type;
  final String? merchant;
  final String? category;
  final String? accountMasked;
  final String? referenceNumber;
  final String? rawMessage;
  final DateTime? timestamp;
  final String currency;

  ParsedTransaction copyWith({
    double? amount,
    TransactionType? type,
    String? merchant,
    String? category,
    String? accountMasked,
    String? referenceNumber,
    String? rawMessage,
    DateTime? timestamp,
    String? currency,
  }) {
    return ParsedTransaction(
      amount: amount ?? this.amount,
      type: type ?? this.type,
      merchant: merchant ?? this.merchant,
      category: category ?? this.category,
      accountMasked: accountMasked ?? this.accountMasked,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      rawMessage: rawMessage ?? this.rawMessage,
      timestamp: timestamp ?? this.timestamp,
      currency: currency ?? this.currency,
    );
  }
}
