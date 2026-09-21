import 'package:finance_app/core/theme/app_theme.dart';
import 'package:finance_app/features/categories/domain/models/category_model.dart';
import 'package:finance_app/features/categories/presentation/screens/categories_screen.dart';
import 'package:finance_app/features/categories/presentation/screens/category_detail_screen.dart';
import 'package:finance_app/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 3: Budget & Category Drill-Down Navigation Tests', () {
    testWidgets('Tapping category tile pushes CategoryDetailScreen with budget limit progress',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const CategoriesScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Find Food & Dining category
      final foodTile = find.text('Food & Dining');
      expect(foodTile, findsOneWidget);

      // Tap category
      await tester.tap(foodTile);
      await tester.pumpAndSettle();

      // Verify CategoryDetailScreen is pushed
      expect(find.byType(CategoryDetailScreen), findsOneWidget);
      expect(find.text('Transactions'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('CategoryDetailScreen renders category budget metrics and filtered items',
        (WidgetTester tester) async {
      const category = CategoryModel(
        id: 'food',
        name: 'Food & Dining',
        icon: Icons.restaurant_rounded,
        color: Color(0xFF10B981),
        budgetLimit: 8000.0,
      );

      final repo = TransactionRepositoryImpl();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: CategoryDetailScreen(
            category: category,
            transactionRepository: repo,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Food & Dining'), findsWidgets);
      expect(find.text('Limit: ₹8,000.00'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('Nature\'s Basket Supermarket'), findsOneWidget);
    });
  });
}
