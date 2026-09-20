import 'package:finance_app/features/categories/data/category_seeder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 7: Dynamic Category Engine & Boot Seeder Tests', () {
    test('Preset categories list contains all 5 required presets with correct icons and hex colors', () {
      final presets = CategorySeeder.presetCategories;

      expect(presets.length, 5);

      final food = presets.firstWhere((c) => c.name == 'Food & Chai');
      expect(food.iconCodePoint, Icons.coffee_rounded.codePoint);
      expect(food.colorHex, 0xFFF59E0B);

      final transport = presets.firstWhere((c) => c.name == 'Transportation');
      expect(transport.iconCodePoint, Icons.directions_bus_rounded.codePoint);
      expect(transport.colorHex, 0xFF3B82F6);

      final groceries = presets.firstWhere((c) => c.name == 'Groceries');
      expect(groceries.iconCodePoint, Icons.shopping_cart_rounded.codePoint);
      expect(groceries.colorHex, 0xFF10B981);

      final entertainment = presets.firstWhere((c) => c.name == 'Entertainment');
      expect(entertainment.iconCodePoint, Icons.movie_creation_rounded.codePoint);
      expect(entertainment.colorHex, 0xFFEC4899);

      final salary = presets.firstWhere((c) => c.name == 'Salary');
      expect(salary.iconCodePoint, Icons.payments_rounded.codePoint);
      expect(salary.colorHex, 0xFF14B8A6);
    });
  });
}
