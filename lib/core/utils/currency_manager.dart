import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Numbering system grouping representation.
enum NumberingScheme {
  /// Indian numbering system (e.g. 12,34,567.00 - Lakhs & Crores grouping).
  indian,

  /// Western standard numbering system (e.g. 1,234,567.00 - Thousands & Millions grouping).
  western,
}

/// Represents a supported financial currency.
class CurrencyItem {
  final String code;
  final String symbol;
  final String name;
  final String flagEmoji;
  final NumberingScheme defaultScheme;
  final int defaultDecimalDigits;

  const CurrencyItem({
    required this.code,
    required this.symbol,
    required this.name,
    required this.flagEmoji,
    this.defaultScheme = NumberingScheme.western,
    this.defaultDecimalDigits = 2,
  });

  static const CurrencyItem inr = CurrencyItem(
    code: 'INR',
    symbol: '₹',
    name: 'Indian Rupee',
    flagEmoji: '🇮🇳',
    defaultScheme: NumberingScheme.indian,
  );

  static const CurrencyItem usd = CurrencyItem(
    code: 'USD',
    symbol: r'$',
    name: 'US Dollar',
    flagEmoji: '🇺🇸',
    defaultScheme: NumberingScheme.western,
  );

  static const CurrencyItem eur = CurrencyItem(
    code: 'EUR',
    symbol: '€',
    name: 'Euro',
    flagEmoji: '🇪🇺',
    defaultScheme: NumberingScheme.western,
  );

  static const CurrencyItem gbp = CurrencyItem(
    code: 'GBP',
    symbol: '£',
    name: 'British Pound',
    flagEmoji: '🇬🇧',
    defaultScheme: NumberingScheme.western,
  );

  static const CurrencyItem jpy = CurrencyItem(
    code: 'JPY',
    symbol: '¥',
    name: 'Japanese Yen',
    flagEmoji: '🇯🇵',
    defaultScheme: NumberingScheme.western,
    defaultDecimalDigits: 0,
  );

  static const CurrencyItem aed = CurrencyItem(
    code: 'AED',
    symbol: 'د.إ',
    name: 'UAE Dirham',
    flagEmoji: '🇦🇪',
    defaultScheme: NumberingScheme.western,
  );

  static const CurrencyItem cad = CurrencyItem(
    code: 'CAD',
    symbol: r'$',
    name: 'Canadian Dollar',
    flagEmoji: '🇨🇦',
    defaultScheme: NumberingScheme.western,
  );

  static const CurrencyItem aud = CurrencyItem(
    code: 'AUD',
    symbol: r'$',
    name: 'Australian Dollar',
    flagEmoji: '🇦🇺',
    defaultScheme: NumberingScheme.western,
  );

  static const CurrencyItem sgd = CurrencyItem(
    code: 'SGD',
    symbol: r'$',
    name: 'Singapore Dollar',
    flagEmoji: '🇸🇬',
    defaultScheme: NumberingScheme.western,
  );

  static const List<CurrencyItem> supportedCurrencies = [
    inr,
    usd,
    eur,
    gbp,
    jpy,
    aed,
    cad,
    aud,
    sgd,
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CurrencyItem && runtimeType == other.runtimeType && code == other.code;

  @override
  int get hashCode => code.hashCode;
}

/// Immutable configuration holding active currency and numbering scheme settings.
class CurrencyConfig {
  final CurrencyItem currency;
  final NumberingScheme numberingScheme;
  final int decimalDigits;

  const CurrencyConfig({
    required this.currency,
    required this.numberingScheme,
    this.decimalDigits = 2,
  });

  CurrencyConfig copyWith({
    CurrencyItem? currency,
    NumberingScheme? numberingScheme,
    int? decimalDigits,
  }) {
    return CurrencyConfig(
      currency: currency ?? this.currency,
      numberingScheme: numberingScheme ?? this.numberingScheme,
      decimalDigits: decimalDigits ?? this.decimalDigits,
    );
  }
}

/// Phase 48: Multi-Currency & Numbering Localizer Manager.
///
/// Features:
/// 1. Reactive state management via [ValueNotifier<CurrencyConfig>].
/// 2. Configurable toggle between Indian (`12,34,567.00`) and Western (`1,234,567.00`) numbering systems.
/// 3. Dynamic active currency prefixing across forms, dialogs, and analytics.
class CurrencyManager extends ValueNotifier<CurrencyConfig> {
  CurrencyManager._()
      : super(
          const CurrencyConfig(
            currency: CurrencyItem.inr,
            numberingScheme: NumberingScheme.indian,
            decimalDigits: 2,
          ),
        );

