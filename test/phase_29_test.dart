import 'package:finance_app/features/automation/domain/anomaly_detector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 29: Anomaly & Fraud Surge Detection Tests', () {
    const detector = AnomalyDetector();

    group('Mean & Standard Deviation Math', () {
      test('calculates correct arithmetic mean', () {
        expect(AnomalyDetector.calculateMean([100.0, 200.0, 300.0]), equals(200.0));
        expect(AnomalyDetector.calculateMean([50.0, 50.0, 50.0, 50.0]), equals(50.0));
        expect(AnomalyDetector.calculateMean([]), equals(0.0));
      });

      test('calculates correct standard deviation', () {
        expect(AnomalyDetector.calculateStandardDeviation([50.0, 50.0, 50.0]), equals(0.0));
        final double stdDev = AnomalyDetector.calculateStandardDeviation([10.0, 20.0, 30.0]);
        expect(stdDev, closeTo(8.165, 0.01));
      });
    });

    group('3-Sigma Rule (Amount > μ + 3σ) Anomaly Evaluation', () {
      // Historical 30-day coffee expenses: average 50.0, stdDev ~ 2.45
      final List<double> coffeeHistory = [
        50.0, 45.0, 55.0, 50.0, 48.0, 52.0, 50.0, 49.0, 51.0, 50.0,
      ];

      test('regular transaction within normal range is NOT an anomaly', () {
        final report = detector.evaluate(amount: 52.0, amounts: coffeeHistory);

        expect(report.isAnomaly, isFalse);
        expect(report.mean, equals(50.0));
        expect(report.amount, equals(52.0));
        expect(report.amount <= report.threshold, isTrue);
      });

      test('fraud surge spike transaction exceeding μ + 3σ IS an anomaly', () {
        // High surge transaction (e.g., ₹500 at a coffee shop where average is ₹50)
        final report = detector.evaluate(amount: 500.0, amounts: coffeeHistory);

        expect(report.isAnomaly, isTrue);
        expect(report.amount, equals(500.0));
        expect(report.amount > report.threshold, isTrue);
        expect(report.zScore, greaterThan(3.0));
        expect(detector.isAnomaly(500.0, coffeeHistory), isTrue);
      });

      test('grocery surge detection on larger datasets', () {
        // Normal grocery shopping history: ~1,200 with variance
        final List<double> groceryHistory = [
          1200.0, 1150.0, 1300.0, 1250.0, 1100.0, 1220.0, 1180.0, 1260.0,
        ];

        // ₹1,280 grocery bill (normal variation) -> not anomaly
        expect(detector.isAnomaly(1280.0, groceryHistory), isFalse);

        // ₹25,000 sudden charge (fraud spike) -> anomaly
        final report = detector.evaluate(amount: 25000.0, amounts: groceryHistory);
        expect(report.isAnomaly, isTrue);
        expect(report.zScore, greaterThan(3.0));
      });
    });

    group('Edge Cases & Cold-Start Behavior', () {
      test('handles insufficient sample size (< 3) gracefully without false positives', () {
        final report = detector.evaluate(amount: 1000.0, amounts: [50.0, 60.0]);
        expect(report.isAnomaly, isFalse);
        expect(report.sampleSize, equals(2));
      });

      test('handles empty historical list', () {
        final report = detector.evaluate(amount: 250.0, amounts: []);
        expect(report.isAnomaly, isFalse);
        expect(report.sampleSize, equals(0));
      });
    });
  });
}
