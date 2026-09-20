import 'package:finance_app/core/theme/app_colors.dart';
import 'package:finance_app/core/theme/theme_toggle_button.dart';
import 'package:finance_app/features/accounts/data/models/account.dart' as isar_model;
import 'package:finance_app/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:finance_app/features/accounts/domain/models/account_model.dart' as domain_model;
import 'package:finance_app/features/accounts/domain/repositories/account_repository.dart';
import 'package:finance_app/features/accounts/presentation/widgets/account_card.dart';
import 'package:finance_app/features/accounts/presentation/widgets/account_carousel_3d.dart';
import 'package:flutter/material.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final AccountRepository _repository = AccountRepositoryImpl();
  List<domain_model.AccountModel> _accounts = [];
  List<isar_model.Account> _carouselAccounts = [];
  bool _isLoading = true;
  isar_model.Account? _selectedAccount;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final List<domain_model.AccountModel> list = await _repository.getAccounts();
    final List<isar_model.Account> carouselList = list.map((a) {
      final acc = isar_model.Account()
        ..name = a.name
        ..currentBalance = a.balance
        ..type = a.type == domain_model.AccountType.creditCard
            ? isar_model.AccountType.creditCard
            : (a.type == domain_model.AccountType.wallet
                ? isar_model.AccountType.wallet
                : isar_model.AccountType.bank)
        ..last4Digits = a.accountNumberMasked.replaceAll('*', '')
        ..colorHex = a.type == domain_model.AccountType.creditCard
            ? 0xFFEC4899
            : (a.isDefault ? 0xFF14B8A6 : 0xFF0D9488)
        ..isDefault = a.isDefault;
      return acc;
    }).toList();

    if (mounted) {
      setState(() {
        _accounts = list;
        _carouselAccounts = carouselList;
        _selectedAccount = carouselList.isNotEmpty ? carouselList.first : null;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Multi-Account Ledger',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          const ThemeToggleButton(),
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.indigoLight),
            tooltip: 'Add Account',
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentIndigo))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_carouselAccounts.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Active Cards & Wallets',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              letterSpacing: 0.2,
                            ),
                          ),
                          Text(
                            '${_carouselAccounts.length} Connected',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    AccountCarousel3D(
                      accounts: _carouselAccounts,
                      onAccountSelected: (acc) {
                        setState(() {
                          _selectedAccount = acc;
                        });
                      },
                    ),
                    if (_selectedAccount != null) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCard,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Color(_selectedAccount!.colorHex).withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.credit_card_rounded,
                                size: 16,
                                color: Color(_selectedAccount!.colorHex),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Selected: ${_selectedAccount!.name}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'All Accounts',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _accounts.length,
                          separatorBuilder: (BuildContext context, int index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (BuildContext context, int index) {
                            return AccountCard(account: _accounts[index]);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

