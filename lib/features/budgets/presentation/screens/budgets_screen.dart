import 'package:finance_app/core/theme/app_colors.dart';
import 'package:finance_app/core/theme/theme_toggle_button.dart';
import 'package:finance_app/features/budgets/data/repositories/budget_repository.dart';
import 'package:finance_app/features/budgets/domain/models/budget_model.dart';
import 'package:finance_app/features/budgets/presentation/widgets/budget_card.dart';
import 'package:flutter/material.dart';

/// Screen listing all category envelope budgets with progress tracking.
class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key, this.repository});

  final BudgetRepository? repository;

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  late final BudgetRepository _repository;
  List<BudgetModel> _budgets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? InMemoryBudgetRepository();
    _loadBudgets();
  }

  Future<void> _loadBudgets() async {
    final list = await _repository.getBudgets();
    if (mounted) {
      setState(() {
        _budgets = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Category Budgets'),
        actions: const [
          ThemeToggleButton(),
          SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentIndigo))
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _budgets.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return BudgetCard(
                  budget: _budgets[index],
                );
              },
            ),
    );
  }
}
