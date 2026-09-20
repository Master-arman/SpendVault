import 'package:finance_app/core/theme/app_colors.dart';
import 'package:finance_app/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:finance_app/features/accounts/domain/models/account_model.dart';
import 'package:finance_app/features/accounts/domain/repositories/account_repository.dart';
import 'package:finance_app/features/accounts/presentation/widgets/account_card.dart';
import 'package:flutter/material.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final AccountRepository _repository = AccountRepositoryImpl();
  List<AccountModel> _accounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final List<AccountModel> list = await _repository.getAccounts();
    if (mounted) {
      setState(() {
        _accounts = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Linked Accounts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.indigoLight),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentIndigo))
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _accounts.length,
              separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 16),
              itemBuilder: (BuildContext context, int index) {
                return AccountCard(account: _accounts[index]);
              },
            ),
    );
  }
}
