import 'dart:async';
import 'package:finance_app/core/constants/app_constants.dart';
import 'package:finance_app/core/theme/app_colors.dart';
import 'package:finance_app/core/theme/radial_expansion_route.dart';
import 'package:finance_app/features/dashboard/presentation/dashboard_shell.dart';
import 'package:finance_app/features/onboarding/domain/onboarding_service.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _glowAnimation;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _navigationTimer = Timer(const Duration(milliseconds: 1800), _navigateToHome);
  }

  Future<void> _navigateToHome() async {
    if (!mounted) return;

    final bool seenOnboarding =
        await OnboardingService.instance.hasSeenOnboarding();

    if (!mounted) return;

    if (!seenOnboarding) {
      Navigator.of(context)
          .pushReplacementNamed(AppConstants.onboardingRoute);
    } else {
      Navigator.of(context).pushReplacement(
        RadialExpansionRoute<void>(
          page: const DashboardShell(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkSlateBackground,
      body: Center(
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (BuildContext context, Widget? child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.primaryGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentIndigo.withValues(
                            alpha: _glowAnimation.value * 0.6,
                          ),
                          blurRadius: 36,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 44,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'FINANCEX',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4.0,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Autonomous Wealth Management',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
