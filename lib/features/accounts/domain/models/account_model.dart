enum AccountType {
  bank,
  creditCard,
  wallet,
  investment,
}

/// Domain entity representing a user's financial account.
class AccountModel {
  const AccountModel({
    required this.id,
    required this.name,
    required this.institutionName,
    required this.accountNumberMasked,
    required this.balance,
    required this.type,
    this.currency = 'USD',
    this.isDefault = false,
  });

  final String id;
  final String name;
  final String institutionName;
  final String accountNumberMasked;
  final double balance;
  final AccountType type;
  final String currency;
  final bool isDefault;

  AccountModel copyWith({
    String? id,
    String? name,
    String? institutionName,
    String? accountNumberMasked,
    double? balance,
    AccountType? type,
    String? currency,
    bool? isDefault,
  }) {
    return AccountModel(
      id: id ?? this.id,
      name: name ?? this.name,
      institutionName: institutionName ?? this.institutionName,
      accountNumberMasked: accountNumberMasked ?? this.accountNumberMasked,
      balance: balance ?? this.balance,
      type: type ?? this.type,
      currency: currency ?? this.currency,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
