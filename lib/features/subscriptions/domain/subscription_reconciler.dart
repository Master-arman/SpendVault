import 'package:finance_app/features/subscriptions/data/models/subscription.dart';
import 'package:finance_app/features/subscriptions/domain/models/subscription_model.dart';
import 'package:finance_app/features/transactions/data/models/transaction.dart';
import 'package:intl/intl.dart';

/// Result container for an executed subscription renewal reconciliation.
class ReconciliationResult {
  const ReconciliationResult({
    required this.transaction,
    required this.originalBillingDate,
    required this.updatedNextBillingDate,
    required this.subscriptionName,
  });

  final Transaction transaction;
  final DateTime originalBillingDate;
  final DateTime updatedNextBillingDate;
  final String subscriptionName;
}

/// Prompt metadata for an overdue subscription requiring user confirmation.
class OverdueSubscriptionPrompt {
  const OverdueSubscriptionPrompt({
    required this.subscriptionId,
    required this.subscriptionName,
    required this.amount,
    required this.cycle,
    required this.dueBillingDate,
    required this.promptText,
    this.subscription,
  });

  final int subscriptionId;
  final String subscriptionName;
  final double amount;
  final BillingCycle cycle;
  final DateTime dueBillingDate;
  final String promptText;
  final Subscription? subscription;
}

/// Phase 35: Downtime Catch-Up & Cold-Boot Auto-Reconciler.
///
/// On every application start, inspects recurring subscriptions against [DateTime.now()].
/// If the app was closed and renewal dates have passed, generates friendly confirmation prompts:
/// e.g. "Did your Netflix renewal for ₹649 go through on 12th Sept?"
///
/// When confirmed, advances [nextBillingDate] by one [BillingCycle] and creates the matching [Transaction] record.
class SubscriptionReconciler {
  const SubscriptionReconciler();

  /// Formats ordinal day suffix: 1st, 2nd, 3rd, 4th, 11th, 12th, 13th, 21st, 22nd...
  static String getOrdinalSuffix(int day) {
    if (day >= 11 && day <= 13) {
      return '${day}th';
    }
    switch (day % 10) {
      case 1:
        return '${day}st';
      case 2:
        return '${day}nd';
      case 3:
        return '${day}rd';
      default:
        return '${day}th';
    }
  }

  /// Formats date with ordinal day and short month abbreviation:
  /// e.g. "12th Sept", "1st Oct", "23rd Jan"
  static String formatOrdinalDate(DateTime date) {
    final String ordinalDay = getOrdinalSuffix(date.day);
    String month = DateFormat('MMM').format(date);
    // Standardize Sep -> Sept for standard Indian English / user spec
    if (month == 'Sep') {
      month = 'Sept';
    }
    return '$ordinalDay $month';
  }

  /// Formats numeric amount without trailing decimals when whole:
  /// e.g. 649.0 -> "649", 649.50 -> "649.50"
  static String formatAmount(double amount) {
    if (amount == amount.roundToDouble()) {
      return amount.toInt().toString();
    }
    return amount.toStringAsFixed(2);
  }

  /// Formats the cold-boot catch-up prompt string:
  /// e.g. "Did your Netflix renewal for ₹649 go through on 12th Sept?"
  static String formatCatchUpPrompt({
    required String name,
    required double amount,
    required DateTime billingDate,
    String currencySymbol = '₹',
  }) {
    final String amountStr = formatAmount(amount);
    final String dateStr = formatOrdinalDate(billingDate);
    return 'Did your $name renewal for $currencySymbol$amountStr go through on $dateStr?';
  }

  /// Advances a [DateTime] forward by one [BillingCycle], handling month overflows and leap years.
  static DateTime advanceBillingDate(DateTime current, BillingCycle cycle) {
    switch (cycle) {
      case BillingCycle.weekly:
        return current.add(const Duration(days: 7));

      case BillingCycle.monthly:
        return _addMonths(current, 1);

      case BillingCycle.quarterly:
        return _addMonths(current, 3);

      case BillingCycle.yearly:
        return _addMonths(current, 12);
    }
  }

