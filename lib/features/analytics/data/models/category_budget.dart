import 'package:finance_app/features/categories/data/models/category.dart';
import 'package:isar/isar.dart';

part 'category_budget.g.dart';

@collection
class CategoryBudget {
  Id id = Isar.autoIncrement;
  final category = IsarLink<Category>();
  late double monthlyLimit;
  late int month;
  late int year;
}
