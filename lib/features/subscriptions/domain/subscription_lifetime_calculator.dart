import 'package:finance_app/features/transactions/data/models/transaction.dart';
import 'package:finance_app/features/transactions/domain/models/transaction_model.dart';
import 'package:fl_chart/fl_chart.dart';

/// Single historical price point recorded for a subscription.
class SubscriptionPricePoint {
  const SubscriptionPricePoint({
    required this.date,
    required this.amount,
    this.isHike = false,
    this.previousAmount,
  });

  final DateTime date;
  final double amount;
  final bool isHike;
  final double? previousAmount;

  double? get priceDifference =>
      previousAmount != null ? amount - previousAmount! : null;

  double? get percentageIncrease => previousAmount != null && previousAmount! > 0
      ? ((amount - previousAmount!) / previousAmount!) * 100
      : null;
}

/// Aggregated result container for a subscription's lifetime spend and price history.
class SubscriptionLifetimeAnalytics {
  const SubscriptionLifetimeAnalytics({
    required this.subscriptionId,
    required this.totalInvested,
    required this.transactionsCount,
    required this.pricePoints,
    required this.priceHikesCount,
    required this.initialPrice,
    required this.latestPrice,
    required this.lifetimeHikePercentage,
    required this.matchingTransactions,
  });

  final String subscriptionId;
  final double totalInvested;
  final int transactionsCount;
  final List<SubscriptionPricePoint> pricePoints;
  final int priceHikesCount;
  final double initialPrice;
  final double latestPrice;
  final double lifetimeHikePercentage;
  final List<dynamic> matchingTransactions;

  bool get hasPriceHikes => priceHikesCount > 0;
}

/// Phase 38: Historical Value & Lifetime Spend Engine.
///
/// Calculates total historical investment for a given subscription:
/// "Total Invested" = ∑ Historical Transactions (where tags contains #subscription_${sub.id})
/// and tracks all price hikes across the service's lifetime.
class SubscriptionLifetimeCalculator {
  const SubscriptionLifetimeCalculator();

  /// Calculates lifetime analytics from a list of Isar [Transaction] records.
  static SubscriptionLifetimeAnalytics calculateFromTransactions({
    required String subscriptionId,
    required List<Transaction> allTransactions,
  }) {
    final String targetTag = '#subscription_$subscriptionId';
    final String altTag = 'subscription_$subscriptionId';

    final List<Transaction> matched = allTransactions.where((tx) {
      return tx.tags.contains(targetTag) || tx.tags.contains(altTag);
    }).toList();

    // Sort chronologically (oldest to newest)
    matched.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    double totalInvested = 0.0;
    final List<SubscriptionPricePoint> pricePoints = [];
    int priceHikesCount = 0;
    double? lastPrice;

    for (final tx in matched) {
      totalInvested += tx.amount;

      final bool isHike = lastPrice != null && tx.amount > lastPrice;
      if (isHike) {
        priceHikesCount++;
      }

      pricePoints.add(
        SubscriptionPricePoint(
          date: tx.timestamp,
          amount: tx.amount,
          isHike: isHike,
          previousAmount: lastPrice,
        ),
      );

      lastPrice = tx.amount;
    }

    final double initialPrice =
        pricePoints.isNotEmpty ? pricePoints.first.amount : 0.0;
    final double latestPrice =
        pricePoints.isNotEmpty ? pricePoints.last.amount : 0.0;
    final double lifetimeHikePercentage =
        initialPrice > 0 ? ((latestPrice - initialPrice) / initialPrice) * 100 : 0.0;

    return SubscriptionLifetimeAnalytics(
      subscriptionId: subscriptionId,
      totalInvested: totalInvested,
      transactionsCount: matched.length,
      pricePoints: pricePoints,
      priceHikesCount: priceHikesCount,
      initialPrice: initialPrice,
      latestPrice: latestPrice,
      lifetimeHikePercentage: lifetimeHikePercentage,
      matchingTransactions: matched,
    );
  }

  /// Calculates lifetime analytics from domain [TransactionModel] records.
  static SubscriptionLifetimeAnalytics calculateFromModels({
    required String subscriptionId,
    required List<TransactionModel> allTransactions,
    List<String> Function(TransactionModel model)? tagsExtractor,
  }) {
    final String targetTag = '#subscription_$subscriptionId';
    final String altTag = 'subscription_$subscriptionId';

    final List<TransactionModel> matched = allTransactions.where((tx) {
      if (tagsExtractor != null) {
        final tags = tagsExtractor(tx);
        return tags.contains(targetTag) || tags.contains(altTag);
      }
      final String note = tx.note?.toLowerCase() ?? '';
      return note.contains(targetTag) ||
          note.contains(altTag) ||
          tx.title.toLowerCase().contains(subscriptionId.toLowerCase());
    }).toList();

    matched.sort((a, b) => a.date.compareTo(b.date));

    double totalInvested = 0.0;
    final List<SubscriptionPricePoint> pricePoints = [];
    int priceHikesCount = 0;
    double? lastPrice;

    for (final tx in matched) {
      totalInvested += tx.amount;

      final bool isHike = lastPrice != null && tx.amount > lastPrice;
      if (isHike) {
        priceHikesCount++;
      }

      pricePoints.add(
        SubscriptionPricePoint(
          date: tx.date,
          amount: tx.amount,
          isHike: isHike,
          previousAmount: lastPrice,
        ),
      );

      lastPrice = tx.amount;
    }

    final double initialPrice =
        pricePoints.isNotEmpty ? pricePoints.first.amount : 0.0;
    final double latestPrice =
        pricePoints.isNotEmpty ? pricePoints.last.amount : 0.0;
    final double lifetimeHikePercentage =
        initialPrice > 0 ? ((latestPrice - initialPrice) / initialPrice) * 100 : 0.0;

    return SubscriptionLifetimeAnalytics(
      subscriptionId: subscriptionId,
      totalInvested: totalInvested,
      transactionsCount: matched.length,
      pricePoints: pricePoints,
      priceHikesCount: priceHikesCount,
      initialPrice: initialPrice,
      latestPrice: latestPrice,
      lifetimeHikePercentage: lifetimeHikePercentage,
      matchingTransactions: matched,
    );
  }

  /// Generates chart spots for [LineChart] from recorded price points.
  static List<FlSpot> generateChartSpots(List<SubscriptionPricePoint> points) {
    if (points.isEmpty) return [];

    return List.generate(points.length, (int index) {
      return FlSpot(index.toDouble(), points[index].amount);
    });
  }
}
