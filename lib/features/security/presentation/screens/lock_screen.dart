import 'package:finance_app/features/security/domain/biometric_auth_service.dart';
import 'package:flutter/material.dart';

/// Full-screen biometric lock overlay.
///
/// Shown automatically when [BiometricAuthService.isLocked] is `true`. On
/// mount it immediately triggers the system authentication prompt so the user
/// isn't faced with a dead screen.
class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen>
    with SingleTickerProviderStateMixin {
  final BiometricAuthService _authService = BiometricAuthService.instance;

  bool _isAuthenticating = false;
  String? _errorMessage;

  // Pulse animation for the fingerprint icon
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Trigger auth immediately on screen mount.
    WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ── Auth Logic ──────────────────────────────────────────────────────────────

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    final AuthResult result = await _authService.authenticate();

    if (!mounted) return;

    switch (result) {
      case AuthResult.success:
        // isLocked notifier flips to false → AppLockObserver rebuilds.
        break;

      case AuthResult.failure:
        setState(() {
          _isAuthenticating = false;
          _errorMessage = 'Authentication failed. Please try again.';
        });

      case AuthResult.notAvailable:
        setState(() {
          _isAuthenticating = false;
          _errorMessage =
              'Biometric authentication is not available on this device.';
        });

      case AuthResult.error:
        setState(() {
          _isAuthenticating = false;
          _errorMessage = 'An error occurred. Please try again.';
        });
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const Spacer(flex: 2),

              // ── App Logo / Title ──────────────────────────────────────────
              _AppLogo(colorScheme: cs),

              const SizedBox(height: 48),

              // ── Fingerprint Icon (animated) ───────────────────────────────
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.primaryContainer,
                  ),
                  child: Icon(
                    Icons.fingerprint_rounded,
                    size: 56,
                    color: cs.primary,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ── Subtitle ──────────────────────────────────────────────────
              Text(
                'Locked',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Authenticate to access your financial ledger',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 24),

              // ── Error Message ─────────────────────────────────────────────
              if (_errorMessage != null) ...<Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: cs.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 18,
                        color: cs.onErrorContainer,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _errorMessage!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              const Spacer(flex: 2),

              // ── Unlock Button ─────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  key: const Key('unlock_button'),
                  onPressed: _isAuthenticating ? null : _authenticate,
                  icon: _isAuthenticating
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.onPrimary,
                          ),
                        )
                      : const Icon(Icons.lock_open_rounded),
                  label: Text(
                    _isAuthenticating ? 'Authenticating…' : 'Unlock',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
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
}

// ── Private Widgets ─────────────────────────────────────────────────────────

class _AppLogo extends StatelessWidget {
  const _AppLogo({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[
                colorScheme.primary,
                colorScheme.tertiary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.account_balance_wallet_rounded,
            size: 38,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'SpendVault',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}
