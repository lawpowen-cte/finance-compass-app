import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/finance_repository.dart';
import '../../models/account.dart';
import '../repository_provider.dart';

/// Account CRUD operations.
///
/// Every method reads the current [FinanceRepository] from
/// [financeRepositoryProvider], calls the appropriate repository method, and
/// pushes the refreshed instance back so the UI re-renders.
class AccountMutations extends Notifier<void> {
  @override
  void build() {}

  FinanceRepositoryNotifier get _repoNotifier =>
      ref.read(financeRepositoryProvider.notifier);

  Future<FinanceRepository> get _repo =>
      ref.read(financeRepositoryProvider.future);

  /// Creates a new account.
  Future<void> addAccount(Account account) async {
    final updated = await (await _repo).addAccount(account);
    _repoNotifier.setRepository(updated);
  }

  /// Updates an existing account.
  Future<void> updateAccount(Account account) async {
    final updated = await (await _repo).updateExistingAccount(account);
    _repoNotifier.setRepository(updated);
  }

  /// Deletes an account only if it has no linked transactions or snapshots.
  ///
  /// Returns `true` if the account was deleted, `false` if it was kept
  /// because linked data exists.
  Future<bool> deleteAccount(String accountId) async {
    final updated = await (await _repo).deleteAccountIfSafe(accountId);
    if (updated != null) {
      _repoNotifier.setRepository(updated);
      return true;
    }
    return false;
  }

  /// Checks whether an account can be safely deleted.
  Future<bool> canDelete(String accountId) async {
    return (await _repo).canDeleteAccount(accountId);
  }

  /// Creates a new asset goal.
  Future<void> addAssetGoal({
    required String name,
    required double amount,
  }) async {
    final updated = await (await _repo).addAssetGoal(
      name: name,
      amount: amount,
    );
    _repoNotifier.setRepository(updated);
  }

  /// Updates an existing asset goal.
  Future<void> updateAssetGoal(AssetGoal goal) async {
    final updated = await (await _repo).updateAssetGoal(goal);
    _repoNotifier.setRepository(updated);
  }

  /// Deletes an asset goal by id.
  Future<void> deleteAssetGoal(String goalId) async {
    final updated = await (await _repo).deleteAssetGoal(goalId);
    _repoNotifier.setRepository(updated);
  }

  /// Sets the reconciled month for an account.
  Future<void> setAccountReconciledMonth(
    String accountId,
    String monthKey,
  ) async {
    final updated = await (await _repo).setAccountReconciledMonth(
      accountId,
      monthKey,
    );
    _repoNotifier.setRepository(updated);
  }

  /// Updates exchange rates and currency priority.
  Future<void> updateExchangeRates(
    Map<String, double> ratesToBase,
    List<String> currencyPriority,
  ) async {
    final updated = await (await _repo).updateExchangeRates(
      ratesToBase,
      currencyPriority,
    );
    _repoNotifier.setRepository(updated);
  }
}

/// Provider for account CRUD mutations.
final accountMutationsProvider =
    NotifierProvider<AccountMutations, void>(AccountMutations.new);
