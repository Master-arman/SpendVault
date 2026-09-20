import 'dart:async';
import 'package:finance_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Foreground floating confirmation card displayed when a transaction is detected.
/// Shows amount, merchant, and inferred category with 10-second auto-confirm countdown.
class IncomingTransactionBanner extends StatefulWidget {
  const IncomingTransactionBanner({
    super.key,
    required this.amount,
    required this.merchant,
    required this.category,
    this.isAnomaly = false,
    this.currencySymbol = '₹',
    this.autoConfirmDuration = const Duration(seconds: 10),
    this.onConfirm,
    this.onChangeCategory,
    this.onDismiss,
  });

  final double amount;
  final String merchant;
  final String category;
  final bool isAnomaly;
  final String currencySymbol;
  final Duration autoConfirmDuration;
  final VoidCallback? onConfirm;
  final VoidCallback? onChangeCategory;
  final VoidCallback? onDismiss;

  @override
  State<IncomingTransactionBanner> createState() =>
      _IncomingTransactionBannerState();
}

class _IncomingTransactionBannerState extends State<IncomingTransactionBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progressController;
  Timer? _countdownTimer;
  int _secondsRemaining = 10;
  bool _isActionTaken = false;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.autoConfirmDuration.inSeconds;

    _progressController = AnimationController(
      vsync: this,
      duration: widget.autoConfirmDuration,
    )..forward();

    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_secondsRemaining > 1) {
          _secondsRemaining--;
        } else {
          _secondsRemaining = 0;
          timer.cancel();
          _handleAutoConfirm();
        }
      });
    });
  }

  void _stopCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    if (_progressController.isAnimating) {
      _progressController.stop();
    }
  }

  void _handleAutoConfirm() {
    if (_isActionTaken) return;
    _isActionTaken = true;
    _stopCountdown();
    widget.onConfirm?.call();
  }

  void _handleManualConfirm() {
    if (_isActionTaken) return;
    _isActionTaken = true;
    HapticFeedback.mediumImpact();
    _stopCountdown();
    widget.onConfirm?.call();
  }

  void _handleChangeCategory() {
    if (_isActionTaken) return;
    HapticFeedback.lightImpact();
    _stopCountdown();
    widget.onChangeCategory?.call();
  }

  void _handleDismiss() {
    if (_isActionTaken) return;
    _isActionTaken = true;
    HapticFeedback.lightImpact();
    _stopCountdown();
    widget.onDismiss?.call();
  }

  @override
  void dispose() {
    _stopCountdown();
    _progressController.dispose();
    super.dispose();
  }

  String _formatAmount(double amount) {
    if (amount == amount.roundToDouble()) {
      return amount.toInt().toString();
    }
    return amount.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final String formattedAmount = _formatAmount(widget.amount);
    final String bannerText =
        'Detected ${widget.currencySymbol}$formattedAmount spent at ${widget.merchant}. Category: ${widget.category}.';

    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.isAnomaly
                ? AppColors.expenseRed.withValues(alpha: 0.8)
                : AppColors.primary.withValues(alpha: 0.5),
            width: widget.isAnomaly ? 2.0 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: (widget.isAnomaly ? AppColors.expenseRed : AppColors.primary)
                  .withValues(alpha: widget.isAnomaly ? 0.25 : 0.15),
              blurRadius: 14,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Countdown Progress Bar
            AnimatedBuilder(
              animation: _progressController,
              builder: (context, child) {
                return LinearProgressIndicator(
                  value: 1.0 - _progressController.value,
                  backgroundColor: AppColors.borderStroke,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.isAnomaly ? AppColors.expenseRed : AppColors.primary,
                  ),
                  minHeight: 3.5,
                );
              },
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with Auto-Confirm Timer Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: (widget.isAnomaly ? AppColors.expenseRed : AppColors.primary)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              widget.isAnomaly
                                  ? Icons.warning_rounded
                                  : Icons.auto_awesome_rounded,
                              size: 16,
                              color: widget.isAnomaly
                                  ? AppColors.expenseRed
                                  : AppColors.accentIndigo,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.isAnomaly
                                ? 'Anomaly Alert'
                                : 'Instant Transaction Alert',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: widget.isAnomaly
                                  ? AppColors.expenseRed
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCardHover,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: widget.isAnomaly
                                ? AppColors.expenseRed.withValues(alpha: 0.4)
                                : AppColors.borderStroke,
                          ),
                        ),
                        child: Text(
                          'Auto-saving in ${_secondsRemaining}s',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // High-priority visual warning chip for unusual expense
                  if (widget.isAnomaly) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.expenseRed.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.expenseRed.withValues(alpha: 0.6),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 16,
                            color: AppColors.expenseRed,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Unusual Expense Detected',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.expenseRed,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Detected Transaction Details Text
                  Text(
                    bannerText,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Action Buttons: [Confirm], [Change Category], [Dismiss]
                  Row(
                    children: [
                      // Confirm Button
                      Expanded(
                        flex: 3,
                        child: ElevatedButton.icon(
                          onPressed: _handleManualConfirm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.successGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: const Text(
                            'Confirm',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Change Category Button
                      Expanded(
                        flex: 4,
                        child: OutlinedButton.icon(
                          onPressed: _handleChangeCategory,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            side: const BorderSide(color: AppColors.borderStroke),
                            backgroundColor: AppColors.surfaceCardHover,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.category_outlined, size: 16, color: AppColors.indigoLight),
                          label: const Text(
                            'Change Category',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Dismiss Button
                      IconButton(
                        onPressed: _handleDismiss,
                        tooltip: 'Dismiss',
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.surfaceCardHover,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(color: AppColors.borderStroke),
                          ),
                          padding: const EdgeInsets.all(8),
                        ),
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
