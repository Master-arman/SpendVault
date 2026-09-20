import 'package:finance_app/features/accounts/data/models/account.dart';
import 'package:finance_app/features/subscriptions/data/models/subscription.dart';
import 'package:finance_app/features/subscriptions/domain/models/subscription_model.dart';
import 'package:finance_app/features/subscriptions/domain/subscription_reconciler.dart';
import 'package:finance_app/features/transactions/data/models/transaction.dart';
import 'package:finance_app/features/transactions/domain/transaction_service.dart';
import 'package:isar/isar.dart';

/// Result summary of an automatically logged recurring subscription renewal.
class AutoLogExecutionResult {
  const AutoLogExecutionResult({
    required this.subscriptionId,
    required this.subscriptionName,
    required this.amount,
    required this.originalBillingDate,
    required this.updatedNextBillingDate,
    required this.transaction,
    this.linkedAccount,
    this.previousBalance,
    this.newBalance,
    this.subscription,
    this.model,
  });

  final String subscriptionId;
  final String subscriptionName;
  final double amount;
  final DateTime originalBillingDate;
  final DateTime updatedNextBillingDate;
  final Transaction transaction;
  final Account? linkedAccount;
  final double? previousBalance;
  final double? newBalance;
  final Subscription? subscription;
  final SubscriptionModel? model;
}

/// Phase 37: Automatic Subscription Transaction Generation Engine.
///
/// When "Auto-Log on Renewal Date" is enabled for a subscription,
/// this engine automatically creates the [Transaction] on the billing date,
/// links it to the selected payment [Account], performs the Phase 6 atomic
/// ledger balance deduction, and advances [nextBillingDate] forward.
class SubscriptionAutoLogger {
  const SubscriptionAutoLogger({
    this.reconciler = const SubscriptionReconciler(),
    this.transactionService,
    this.isar,
  });

  final SubscriptionReconciler reconciler;
  final TransactionService? transactionService;
  final Isar? isar;

  /// Filters and executes automated renewal logging for all due [Subscription] entities.
  List<AutoLogExecutionResult> processDueSubscriptions({
    required List<Subscription> subscriptions,
    DateTime? now,
    Account? defaultAccount,
  }) {
    final DateTime currentTime = now ?? DateTime.now();
    final List<AutoLogExecutionResult> results = [];

    for (final sub in subscriptions) {
      if (!sub.isActive || !sub.autoLogOnRenewal) continue;

      // Check if billing date is due (today or in the past)
      if (sub.nextBillingDate.isBefore(currentTime) ||
          _isSameDay(sub.nextBillingDate, currentTime)) {
        final DateTime originalDate = sub.nextBillingDate;
        final Account? paymentAccount = sub.account.value ?? defaultAccount;

        double? prevBal;
        double? nextBal;

        // Perform Phase 6 balance deduction on linked payment account
        if (paymentAccount != null) {
          prevBal = paymentAccount.currentBalance;
          paymentAccount.currentBalance -= sub.amount;
          nextBal = paymentAccount.currentBalance;
        }

        // Reconcile subscription (advance next billing date and create Transaction)
        final ReconciliationResult recResult = reconciler.reconcileSubscription(
          subscription: sub,
          transactionDate: originalDate,
          customNote: 'Auto-Logged Renewal: ${sub.name}',
        );

        final Transaction tx = recResult.transaction;
        if (!tx.tags.contains('auto-logged')) {
          tx.tags.add('auto-logged');
        }

        if (paymentAccount != null) {
          tx.sourceAccount.value = paymentAccount;
        }

        results.add(
          AutoLogExecutionResult(
            subscriptionId: sub.id.toString(),
            subscriptionName: sub.name,
            amount: sub.amount,
            originalBillingDate: originalDate,
            updatedNextBillingDate: recResult.updatedNextBillingDate,
            transaction: tx,
            linkedAccount: paymentAccount,
            previousBalance: prevBal,
            newBalance: nextBal,
            subscription: sub,
          ),
        );
      }
    }

    return results;
  }

  /// Processes domain [SubscriptionModel] list with account lookup map.
  List<AutoLogExecutionResult> processDueModels({
    required List<SubscriptionModel> models,
    DateTime? now,
    Map<String, Account>? accountsMap,
    Account? defaultAccount,
  }) {
    final DateTime currentTime = now ?? DateTime.now();
    final List<AutoLogExecutionResult> results = [];

    for (final model in models) {
      if (!model.isActive || !model.autoLogOnRenewal) continue;

      if (model.nextBillingDate.isBefore(currentTime) ||
          _isSameDay(model.nextBillingDate, currentTime)) {
        final DateTime originalDate = model.nextBillingDate;
        final Account? paymentAccount = (model.accountId != null && accountsMap != null)
            ? accountsMap[model.accountId]
            : defaultAccount;

        double? prevBal;
        double? nextBal;

        if (paymentAccount != null) {
          prevBal = paymentAccount.currentBalance;
          paymentAccount.currentBalance -= model.amount;
          nextBal = paymentAccount.currentBalance;
        }

        final ReconciliationResult recResult = reconciler.reconcileModel(
          model: model,
          transactionDate: originalDate,
          customNote: 'Auto-Logged Renewal: ${model.name}',
        );

        final Transaction tx = recResult.transaction;
        if (!tx.tags.contains('auto-logged')) {
          tx.tags.add('auto-logged');
        }

        if (paymentAccount != null) {
          tx.sourceAccount.value = paymentAccount;
        }

        results.add(
          AutoLogExecutionResult(
            subscriptionId: model.id,
            subscriptionName: model.name,
            amount: model.amount,
            originalBillingDate: originalDate,
            updatedNextBillingDate: recResult.updatedNextBillingDate,
            transaction: tx,
            linkedAccount: paymentAccount,
            previousBalance: prevBal,
            newBalance: nextBal,
            model: model,
          ),
        );
      }
    }

    return results;
  }

  /// Executes database persistence in Isar when live database is provided.
  Future<List<AutoLogExecutionResult>> executeAndPersistDueSubscriptions({
    DateTime? now,
  }) async {
    if (isar == null) return [];

    final isarInstance = isar!;
    final subscriptions = await isarInstance.subscriptions.where().findAll();

    final results = processDueSubscriptions(
      subscriptions: subscriptions,
      now: now,
    );

    if (results.isEmpty) return [];

    await isarInstance.writeTxn(() async {
      for (final res in results) {
        if (res.subscription != null) {
          await isarInstance.subscriptions.put(res.subscription!);
          await res.subscription!.account.save();
          await res.subscription!.category.save();
        }

        if (res.linkedAccount != null) {
          await isarInstance.accounts.put(res.linkedAccount!);
        }

        await isarInstance.transactions.put(res.transaction);
        await res.transaction.sourceAccount.save();
        if (res.transaction.category.value != null) {
          await res.transaction.category.save();
        }
      }
    });

    return results;
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
