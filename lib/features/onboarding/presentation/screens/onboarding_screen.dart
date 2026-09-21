import 'package:finance_app/core/constants/app_constants.dart';
import 'package:finance_app/core/theme/app_colors.dart';
import 'package:finance_app/features/onboarding/domain/onboarding_service.dart';
import 'package:finance_app/features/onboarding/presentation/widgets/onboarding_illustrations.dart';
import 'package:flutter/material.dart';

// ── Slide Data ────────────────────────────────────────────────────────────────

class _SlideData {
  const _SlideData({
    required this.title,
    required this.subtitle,
    required this.accentColor,
  });

  final String title;
  final String subtitle;
  final Color accentColor;
}

const List<_SlideData> _slides = <_SlideData>[
  _SlideData(
    title: 'Complete On-Device Storage',
    subtitle:
        'Your financial data never leaves your phone.\nZero servers. Zero tracking. Total privacy.',
    accentColor: Color(0xFF0D9488),
  ),
  _SlideData(
    title: 'Multi-Account Ledger',
    subtitle:
        'Bank accounts, UPI wallets, and cash — all tracked in one unified ledger, always in sync.',
    accentColor: Color(0xFF0891B2),
  ),
  _SlideData(
    title: 'Automatic Detection',
    subtitle:
        'Transactions are read directly from local notification parsing — no manual entry needed.',
    accentColor: Color(0xFF7C3AED),
  ),
];

// ── Screen ────────────────────────────────────────────────────────────────────

/// First-launch onboarding carousel.
///
/// Shown once on fresh install. After completion (or skip), writes a sentinel
/// file via [OnboardingService] and navigates to the dashboard.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Slide-text fade animation
  late final AnimationController _textFade;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _textFade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _textFade,
      curve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _textFade.dispose();
    super.dispose();
  }

  // ── Navigation ──────────────────────────────────────────────────────────────

  Future<void> _next() async {
    if (_currentPage < _slides.length - 1) {
      await _animateTextOut();
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOutCubic,
      );
    } else {
      await _finish();
    }
  }

  Future<void> _skip() async => _finish();

  Future<void> _finish() async {
    await OnboardingService.instance.markOnboardingSeen();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppConstants.dashboardRoute);
  }

  Future<void> _animateTextOut() async {
    await _textFade.reverse();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    _textFade.forward();
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final _SlideData slide = _slides[_currentPage];
    final Size screen = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.darkSlateBackground,
      body: Stack(
        children: <Widget>[
          // ── Background gradient accent ──────────────────────────────────────
          Positioned(
            top: -80,
            left: -80,
            child: _GlowOrb(color: slide.accentColor, size: 280),
          ),
          Positioned(
            bottom: -60,
            right: -60,
            child: _GlowOrb(color: slide.accentColor.withValues(alpha: 0.5), size: 200),
          ),

          // ── Main content ───────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: <Widget>[
                // Skip button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, right: 16),
                    child: _currentPage < _slides.length - 1
                        ? TextButton(
                            key: const Key('skip_button'),
                            onPressed: _skip,
                            child: const Text(
                              'Skip',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                        : const SizedBox(height: 40),
                  ),
                ),

                // Illustration PageView
                Expanded(
                  flex: 5,
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemCount: _slides.length,
                    itemBuilder: (BuildContext context, int index) {
                      return Center(
                        child: onboardingIllustration(
                          index,
                          size: screen.width * 0.65,
                        ),
                      );
                    },
                  ),
                ),

                // Text content (fades between slides)
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              color: slide.accentColor,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              height: 1.3,
                            ),
                            child: Text(
                              slide.title,
                              key: ValueKey<int>(_currentPage),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            slide.subtitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Dot indicator + CTA button
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
                  child: Column(
                    children: <Widget>[
                      // Dot indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List<Widget>.generate(_slides.length, (int i) {
                          final bool active = i == _currentPage;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: active ? 28 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: active
                                  ? slide.accentColor
                                  : AppColors.textMuted,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 32),

                      // Next / Get Started button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton(
                          key: const Key('next_button'),
                          onPressed: _next,
                          style: FilledButton.styleFrom(
                            backgroundColor: slide.accentColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Text(
                              _currentPage == _slides.length - 1
                                  ? 'Get Started'
                                  : 'Next',
                              key: ValueKey<String>(
                                _currentPage == _slides.length - 1
                                    ? 'get_started'
                                    : 'next',
                              ),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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

// ── Private Helpers ───────────────────────────────────────────────────────────

/// Soft radial glow orb used as a background accent behind each slide.
class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: <Color>[
            color.withValues(alpha: 0.25),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
