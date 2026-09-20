import 'dart:math' as math;

/// Evaluation outcome containing statistical metrics for fraud/surge anomaly detection.
class AnomalyReport {
  const AnomalyReport({
    required this.isAnomaly,
    required this.amount,
    required this.mean,
    required this.standardDeviation,
    required this.threshold,
    required this.zScore,
    required this.sampleSize,
  });

  /// True if amount > (mean + 3 * standardDeviation).
  final bool isAnomaly;

  /// The evaluated transaction amount.
  final double amount;

  /// Running mean (μ) of historical transactions within the 30-day scope.
  final double mean;

  /// Running standard deviation (σ).
  final double standardDeviation;

  /// Threshold upper bound: (μ + 3σ).
  final double threshold;

  /// Statistical standard score (z-score): (amount - μ) / σ.
  final double zScore;

  /// Number of historical samples evaluated.
  final int sampleSize;

  @override
  String toString() {
    return 'AnomalyReport(isAnomaly: $isAnomaly, amount: $amount, mean: ${mean.toStringAsFixed(2)}, '
        'stdDev: ${standardDeviation.toStringAsFixed(2)}, threshold: ${threshold.toStringAsFixed(2)}, '
        'zScore: ${zScore.toStringAsFixed(2)}, samples: $sampleSize)';
  }
}

/// Anomaly & Fraud Surge Detection Engine using the 3-Sigma (μ + 3σ) statistical rule.
class AnomalyDetector {
  const AnomalyDetector({this.minimumSampleCount = 3});

  /// Minimum historical data points required before triggering 3-sigma anomaly flags.
  final int minimumSampleCount;

  /// Calculates the arithmetic mean (μ) of a list of numbers.
  static double calculateMean(List<double> values) {
    if (values.isEmpty) return 0.0;
    final double sum = values.fold(0.0, (prev, element) => prev + element);
    return sum / values.length;
  }

  /// Calculates the population standard deviation (σ) of a list of numbers.
  static double calculateStandardDeviation(
    List<double> values, [
    double? precomputedMean,
  ]) {
    if (values.length < 2) return 0.0;
    final double mean = precomputedMean ?? calculateMean(values);
    final double sumSquaredDiff = values.fold(
      0.0,
      (prev, element) => prev + math.pow(element - mean, 2),
    );
    return math.sqrt(sumSquaredDiff / values.length);
  }

  /// Evaluates an incoming transaction [amount] against the historical [amounts] (e.g., 30-day running window).
  /// Formula: Is Anomaly = Amount > (μ + 3σ)
  AnomalyReport evaluate({
    required double amount,
    required List<double> amounts,
    double sigmaMultiplier = 3.0,
  }) {
    if (amounts.isEmpty || amounts.length < minimumSampleCount) {
      return AnomalyReport(
        isAnomaly: false,
        amount: amount,
        mean: amounts.isEmpty ? amount : calculateMean(amounts),
        standardDeviation: 0.0,
        threshold: double.infinity,
        zScore: 0.0,
        sampleSize: amounts.length,
      );
    }

    final double mean = calculateMean(amounts);
    final double stdDev = calculateStandardDeviation(amounts, mean);
    final double threshold = mean + (sigmaMultiplier * stdDev);

    final double zScore = stdDev > 0 ? (amount - mean) / stdDev : 0.0;
    final bool isAnomaly = amount > threshold;

    return AnomalyReport(
      isAnomaly: isAnomaly,
      amount: amount,
      mean: mean,
      standardDeviation: stdDev,
      threshold: threshold,
      zScore: zScore,
      sampleSize: amounts.length,
    );
  }

  /// Returns true if the transaction amount exceeds (μ + 3σ).
  bool isAnomaly(
    double amount,
    List<double> amounts, {
    double sigmaMultiplier = 3.0,
  }) {
    return evaluate(
      amount: amount,
      amounts: amounts,
      sigmaMultiplier: sigmaMultiplier,
    ).isAnomaly;
  }
}
