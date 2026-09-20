import 'dart:math' as math;
import 'package:finance_app/core/theme/app_colors.dart';
import 'package:finance_app/core/theme/interactive_card.dart';
import 'package:finance_app/core/widgets/rolling_counter.dart';
import 'package:finance_app/features/accounts/data/models/account.dart';
import 'package:flutter/material.dart';

/// 3D Carousel Widget supporting card snapping via [PageController] (viewportFraction: 0.88)
/// and dynamic 3D card tilt via [Transform] with perspective rotation matrix.
class AccountCarousel3D extends StatefulWidget {
  const AccountCarousel3D({
    super.key,
    required this.accounts,
    this.onAccountSelected,
    this.initialIndex = 0,
    this.height = 200,
  });

  final List<Account> accounts;
  final ValueChanged<Account>? onAccountSelected;
  final int initialIndex;
  final double height;

  @override
  State<AccountCarousel3D> createState() => _AccountCarousel3DState();
}

class _AccountCarousel3DState extends State<AccountCarousel3D> {
  late final PageController _pageController;
  double _currentPage = 0.0;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialIndex.toDouble();
    _pageController = PageController(
      viewportFraction: 0.88,
      initialPage: widget.initialIndex,
    );
    _pageController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_pageController.position.haveDimensions) {
      setState(() {
        _currentPage = _pageController.page ?? 0.0;
      });
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_onScroll);
    _pageController.dispose();
    super.dispose();
  }

  IconData _getTypeIcon(AccountType type) {
    switch (type) {
      case AccountType.bank:
        return Icons.account_balance_rounded;
      case AccountType.creditCard:
        return Icons.credit_card_rounded;
      case AccountType.wallet:
        return Icons.account_balance_wallet_rounded;
      case AccountType.cash:
        return Icons.payments_rounded;
    }
  }

  String _getTypeLabel(AccountType type) {
    switch (type) {
      case AccountType.bank:
        return 'BANK ACCOUNT';
      case AccountType.creditCard:
        return 'CREDIT CARD';
      case AccountType.wallet:
        return 'DIGITAL WALLET';
      case AccountType.cash:
        return 'CASH LEDGER';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.accounts.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: widget.height,
      child: PageView.builder(
        controller: _pageController,
        itemCount: widget.accounts.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (BuildContext context, int index) {
          final Account account = widget.accounts[index];
          final double diff = index - _currentPage;
          final double angle = (diff * 0.28).clamp(-math.pi / 4, math.pi / 4);

          final Matrix4 transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle);

          final Color cardBaseColor = Color(account.colorHex);

          return Transform(
            transform: transform,
            alignment: diff > 0 ? FractionalOffset.centerLeft : FractionalOffset.centerRight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: InteractiveCard(
                onTap: () => widget.onAccountSelected?.call(account),
                duration: const Duration(milliseconds: 140),
                borderRadius: BorderRadius.circular(20),
                backgroundColor: cardBaseColor.withValues(alpha: 0.15),
                border: Border.all(
                  color: cardBaseColor.withValues(alpha: 0.35),
                  width: 1.2,
                ),
                hoverBorder: Border.all(
                  color: cardBaseColor,
                  width: 1.5,
                ),
                hoverBoxShadow: [
                  BoxShadow(
                    color: cardBaseColor.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: cardBaseColor.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                _getTypeIcon(account.type),
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  account.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  _getTypeLabel(account.type),
                                  style: TextStyle(
                                    fontSize: 10,
                                    letterSpacing: 0.8,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (account.isDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.accentIndigo.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppColors.indigoLight.withValues(alpha: 0.6),
                              ),
                            ),
                            child: const Text(
                              'PRIMARY',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: AppColors.indigoLight,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AVAILABLE BALANCE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 4),
                            RollingCounter(
                              value: account.currentBalance,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        if (account.last4Digits != null && account.last4Digits!.isNotEmpty)
                          Text(
                            '•••• ${account.last4Digits}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.75),
                              letterSpacing: 1.2,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
