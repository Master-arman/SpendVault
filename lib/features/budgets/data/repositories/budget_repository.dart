import 'package:finance_app/features/budgets/domain/models/budget_model.dart';

abstract class BudgetRepository {
  Future<List<BudgetModel>> getBudgets();
  Future<void> saveBudget(BudgetModel budget);
  Future<void> deleteBudget(String id);
}

class InMemoryBudgetRepository implements BudgetRepository {
  final List<BudgetModel> _budgets = [];

  @override
  Future<List<BudgetModel>> getBudgets() async {
    return List.unmodifiable(_budgets);
  }

  @override
  Future<void> saveBudget(BudgetModel budget) async {
    final index = _budgets.indexWhere((b) => b.id == budget.id);
    if (index >= 0) {
      _budgets[index] = budget;
    } else {
      _budgets.add(budget);
    }
  }

  @override
  Future<void> deleteBudget(String id) async {
    _budgets.removeWhere((b) => b.id == id);
  }
}
