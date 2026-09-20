import 'package:finance_app/features/accounts/domain/models/account_model.dart';
import 'package:finance_app/features/accounts/domain/repositories/account_repository.dart';

class AccountRepositoryImpl implements AccountRepository {
  final List<AccountModel> _accounts = [
    const AccountModel(
      id: 'acc-1',
      name: 'Primary Checking',
      institutionName: 'HDFC Bank',
      accountNumberMasked: '****4592',
      balance: 45250.75,
      type: AccountType.bank,
      isDefault: true,
    ),
    const AccountModel(
      id: 'acc-2',
      name: 'Platinum Rewards Card',
      institutionName: 'ICICI Bank',
      accountNumberMasked: '****8901',
      balance: -3320.40,
      type: AccountType.creditCard,
    ),
    const AccountModel(
      id: 'acc-3',
      name: 'High Yield Savings',
      institutionName: 'SBI Savings',
      accountNumberMasked: '****7124',
      balance: 185900.00,
      type: AccountType.bank,
    ),
  ];

  @override
  Future<List<AccountModel>> getAccounts() async {
    return List<AccountModel>.unmodifiable(_accounts);
  }

  @override
  Future<AccountModel?> getAccountById(String id) async {
    try {
      return _accounts.firstWhere((AccountModel acc) => acc.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> addAccount(AccountModel account) async {
    _accounts.add(account);
  }

  @override
  Future<void> updateAccount(AccountModel account) async {
    final int index = _accounts.indexWhere((AccountModel a) => a.id == account.id);
    if (index != -1) {
      _accounts[index] = account;
    }
  }

  @override
  Future<void> deleteAccount(String id) async {
    _accounts.removeWhere((AccountModel a) => a.id == id);
  }
}
