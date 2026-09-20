import 'package:isar/isar.dart';

part 'account.g.dart';

@collection
class Account {
  Id id = Isar.autoIncrement;
  late String name; // "HDFC Salary", "SBI Savings", "Cash Wallet"
  late double currentBalance;
  @Enumerated(EnumType.name)
  late AccountType type; // bank, cash, wallet, creditCard
  String? last4Digits;
  late int colorHex;
  bool isDefault = false;
}

enum AccountType { bank, cash, wallet, creditCard }
