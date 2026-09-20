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
    this.accountMasked,
    this.referenceNumber,
    this.rawMessage,
    this.timestamp,
    this.currency = 'USD',
  });

  final double amount;
  final TransactionType type;
  final String? merchant;
  final String? accountMasked;
  final String? referenceNumber;
  final String? rawMessage;
  final DateTime? timestamp;
  final String currency;
}
