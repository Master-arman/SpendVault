import 'package:finance_app/core/theme/app_colors.dart';
import 'package:finance_app/core/utils/currency_formatter.dart';
import 'package:finance_app/features/accounts/domain/models/account_model.dart';
import 'package:flutter/material.dart';

class AccountCard extends StatelessWidget {
  const AccountCard({
    required this.account,
    this.onTap,
    super.key,
  });

  final AccountModel account;
  final VoidCallback? onTap;

  IconData _getAccountIcon() {
    switch (account.type) {
      case AccountType.bank:
        return Icons.account_balance_rounded;
      case AccountType.creditCard:
        return Icons.credit_card_rounded;
      case AccountType.wallet:
        return Icons.account_balance_wallet_rounded;
      case AccountType.investment:
        return Icons.trending_up_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isNegative = account.balance < 0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderStroke),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.accentIndigo.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getAccountIcon(),
                        color: AppColors.accentIndigo,
                        size: 20,
                      ),
                    ),
                    if (account.isDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accentIndigo.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.accentIndigo.withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Text(
                          'DEFAULT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.indigoLight,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  account.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${account.institutionName} • ${account.accountNumberMasked}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  CurrencyFormatter.format(
                    account.balance,
                    currencySymbol: '\$',
                  ),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: isNegative ? AppColors.expenseRed : AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
