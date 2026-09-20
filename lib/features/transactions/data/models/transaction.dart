import 'package:isar/isar.dart';
import '../../../categories/data/models/category.dart';
import '../../../accounts/data/models/account.dart';

part 'transaction.g.dart';

@collection
class Transaction {
  Id id = Isar.autoIncrement;
  late double amount;
  @Enumerated(EnumType.name)
  late TransactionType type; // expense, income, transfer
  final sourceAccount = IsarLink<Account>();
  final destinationAccount = IsarLink<Account>();
  final category = IsarLink<Category>();
  late DateTime timestamp;
  String? note;
  String? receiptLocalPath;
  List<String> tags = [];
  @Index(unique: true, replace: false)
  String? deduplicationHash;
}

enum TransactionType { expense, income, transfer }
