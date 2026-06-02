import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/finance_repository.dart';
import '../../models/budget.dart';
import '../repository_provider.dart';

/// Budget CRUD operations.
///
/// Wraps [FinanceRepository] budget methods and refreshes the global
/// repository state after every write.
class BudgetMutations extends Notifier<void> {
  @override
  void build() {}

  FinanceRepositoryNotifier get _repoNotifier =>
      ref.read(financeRepositoryProvider.notifier);

  Future<FinanceRepository> get _repo =>
      ref.read(financeRepositoryProvider.future);

  /// Creates or updates a budget (upsert by id, or by category+monthKey).
  Future<void> addBudget(Budget budget) async {
    final updated = await (await _repo).addBudget(budget);
    _repoNotifier.setRepository(updated);
  }

  /// Deletes a budget by its id.
  Future<void> deleteBudget(String budgetId) async {
    final updated = await (await _repo).deleteExistingBudget(budgetId);
    _repoNotifier.setRepository(updated);
  }
}

/// Provider for budget CRUD mutations.
final budgetMutationsProvider =
    NotifierProvider<BudgetMutations, void>(BudgetMutations.new);
