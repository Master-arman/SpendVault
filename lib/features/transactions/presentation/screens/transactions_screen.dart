import 'package:finance_app/core/constants/app_constants.dart';
import 'package:finance_app/core/theme/app_colors.dart';
import 'package:finance_app/core/theme/theme_toggle_button.dart';
import 'package:finance_app/core/widgets/staggered_list_wrapper.dart';
import 'package:finance_app/features/reports/presentation/widgets/export_report_bottom_sheet.dart';
import 'package:finance_app/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:finance_app/features/transactions/domain/models/transaction_model.dart';
import 'package:finance_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:finance_app/features/transactions/presentation/widgets/transaction_detail_modal.dart';
import 'package:finance_app/features/transactions/presentation/widgets/transaction_tile.dart';
import 'package:flutter/material.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TransactionRepository _repository = TransactionRepositoryImpl();
  List<TransactionModel> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final List<TransactionModel> list = await _repository.getTransactions();
    if (mounted) {
      setState(() {
        _transactions = list;
        _isLoading = false;
      });
    }
  }

  void _openTransactionDetail(TransactionModel transaction) {
    TransactionDetailModal.show(
      context: context,
      transaction: transaction,
      onDelete: () async {
        await _repository.deleteTransaction(transaction.id);
        if (mounted) {
          setState(() {
            _transactions.removeWhere((t) => t.id == transaction.id);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deleted "${transaction.title}"'),
              backgroundColor: AppColors.expenseRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Transactions'),
        actions: [
          IconButton(
            key: const Key('button_export_transactions'),
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Export Statement & Data',
            onPressed: () {
              ExportReportBottomSheet.show(
                context: context,
                transactions: _transactions,
              );
            },
          ),
          IconButton(
            key: const Key('open_search_button'),
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Search Transactions',
            onPressed: () {
              Navigator.of(context).pushNamed(AppConstants.searchRoute);
            },
          ),
          const ThemeToggleButton(),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentIndigo))
          : ListView.builder(
              itemExtent: 82.0,
              padding: const EdgeInsets.all(20),
              itemCount: _transactions.length,
              itemBuilder: (BuildContext context, int index) {
                final txn = _transactions[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AnimationConfiguration.staggeredList(
                    position: index,
                    delay: const Duration(milliseconds: 40),
                    duration: const Duration(milliseconds: 320),
                    child: TransactionTile(
                      transaction: txn,
                      onTap: () => _openTransactionDetail(txn),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
