import 'package:finance_app/features/categories/data/models/category.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';

class CategorySeeder {
  static List<Category> get presetCategories => [
        Category()
          ..name = 'Food & Chai'
          ..iconCodePoint = Icons.coffee_rounded.codePoint
          ..colorHex = 0xFFF59E0B,
        Category()
          ..name = 'Transportation'
          ..iconCodePoint = Icons.directions_bus_rounded.codePoint
          ..colorHex = 0xFF3B82F6,
        Category()
          ..name = 'Groceries'
          ..iconCodePoint = Icons.shopping_cart_rounded.codePoint
          ..colorHex = 0xFF10B981,
        Category()
          ..name = 'Entertainment'
          ..iconCodePoint = Icons.movie_creation_rounded.codePoint
          ..colorHex = 0xFFEC4899,
        Category()
          ..name = 'Salary'
          ..iconCodePoint = Icons.payments_rounded.codePoint
          ..colorHex = 0xFF14B8A6,
      ];

  /// On application launch, verify if isar.categorys.count() == 0.
  /// If empty, inserts the preset categories.
  static Future<void> seed(Isar isar) async {
    final int count = await isar.categorys.count();
    if (count == 0) {
      await isar.writeTxn(() async {
        await isar.categorys.putAll(presetCategories);
      });
    }
  }
}
