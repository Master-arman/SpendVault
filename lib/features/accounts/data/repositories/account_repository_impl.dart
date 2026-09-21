import 'package:finance_app/features/accounts/domain/models/account_model.dart';
import 'package:finance_app/features/accounts/domain/repositories/account_repository.dart';
import 'package:finance_app/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:finance_app/features/transactions/domain/models/transaction_model.dart';
import 'package:finance_app/features/transactions/domain/repositories/transaction_repository.dart';

class AccountRepositoryImpl implements AccountRepository {
  static final List<AccountModel> _accounts = [
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

  final TransactionRepository _transactionRepository = TransactionRepositoryImpl();

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

  @override
  Future<void> transferFunds({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    DateTime? date,
    String? note,
  }) async {
    final int fromIndex = _accounts.indexWhere((AccountModel a) => a.id == fromAccountId);
    final int toIndex = _accounts.indexWhere((AccountModel a) => a.id == toAccountId);

    if (fromIndex == -1 || toIndex == -1) {
      throw ArgumentError('Invalid account IDs provided for fund transfer');
    }

    final AccountModel fromAccount = _accounts[fromIndex];
    final AccountModel toAccount = _accounts[toIndex];

    // Double-entry record: decrement source balance, increment destination balance
    _accounts[fromIndex] = fromAccount.copyWith(
      balance: fromAccount.balance - amount,
    );
    _accounts[toIndex] = toAccount.copyWith(
      balance: toAccount.balance + amount,
    );

    // Log the transfer entry into the ledger
    final DateTime transferDate = date ?? DateTime.now();
    final TransactionModel transferTxn = TransactionModel(
      id: 'txn-transfer-${DateTime.now().millisecondsSinceEpoch}',
      title: 'Transfer: ${fromAccount.name} → ${toAccount.name}',
      amount: amount,
      flow: TransactionFlow.transfer,
      category: 'Transfer',
      date: transferDate,
      accountId: fromAccount.id,
      accountName: fromAccount.name,
      merchant: toAccount.name,
      note: note ?? 'Inter-account transfer from ${fromAccount.name} to ${toAccount.name}',
      isAutomated: false,
    );

    await _transactionRepository.addTransaction(transferTxn);
  }
}
