import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/finance_repository.dart';
import '../../models/category.dart';
import '../repository_provider.dart';

/// Category CRUD operations.
///
/// Wraps [FinanceRepository] category methods and refreshes the global
/// repository state after every write.
class CategoryMutations extends Notifier<void> {
  @override
  void build() {}

  FinanceRepositoryNotifier get _repoNotifier =>
      ref.read(financeRepositoryProvider.notifier);

  Future<FinanceRepository> get _repo =>
      ref.read(financeRepositoryProvider.future);

  /// Creates a new category.
  Future<void> addCategory(Category category) async {
    final updated = await (await _repo).addCategory(category);
    _repoNotifier.setRepository(updated);
  }

  /// Updates an existing category.
  Future<void> updateCategory(Category category) async {
    final updated = await (await _repo).updateExistingCategory(category);
    _repoNotifier.setRepository(updated);
  }

  /// Deletes a category only if it has no linked transactions or budgets.
  ///
  /// Returns `true` if deleted, `false` if linked data exists.
  Future<bool> deleteCategory(String categoryId) async {
    final updated = await (await _repo).deleteCategoryIfSafe(categoryId);
    if (updated != null) {
      _repoNotifier.setRepository(updated);
      return true;
    }
    return false;
  }

  /// Checks whether a category can be safely deleted.
  Future<bool> canDelete(String categoryId) async {
    return (await _repo).canDeleteCategory(categoryId);
  }
}

/// Provider for category CRUD mutations.
final categoryMutationsProvider =
    NotifierProvider<CategoryMutations, void>(CategoryMutations.new);
