import 'package:finance_app/core/theme/app_colors.dart';
import 'package:finance_app/features/automation/data/notification_listener_repo.dart';
import 'package:finance_app/features/automation/domain/payment_app_filter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Illustrated privacy consent screen for Android Notification Listener Bridge.
/// Explains that all parsing happens locally on-device and never reads chats, OTPs, or passwords.
class NotificationConsentScreen extends StatefulWidget {
  const NotificationConsentScreen({
    super.key,
    this.repository,
    this.onPermissionGranted,
  });

  final NotificationListenerRepo? repository;
  final VoidCallback? onPermissionGranted;

  @override
  State<NotificationConsentScreen> createState() =>
      _NotificationConsentScreenState();
}

class _NotificationConsentScreenState extends State<NotificationConsentScreen>
    with SingleTickerProviderStateMixin {
  late final NotificationListenerRepo _repo;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  bool _isPermissionGranted = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? NotificationListenerRepo();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );

    _checkInitialPermission();
  }

  Future<void> _checkInitialPermission() async {
    final bool granted = await _repo.isPermissionGranted();
    if (mounted) {
      setState(() {
        _isPermissionGranted = granted;
      });
    }
  }

  Future<void> _handleRequestPermission() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _isLoading = true;
    });

    try {
      final bool granted = await _repo.requestPermission();
      if (granted) {
        await _repo.startListening();
      }
      if (mounted) {
        setState(() {
          _isPermissionGranted = granted;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: granted ? AppColors.successGreen : AppColors.expenseRed,
            content: Text(
              granted
                  ? 'Notification Listener permission active (On-Device only)'
                  : 'Permission was not granted',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        );

        if (granted) {
          widget.onPermissionGranted?.call();
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkSlateBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Automated Expense Sync',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Custom Illustrated Shield Visual
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    size: const Size(200, 160),
                    painter: _ShieldIllustrationPainter(pulseProgress: _pulseAnimation.value),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Header Title & Subtitle
              const Text(
                '100% On-Device Privacy',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'SpendVault processes transaction alerts strictly on your phone. Your private data never touches any external servers.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Guarantee Feature Cards
              _buildPrivacyCard(
                icon: Icons.phonelink_lock_rounded,
                iconColor: AppColors.accentIndigo,
                title: 'Local Computation Engine',
                description:
                    'Regex & heuristics run exclusively in local memory. Zero cloud data transmission.',
              ),
              const SizedBox(height: 12),
              _buildPrivacyCard(
                icon: Icons.shield_outlined,
                iconColor: AppColors.successGreen,
                title: 'Never Reads Chats, OTPs or Passwords',
                description:
                    'Strict filters ignore messaging apps, two-factor authentication codes, passwords, and private chats.',
              ),
              const SizedBox(height: 12),
              _buildPrivacyCard(
                icon: Icons.account_balance_wallet_outlined,
                iconColor: AppColors.accentViolet,
                title: 'Bank & UPI Alerts Only',
                description:
                    'Detects official banking debits, credits, and merchant receipts to log your expenses automatically.',
              ),
              const SizedBox(height: 20),

              // Whitelisted Payment Apps Section
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Whitelisted Payment Apps (${PaymentAppFilter.paymentApps.length})',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: PaymentAppFilter.supportedAppNames.map((appName) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCardHover,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.borderStroke),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified_user_rounded,
                          size: 14,
                          color: AppColors.successGreen,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          appName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),

              // CTA Action Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRequestPermission,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isPermissionGranted
                        ? AppColors.successGreen
                        : AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isPermissionGranted
                                  ? Icons.check_circle_rounded
                                  : Icons.notifications_active_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isPermissionGranted
                                  ? 'Notification Access Active'
                                  : 'Enable Notification Access',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 14),

              // Skip / Later Option
              TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text(
                  'Skip for now',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderStroke),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter rendering a glowing privacy shield vector illustration.
class _ShieldIllustrationPainter extends CustomPainter {
  _ShieldIllustrationPainter({required this.pulseProgress});

  final double pulseProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;

    // Glowing Pulse Rings
    final Paint pulsePaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.08 + (pulseProgress * 0.12))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(
      Offset(centerX, centerY),
      55 + (pulseProgress * 15),
      pulsePaint,
    );

    // Inner Glow Aura
    final Paint auraPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.primary.withValues(alpha: 0.35),
          AppColors.primary.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: Offset(centerX, centerY), radius: 60));

    canvas.drawCircle(Offset(centerX, centerY), 60, auraPaint);

    // Shield Body Path
    final Path shieldPath = Path();
    const double w = 70;
    const double h = 85;
    final double top = centerY - h / 2;
    final double left = centerX - w / 2;
    final double right = centerX + w / 2;

    shieldPath.moveTo(left, top + 15);
    shieldPath.quadraticBezierTo(centerX, top - 10, right, top + 15);
    shieldPath.lineTo(right, top + h * 0.55);
    shieldPath.quadraticBezierTo(right, top + h * 0.85, centerX, top + h);
    shieldPath.quadraticBezierTo(left, top + h * 0.85, left, top + h * 0.55);
    shieldPath.close();

    final Paint shieldFill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF6366F1),
          Color(0xFF8B5CF6),
        ],
      ).createShader(Rect.fromLTWH(left, top, w, h));

    final Paint shieldBorder = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawPath(shieldPath, shieldFill);
    canvas.drawPath(shieldPath, shieldBorder);

    // Lock Body inside Shield
    final Paint lockPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final Rect lockRect = Rect.fromCenter(
      center: Offset(centerX, centerY + 8),
      width: 24,
      height: 20,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(lockRect, const Radius.circular(5)),
      lockPaint,
    );

    // Lock Shackle
    final Paint shacklePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final Path shacklePath = Path()
      ..moveTo(centerX - 7, centerY - 2)
      ..lineTo(centerX - 7, centerY - 8)
      ..arcToPoint(
        Offset(centerX + 7, centerY - 8),
        radius: const Radius.circular(7),
      )
      ..lineTo(centerX + 7, centerY - 2);

    canvas.drawPath(shacklePath, shacklePaint);

    // Keyhole Dot
    final Paint keyholePaint = Paint()..color = AppColors.primary;
    canvas.drawCircle(Offset(centerX, centerY + 7), 2.5, keyholePaint);
  }

  @override
  bool shouldRepaint(covariant _ShieldIllustrationPainter oldDelegate) {
    return oldDelegate.pulseProgress != pulseProgress;
  }
}
