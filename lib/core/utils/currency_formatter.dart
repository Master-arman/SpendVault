import 'package:intl/intl.dart';

/// Financial and multi-currency formatting utility.
class CurrencyFormatter {
  const CurrencyFormatter._();

  /// Formats numeric [amount] into localized currency representation (e.g. ₹1,250.50).
  static String format(
    double amount, {
    String currencySymbol = '₹',
    String locale = 'en_IN',
    int decimalDigits = 2,
    bool showSign = false,
  }) {
    final NumberFormat format = NumberFormat.currency(
      locale: locale,
      symbol: currencySymbol,
      decimalDigits: decimalDigits,
    );

    final String formatted = format.format(amount.abs());
    if (showSign) {
      if (amount > 0) {
        return '+$formatted';
      } else if (amount < 0) {
        return '-$formatted';
      }
    } else if (amount < 0) {
      return '-$formatted';
    }

    return formatted;
  }

  /// Formats large numbers compactly (e.g. ₹1.2K, ₹4.5M, ₹1.8B).
  static String formatCompact(
    double amount, {
    String currencySymbol = '₹',
    String locale = 'en_IN',
  }) {
    final NumberFormat compactFormat = NumberFormat.compactCurrency(
      locale: locale,
      symbol: currencySymbol,
      decimalDigits: 1,
    );
    return compactFormat.format(amount);
  }

  /// Parses a string representation of currency into a double amount safely.
  static double? parseAmount(String input) {
    if (input.trim().isEmpty) {
      return null;
    }
    // Remove symbols, letters, spaces except digits, period, comma, negative sign
    final String clean = input.replaceAll(RegExp(r'[^0-9.-]'), '');
    return double.tryParse(clean);
  }
}
