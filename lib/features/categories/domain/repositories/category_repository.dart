import 'package:finance_app/features/categories/domain/models/category_model.dart';

abstract class CategoryRepository {
  Future<List<CategoryModel>> getCategories();
  Future<CategoryModel?> getCategoryById(String id);
}
