import 'package:finance_app/core/utils/currency_manager.dart';

/// Financial and multi-currency formatting utility linked with [CurrencyManager].
class CurrencyFormatter {
  const CurrencyFormatter._();

  /// Formats numeric [amount] into localized currency representation (e.g. ₹1,250.50).
  static String format(
    double amount, {
    String? currencySymbol,
    String? locale,
    int? decimalDigits,
    bool showSign = false,
  }) {
    return CurrencyManager.instance.format(
      amount,
      customSymbol: currencySymbol,
      customScheme: locale != null
          ? (locale == 'en_IN' ? NumberingScheme.indian : NumberingScheme.western)
          : null,
      customDecimalDigits: decimalDigits,
      showSign: showSign,
    );
  }

  /// Formats large numbers compactly (e.g. ₹1.2K, ₹4.5M, ₹1.8B, ₹1.5L).
  static String formatCompact(
    double amount, {
    String? currencySymbol,
    String? locale,
  }) {
    return CurrencyManager.instance.formatCompact(
      amount,
      customSymbol: currencySymbol,
      customScheme: locale != null
          ? (locale == 'en_IN' ? NumberingScheme.indian : NumberingScheme.western)
          : null,
    );
  }

  /// Parses a string representation of currency into a double amount safely.
  static double? parseAmount(String input) {
    return CurrencyManager.parseAmount(input);
  }
}
