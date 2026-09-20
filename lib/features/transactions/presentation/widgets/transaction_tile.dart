import 'package:finance_app/core/theme/app_colors.dart';
import 'package:finance_app/core/utils/currency_formatter.dart';
import 'package:finance_app/features/transactions/domain/models/transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    required this.transaction,
    this.onTap,
    super.key,
  });

  final TransactionModel transaction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool isIncome = transaction.isIncome;
    final DateFormat formatter = DateFormat('MMM d, h:mm a');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderStroke),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isIncome
                        ? AppColors.successGreenSoft
                        : AppColors.expenseRedSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isIncome
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded,
                    color: isIncome ? AppColors.successGreen : AppColors.expenseRed,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            formatter.format(transaction.date),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                          if (transaction.isAutomated) ...[
                            const SizedBox(width: 6),
                            const Text('•', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                            const SizedBox(width: 6),
                            const Icon(Icons.bolt_rounded, size: 12, color: AppColors.indigoLight),
                            const SizedBox(width: 2),
                            const Text('Auto', style: TextStyle(fontSize: 11, color: AppColors.indigoLight, fontWeight: FontWeight.w500)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  CurrencyFormatter.format(
                    transaction.amount,
                    showSign: true,
                  ),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isIncome ? AppColors.successGreen : AppColors.textPrimary,
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
