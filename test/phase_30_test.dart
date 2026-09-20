import 'package:finance_app/core/theme/app_theme.dart';
import 'package:finance_app/features/automation/domain/payment_app_filter.dart';
import 'package:finance_app/features/automation/presentation/screens/automation_settings_screen.dart';
import 'package:finance_app/features/automation/presentation/widgets/incoming_transaction_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 30 & Anomaly Warning Chip Tests', () {
    testWidgets('IncomingTransactionBanner renders Unusual Expense Detected warning chip when isAnomaly is true',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: IncomingTransactionBanner(
              amount: 25000,
              merchant: 'Apple Store',
              category: 'Shopping',
              isAnomaly: true,
              onConfirm: () {},
              onDismiss: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      // Verify Anomaly Alert header and visual warning chip
      expect(find.text('Anomaly Alert'), findsOneWidget);
      expect(find.text('Unusual Expense Detected'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(
        find.text('Detected ₹25000 spent at Apple Store. Category: Shopping.'),
        findsOneWidget,
      );
    });

    testWidgets('IncomingTransactionBanner does NOT render warning chip when isAnomaly is false',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: IncomingTransactionBanner(
              amount: 45,
              merchant: 'Chai Point',
              category: 'Food & Dining',
              isAnomaly: false,
              onConfirm: () {},
              onDismiss: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Instant Transaction Alert'), findsOneWidget);
      expect(find.text('Unusual Expense Detected'), findsNothing);
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
      expect(
        find.text('Detected ₹45 spent at Chai Point. Category: Food & Dining.'),
        findsOneWidget,
      );
    });

    testWidgets('AutomationSettingsScreen renders all sections, toggles and payment apps',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const AutomationSettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Check Header & Hero Shield
      expect(find.text('Automation & Privacy'), findsOneWidget);
      expect(find.text('Zero Cloud Ingestion'), findsOneWidget);

      // Check Master Controls
      expect(find.text('Notification Listener Service'), findsOneWidget);
      expect(find.text('Bank SMS Fallback Engine'), findsOneWidget);

      // Check Confirmation & Anomaly Rules
      expect(find.text('Auto-Confirm Mode'), findsOneWidget);
      expect(find.text('Anomaly & Fraud Surge Alert'), findsOneWidget);

      // Check Payment Apps Whitelist
      for (final appName in PaymentAppFilter.supportedAppNames) {
        expect(find.text(appName), findsOneWidget);
      }

      // Check Banks
      expect(find.text('HDFC Bank'), findsOneWidget);
      expect(find.text('State Bank of India'), findsOneWidget);
      expect(find.text('Axis Bank'), findsOneWidget);
      expect(find.text('ICICI Bank'), findsOneWidget);

      // Check Privacy & Audit log
      expect(find.text('Privacy Architecture & Consent'), findsOneWidget);
      expect(find.text('Historical Audit Records'), findsOneWidget);
      expect(find.text('Clear Historical Audit Logs'), findsOneWidget);
    });

    testWidgets('AutomationSettingsScreen granular switches toggle correctly',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const AutomationSettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Toggle Google Pay switch
      final gpaySwitchFinder = find.byKey(const Key('switch_app_com.google.android.apps.nbu.paisa.user'));
      expect(gpaySwitchFinder, findsOneWidget);
      
      final Switch gpaySwitchBefore = tester.widget(
        find.descendant(of: gpaySwitchFinder, matching: find.byType(Switch)),
      );
      expect(gpaySwitchBefore.value, isTrue);

      await tester.tap(gpaySwitchFinder);
      await tester.pumpAndSettle();

      final Switch gpaySwitchAfter = tester.widget(
        find.descendant(of: gpaySwitchFinder, matching: find.byType(Switch)),
      );
      expect(gpaySwitchAfter.value, isFalse);

      // Toggle HDFC Bank switch
      final hdfcSwitchFinder = find.byKey(const Key('switch_bank_HDFCBK'));
      expect(hdfcSwitchFinder, findsOneWidget);

      await tester.tap(hdfcSwitchFinder);
      await tester.pumpAndSettle();

      final Switch hdfcSwitchAfter = tester.widget(
        find.descendant(of: hdfcSwitchFinder, matching: find.byType(Switch)),
      );
      expect(hdfcSwitchAfter.value, isFalse);
    });

    testWidgets('AutomationSettingsScreen clear audit logs dialog pops and executes callback',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      bool clearLogsInvoked = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: AutomationSettingsScreen(
            onClearLogs: () async {
              clearLogsInvoked = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final clearButtonFinder = find.byKey(const Key('clear_audit_logs_button'));
      expect(clearButtonFinder, findsOneWidget);

      await tester.tap(clearButtonFinder);
      await tester.pumpAndSettle();

      // Dialog should appear
      expect(find.text('Clear Historical Logs?'), findsOneWidget);
      expect(find.text('Clear All Logs'), findsOneWidget);

      // Tap confirm button
      await tester.tap(find.text('Clear All Logs'));
      await tester.pumpAndSettle();

      expect(clearLogsInvoked, isTrue);
      expect(find.text('0 logs stored'), findsOneWidget);
      expect(find.text('Historical parser logs wiped successfully.'), findsOneWidget);
    });
  });
}
