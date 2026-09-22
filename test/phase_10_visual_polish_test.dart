import 'package:finance_app/core/theme/app_colors.dart';
import 'package:finance_app/core/theme/app_theme.dart';
import 'package:finance_app/features/transactions/domain/models/transaction_model.dart';
import 'package:finance_app/features/transactions/presentation/screens/dashboard_screen.dart';
import 'package:finance_app/features/transactions/presentation/screens/transactions_screen.dart';
import 'package:finance_app/features/transactions/presentation/widgets/transaction_tile.dart';
import 'package:finance_app/shared/widgets/app_card.dart';
import 'package:finance_app/shared/widgets/empty_state_view.dart';
import 'package:finance_app/shared/widgets/shimmer_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('Phase 10: Visual Polish & Theme Tests', () {
    test('Light theme configures soft background and pure white cards', () {
      final lightTheme = AppTheme.lightTheme;
      expect(lightTheme.scaffoldBackgroundColor, AppColors.lightBackground);
      expect(lightTheme.cardTheme.color, AppColors.lightCard);
      expect(lightTheme.splashFactory, equals(InkRipple.splashFactory));
    });

    test('Dark theme configures soft dark slate background with subtle borders', () {
      final darkTheme = AppTheme.darkTheme;
      expect(darkTheme.scaffoldBackgroundColor, AppColors.darkSlateBackground);
      expect(darkTheme.colorScheme.surface, AppColors.surfaceCard);
      expect(darkTheme.splashFactory, equals(InkRipple.splashFactory));
    });

    test('Typography hierarchy adheres to strict sizing', () {
      final darkTheme = AppTheme.darkTheme;
      // Display: 24sp / 28sp Bold
      expect(darkTheme.textTheme.displayMedium?.fontSize, 24);
      expect(darkTheme.textTheme.displayMedium?.fontWeight, FontWeight.w700);

      // Section Title: 16sp / 18sp Semi-Bold
      expect(darkTheme.textTheme.titleMedium?.fontSize, 16);
      expect(darkTheme.textTheme.titleMedium?.fontWeight, FontWeight.w600);

      // Body: 14sp Regular
      expect(darkTheme.textTheme.bodyMedium?.fontSize, 14);
      expect(darkTheme.textTheme.bodyMedium?.fontWeight, FontWeight.w400);

      // Caption: 12sp Muted
      expect(darkTheme.textTheme.bodySmall?.fontSize, 12);
      expect(darkTheme.textTheme.bodySmall?.fontWeight, FontWeight.w400);
    });
  });

  group('Phase 10: Shimmer & Skeleton Loaders', () {
    testWidgets('TransactionTileSkeleton renders placeholders cleanly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShimmerLoading(
              child: TransactionTileSkeleton(),
            ),
          ),
        ),
      );

      expect(find.byType(TransactionTileSkeleton), findsOneWidget);
      expect(find.byType(ShimmerBox), findsNWidgets(4));
    });

    testWidgets('TransactionListSkeleton renders list of skeleton cards', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TransactionListSkeleton(itemCount: 4),
          ),
        ),
      );

      expect(find.byType(TransactionTileSkeleton), findsNWidgets(4));
    });
  });

  group('Phase 10: Empty State View Widget Tests', () {
    testWidgets('EmptyStateView renders title, description, and triggers CTA callback', (tester) async {
      bool actionTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateView.transactions(
              onAddTransaction: () {
                actionTriggered = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('No Transactions Yet'), findsOneWidget);
      expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);
      expect(find.text('Add First Expense'), findsOneWidget);

      await tester.tap(find.text('Add First Expense'));
      await tester.pumpAndSettle();

      expect(actionTriggered, isTrue);
    });

    testWidgets('EmptyStateView.search renders query specific text and clear CTA', (tester) async {
      bool clearTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateView.search(
              query: 'Groceries',
              onClear: () {
                clearTriggered = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('No Results Found'), findsOneWidget);
      expect(find.textContaining('Groceries'), findsOneWidget);
      expect(find.text('Clear Search'), findsOneWidget);

      await tester.tap(find.text('Clear Search'));
      await tester.pumpAndSettle();

      expect(clearTriggered, isTrue);
    });
  });

  group('Phase 10: Card Tactile Feedback & InkRipple', () {
    testWidgets('AppCard handles tap with InkRipple splash effect', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: AppCard(
              onTap: () => tapped = true,
              child: const Text('Interactive Card'),
            ),
          ),
        ),
      );

      expect(find.text('Interactive Card'), findsOneWidget);
      expect(find.byType(InkWell), findsOneWidget);

      await tester.tap(find.text('Interactive Card'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('TransactionTile renders with InkRipple and triggers onTap', (tester) async {
      bool tapped = false;
      final sampleTxn = TransactionModel(
        id: 'tx-1',
        title: 'Blue Tokai Coffee',
        amount: 240.0,
        flow: TransactionFlow.expense,
        category: 'Food & Dining',
        date: DateTime(2026, 9, 22, 10, 30),
        accountId: 'acc-1',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: TransactionTile(
              transaction: sampleTxn,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Blue Tokai Coffee'), findsOneWidget);
      expect(find.text('-₹240.00'), findsOneWidget);

      await tester.tap(find.text('Blue Tokai Coffee'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });
}