  /// Helper to safely add months while clamping day-of-month (e.g. Jan 31 -> Feb 28).
  static DateTime _addMonths(DateTime date, int monthsToAdd) {
    final int newYear = date.year + ((date.month + monthsToAdd - 1) ~/ 12);
    final int newMonth = ((date.month + monthsToAdd - 1) % 12) + 1;
    final int daysInTargetMonth = DateTime(newYear, newMonth + 1, 0).day;
    final int newDay = date.day > daysInTargetMonth ? daysInTargetMonth : date.day;

    return DateTime(
      newYear,
      newMonth,
      newDay,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );
  }

  /// Inspects a list of [Subscription] records and returns prompts for any active overdue renewals.
  List<OverdueSubscriptionPrompt> findOverdueSubscriptions({
    required List<Subscription> subscriptions,
    DateTime? now,
    String currencySymbol = '₹',
  }) {
    final DateTime currentTime = now ?? DateTime.now();
    final List<OverdueSubscriptionPrompt> prompts = [];

    for (final sub in subscriptions) {
      if (!sub.isActive) continue;

      if (sub.nextBillingDate.isBefore(currentTime)) {
        prompts.add(
          OverdueSubscriptionPrompt(
            subscriptionId: sub.id,
            subscriptionName: sub.name,
            amount: sub.amount,
            cycle: sub.cycle,
            dueBillingDate: sub.nextBillingDate,
            promptText: formatCatchUpPrompt(
              name: sub.name,
              amount: sub.amount,
              billingDate: sub.nextBillingDate,
              currencySymbol: currencySymbol,
            ),
            subscription: sub,
          ),
        );
      }
    }

    return prompts;
  }

  /// Reconciles an overdue [Subscription]:
  /// 1. Generates matching [Transaction] expense record.
  /// 2. Advances [subscription.nextBillingDate] forward by one [BillingCycle].
  ReconciliationResult reconcileSubscription({
    required Subscription subscription,
    DateTime? transactionDate,
    String? customNote,
  }) {
    final DateTime originalDate = subscription.nextBillingDate;
    final DateTime effectiveDate = transactionDate ?? originalDate;

    // 1. Generate matching transaction record
    final transaction = Transaction()
      ..amount = subscription.amount
      ..type = TransactionType.expense
      ..timestamp = effectiveDate
      ..note = customNote ?? 'Recurring Renewal: ${subscription.name}'
      ..tags = [
        'subscription',
        'recurring',
        'auto-reconciled',
        subscription.name.toLowerCase().trim(),
      ];

    // Link category & account if available
    if (subscription.category.value != null) {
      transaction.category.value = subscription.category.value;
    }
    if (subscription.account.value != null) {
      transaction.sourceAccount.value = subscription.account.value;
    }

    // 2. Advance nextBillingDate forward by one BillingCycle
    final DateTime nextDate = advanceBillingDate(originalDate, subscription.cycle);
    subscription.nextBillingDate = nextDate;

    return ReconciliationResult(
      transaction: transaction,
      originalBillingDate: originalDate,
      updatedNextBillingDate: nextDate,
      subscriptionName: subscription.name,
    );
  }

  /// Reconciles a domain [SubscriptionModel] entity and returns generated [Transaction] and next date.
  ReconciliationResult reconcileModel({
    required SubscriptionModel model,
    DateTime? transactionDate,
    String? customNote,
  }) {
    final DateTime originalDate = model.nextBillingDate;
    final DateTime effectiveDate = transactionDate ?? originalDate;

    final transaction = Transaction()
      ..amount = model.amount
      ..type = TransactionType.expense
      ..timestamp = effectiveDate
      ..note = customNote ?? 'Recurring Renewal: ${model.name}'
      ..tags = [
        'subscription',
        'recurring',
        'auto-reconciled',
        model.name.toLowerCase().trim(),
      ];

    final DateTime nextDate = advanceBillingDate(originalDate, model.cycle);

    return ReconciliationResult(
      transaction: transaction,
      originalBillingDate: originalDate,
      updatedNextBillingDate: nextDate,
      subscriptionName: model.name,
    );
  }
}
