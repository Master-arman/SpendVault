import 'package:finance_app/features/categories/domain/models/category_model.dart';
import 'package:finance_app/features/categories/domain/repositories/category_repository.dart';
import 'package:flutter/material.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final List<CategoryModel> _categories = const [
    CategoryModel(
      id: 'cat-food',
      name: 'Food & Dining',
      icon: Icons.restaurant_rounded,
      color: Color(0xFFF59E0B),
      budgetLimit: 600,
    ),
    CategoryModel(
      id: 'cat-shopping',
      name: 'Shopping',
      icon: Icons.shopping_bag_rounded,
      color: Color(0xFF6366F1),
      budgetLimit: 400,
    ),
    CategoryModel(
      id: 'cat-bills',
      name: 'Bills & Utilities',
      icon: Icons.receipt_long_rounded,
      color: Color(0xFFEF4444),
      budgetLimit: 500,
    ),
    CategoryModel(
      id: 'cat-transport',
      name: 'Transport',
      icon: Icons.directions_car_rounded,
      color: Color(0xFF10B981),
      budgetLimit: 250,
    ),
    CategoryModel(
      id: 'cat-entertainment',
      name: 'Entertainment',
      icon: Icons.movie_rounded,
      color: Color(0xFF8B5CF6),
      budgetLimit: 200,
    ),
  ];

  @override
  Future<List<CategoryModel>> getCategories() async {
    return _categories;
  }

  @override
  Future<CategoryModel?> getCategoryById(String id) async {
    try {
      return _categories.firstWhere((CategoryModel cat) => cat.id == id);
    } catch (_) {
      return null;
    }
  }
}
