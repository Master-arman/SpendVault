import 'package:isar/isar.dart';

part 'category.g.dart';

@collection
class Category {
  Id id = Isar.autoIncrement;
  late String name;
  int iconCodePoint = 0;
  int colorHex = 0xFF6366F1;
  double? budgetLimit;
}
