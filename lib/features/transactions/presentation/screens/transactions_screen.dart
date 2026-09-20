import 'package:finance_app/core/theme/app_colors.dart';
import 'package:finance_app/core/widgets/staggered_list_wrapper.dart';
import 'package:finance_app/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:finance_app/features/transactions/domain/models/transaction_model.dart';
import 'package:finance_app/features/transactions/domain/repositories/transaction_repository.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Transactions'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentIndigo))
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _transactions.length,
              separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 10),
              itemBuilder: (BuildContext context, int index) {
                return AnimationConfiguration.staggeredList(
                  position: index,
                  delay: const Duration(milliseconds: 40),
                  duration: const Duration(milliseconds: 320),
                  child: TransactionTile(transaction: _transactions[index]),
                );
              },
            ),
    );
  }
}
