/// Regular expressions for financial parsing, SMS transaction extractors, and validation.
class RegexPatterns {
  const RegexPatterns._();

  /// Regex to detect debited or credited transaction amounts (e.g. INR 1,250.00, Rs. 450, $120.50, USD 99.00)
  static final RegExp currencyAmount = RegExp(
    r'(?:(?:Rs\.?|INR|USD|\$|EUR|€|GBP|£)\s*)([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?|[0-9]+(?:\.[0-9]{1,2})?)',
    caseSensitive: false,
  );

  /// Regex to identify debit or spending keywords in SMS
  static final RegExp debitKeywords = RegExp(
    r'\b(?:debited|spent|paid|withdrawn|sent|deducted|purchase|txn|transferred to|spent at)\b',
    caseSensitive: false,
  );

  /// Regex to identify credit or income keywords in SMS
  static final RegExp creditKeywords = RegExp(
    r'\b(?:credited|received|deposited|refunded|cashback|added|transferred from)\b',
    caseSensitive: false,
  );

  /// Regex to extract masked bank account or card number (e.g., A/c **1234, Card ending 4321, XX9876)
  static final RegExp maskedAccount = RegExp(
    r'(?:a\/c|acct|account|card|ending|xx|no\.?)\s*[:#.]?\s*([xX*]*\d{3,4})',
    caseSensitive: false,
  );

  /// Regex to extract merchant/vendor/recipient name (e.g., at Amazon, to Uber, info: StarBucks)
  static final RegExp merchantName = RegExp(
    r'(?:at|to|vpa|info|merchant|towards)\s+([A-Za-z0-9\.\-_& ]{2,30})(?:\s+on|\s+ref|\s+avail|\s+balance|\s+bal|\s+upi|\.|$)',
    caseSensitive: false,
  );

  /// Regex for transaction reference or UTR numbers
  static final RegExp referenceNumber = RegExp(
    r'(?:ref(?:\s+no)?|utr|txn\s+id|rrn)[\s:]+([A-Za-z0-9]{6,22})',
    caseSensitive: false,
  );

  /// Regex to validate email addresses
  static final RegExp email = RegExp(
    r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$',
  );
}
