import 'package:finance_app/features/accounts/domain/models/account_model.dart';

abstract class AccountRepository {
  Future<List<AccountModel>> getAccounts();
  Future<AccountModel?> getAccountById(String id);
  Future<void> addAccount(AccountModel account);
  Future<void> updateAccount(AccountModel account);
  Future<void> deleteAccount(String id);
  Future<void> transferFunds({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    DateTime? date,
    String? note,
  });
}
