import 'package:finance_app/core/widgets/rolling_counter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RollingCounter Tests', () {
    testWidgets('Renders initial balance with Indian currency formatting', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RollingCounter(
              value: 12400.00,
            ),
          ),
        ),
      );

      // Verify initial Indian currency format
      expect(find.text('₹12,400.00'), findsOneWidget);
    });

    testWidgets('Smoothly transitions from ₹12,400.00 to ₹18,950.00 over 1000ms',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RollingCounter(
              value: 12400.00,
            ),
          ),
        ),
      );

      expect(find.text('₹12,400.00'), findsOneWidget);

      // Update to new target value
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RollingCounter(
              value: 18950.00,
            ),
          ),
        ),
      );

      // Advance by 300ms (intermediate frame during easeOutExpo)
      await tester.pump(const Duration(milliseconds: 300));
      // Text should not be either old or final value yet
      expect(find.text('₹12,400.00'), findsNothing);
      expect(find.text('₹18,950.00'), findsNothing);

      // Advance remaining time to complete 1000ms
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      // Final value reached
      expect(find.text('₹18,950.00'), findsOneWidget);
    });

    testWidgets('Supports custom builder and styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RollingCounter(
              value: 50000.00,
              builder: (context, value, formatted) {
                return Text('Balance: $formatted', key: const Key('custom_text'));
              },
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('custom_text')), findsOneWidget);
      expect(find.text('Balance: ₹50,000.00'), findsOneWidget);
    });
  });
}
