import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A high-performance rolling financial counter engine that smoothly interpolates
/// numeric values and balances with zero UI thread stutter.
///
/// Features:
/// - Subclasses [ImplicitlyAnimatedWidget] for native implicit animation lifecycle.
/// - Default transition curve: [Curves.easeOutExpo] over `1000ms`.
/// - Localized Indian numbering formatting: `NumberFormat.currency(locale: 'en_IN', symbol: '₹')`.
class RollingCounter extends ImplicitlyAnimatedWidget {
  const RollingCounter({
    super.key,
    required this.value,
    this.style,
    this.textAlign,
    this.locale = 'en_IN',
    this.symbol = '₹',
    this.decimalDigits = 2,
    this.prefix = '',
    this.suffix = '',
    this.builder,
    super.duration = const Duration(milliseconds: 1000),
    super.curve = Curves.easeOutExpo,
    super.onEnd,
  });

  /// The target numerical balance or value to animate towards.
  final double value;

  /// Optional text styling applied to the rendered counter text.
  final TextStyle? style;

  /// Text alignment for the counter display.
  final TextAlign? textAlign;

  /// Currency locale identifier (defaults to `'en_IN'`).
  final String locale;

  /// Currency symbol prefix (defaults to `'₹'`).
  final String symbol;

  /// Number of decimal digits to preserve (defaults to `2`).
  final int decimalDigits;

  /// Optional prefix string before the formatted balance.
  final String prefix;

  /// Optional suffix string after the formatted balance.
  final String suffix;

  /// Optional custom builder for arbitrary styling/layout per frame.
  final Widget Function(BuildContext context, double interpolatedValue, String formattedText)?
      builder;

  @override
  ImplicitlyAnimatedWidgetState<RollingCounter> createState() =>
      _RollingCounterState();
}

class _RollingCounterState extends AnimatedWidgetBaseState<RollingCounter> {
  Tween<double>? _valueTween;
  late NumberFormat _cachedFormatter;
  String _lastLocale = '';
  String _lastSymbol = '';
  int _lastDecimalDigits = -1;

  @override
  void initState() {
    super.initState();
    _updateFormatter();
  }

  void _updateFormatter() {
    if (_lastLocale != widget.locale ||
        _lastSymbol != widget.symbol ||
        _lastDecimalDigits != widget.decimalDigits) {
      _lastLocale = widget.locale;
      _lastSymbol = widget.symbol;
      _lastDecimalDigits = widget.decimalDigits;
      _cachedFormatter = NumberFormat.currency(
        locale: widget.locale,
        symbol: widget.symbol,
        decimalDigits: widget.decimalDigits,
      );
    }
  }

  @override
  void didUpdateWidget(RollingCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateFormatter();
  }

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _valueTween = visitor(
      _valueTween,
      widget.value,
      (dynamic value) => Tween<double>(begin: value as double),
    ) as Tween<double>?;
  }

  @override
  Widget build(BuildContext context) {
    final double currentValue = _valueTween?.evaluate(animation) ?? widget.value;
    final String formatted = _cachedFormatter.format(currentValue);
    final String displayText = '${widget.prefix}$formatted${widget.suffix}';

    if (widget.builder != null) {
      return widget.builder!(context, currentValue, displayText);
    }

    return Text(
      displayText,
      style: widget.style,
      textAlign: widget.textAlign,
    );
  }
}