  /// Central singleton instance.
  static final CurrencyManager instance = CurrencyManager._();

  /// Gets the active currency symbol (e.g. `₹`, `$`, `€`).
  String get activeSymbol => value.currency.symbol;

  /// Gets the active currency ISO code (e.g. `INR`, `USD`).
  String get activeCode => value.currency.code;

  /// Gets the active numbering scheme.
  NumberingScheme get activeScheme => value.numberingScheme;

  /// Updates the active currency and adapts default numbering scheme.
  void setCurrency(CurrencyItem currency, {NumberingScheme? scheme}) {
    value = value.copyWith(
      currency: currency,
      numberingScheme: scheme ?? currency.defaultScheme,
      decimalDigits: currency.defaultDecimalDigits,
    );
  }

  /// Updates the active numbering scheme explicitly.
  void setNumberingScheme(NumberingScheme scheme) {
    value = value.copyWith(numberingScheme: scheme);
  }

  /// Updates the decimal digits precision.
  void setDecimalDigits(int digits) {
    value = value.copyWith(decimalDigits: digits);
  }

  /// Formats numeric amount using current active or custom currency and numbering scheme.
  String format(
    double amount, {
    String? customSymbol,
    NumberingScheme? customScheme,
    int? customDecimalDigits,
    bool showSign = false,
  }) {
    final String symbol = customSymbol ?? value.currency.symbol;
    final NumberingScheme scheme = customScheme ?? value.numberingScheme;
    final int decimals = customDecimalDigits ?? value.decimalDigits;

    final double absAmount = amount.abs();
    final String formattedNumber = formatNumberOnly(
      absAmount,
      scheme: scheme,
      decimalDigits: decimals,
    );

    final String result = '$symbol$formattedNumber';
    if (showSign) {
      if (amount > 0) return '+$result';
      if (amount < 0) return '-$result';
    } else if (amount < 0) {
      return '-$result';
    }

    return result;
  }

  /// Formats numeric values without prepending currency symbol.
  static String formatNumberOnly(
    double amount, {
    NumberingScheme scheme = NumberingScheme.indian,
    int decimalDigits = 2,
  }) {
    final String locale = scheme == NumberingScheme.indian ? 'en_IN' : 'en_US';
    final NumberFormat numberFormat = NumberFormat.currency(
      locale: locale,
      symbol: '',
      decimalDigits: decimalDigits,
    );
    return numberFormat.format(amount).trim();
  }

  /// Formats compact monetary values (e.g. ₹1.2L, ₹4.5Cr for Indian; $1.2M, $4.5B for Western).
  String formatCompact(
    double amount, {
    String? customSymbol,
    NumberingScheme? customScheme,
  }) {
    final String symbol = customSymbol ?? value.currency.symbol;
    final NumberingScheme scheme = customScheme ?? value.numberingScheme;

    if (scheme == NumberingScheme.indian) {
      final double abs = amount.abs();
      String suffix = '';
      double valueToFormat = abs;

      if (abs >= 10000000) {
        valueToFormat = abs / 10000000;
        suffix = 'Cr';
      } else if (abs >= 100000) {
        valueToFormat = abs / 100000;
        suffix = 'L';
      } else if (abs >= 1000) {
        valueToFormat = abs / 1000;
        suffix = 'K';
      }

      final String formattedNum = valueToFormat.toStringAsFixed(
        valueToFormat.truncateToDouble() == valueToFormat ? 0 : 1,
      );
      final String formatted = '$symbol$formattedNum$suffix';
      return amount < 0 ? '-$formatted' : formatted;
    } else {
      final NumberFormat compactFormat = NumberFormat.compactCurrency(
        locale: 'en_US',
        symbol: symbol,
        decimalDigits: 1,
      );
      return compactFormat.format(amount);
    }
  }

  /// Parses an input string representation safely into a double amount.
  static double? parseAmount(String input) {
    if (input.trim().isEmpty) return null;
    final String clean = input.replaceAll(RegExp(r'[^0-9.-]'), '');
    return double.tryParse(clean);
  }

  /// Helper widget for prefixing TextFields with the reactive active currency symbol.
  Widget buildPrefixWidget({
    TextStyle? style,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 12),
  }) {
    return ValueListenableBuilder<CurrencyConfig>(
      valueListenable: this,
      builder: (context, config, _) {
        return Padding(
          padding: padding,
          child: Text(
            config.currency.symbol,
            style: style ??
                const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF14B8A6),
                ),
          ),
        );
      },
    );
  }
}
