import 'package:flutter/material.dart';

/// Domain entity representing a transaction category.
class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.budgetLimit,
  });

  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final double? budgetLimit;
}
