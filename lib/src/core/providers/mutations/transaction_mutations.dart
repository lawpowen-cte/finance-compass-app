import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/finance_repository.dart';
import '../../models/transaction.dart';
import '../repository_provider.dart';

/// Transaction CRUD operations.
///
/// All methods read the current [FinanceRepository], mutate via the
/// repository, and push the refreshed instance back into
/// [financeRepositoryProvider] so consumers rebuild.
class TransactionMutations extends Notifier<void> {
  @override
  void build() {}

  FinanceRepositoryNotifier get _repoNotifier =>
      ref.read(financeRepositoryProvider.notifier);

  Future<FinanceRepository> get _repo =>
      ref.read(financeRepositoryProvider.future);

  /// Creates a single transaction.
  Future<void> addTransaction(FinanceTransaction transaction) async {
    final updated = await (await _repo).addTransaction(transaction);
    _repoNotifier.setRepository(updated);
  }

  /// Creates multiple transactions in a single batch.
  Future<void> addTransactions(List<FinanceTransaction> transactions) async {
    final updated = await (await _repo).addTransactions(transactions);
    _repoNotifier.setRepository(updated);
  }

  /// Updates an existing transaction (reverses old balance effects, applies new).
  Future<void> updateTransaction(FinanceTransaction transaction) async {
    final updated = await (await _repo).updateExistingTransaction(transaction);
    _repoNotifier.setRepository(updated);
  }

  /// Deletes a transaction and reverses its balance effects.
  Future<void> deleteTransaction(String transactionId) async {
    final updated = await (await _repo).deleteExistingTransaction(transactionId);
    _repoNotifier.setRepository(updated);
  }

  /// Saves a transaction as a reusable template.
  Future<void> addTransactionTemplate({
    required String name,
    required FinanceTransaction transaction,
  }) async {
    final updated = await (await _repo).addTransactionTemplate(
      name: name,
      transaction: transaction,
    );
    _repoNotifier.setRepository(updated);
  }

  /// Deletes a transaction template by id.
  Future<void> deleteTransactionTemplate(String templateId) async {
    final updated = await (await _repo).deleteTransactionTemplate(templateId);
    _repoNotifier.setRepository(updated);
  }

  /// Creates a recurring transaction rule.
  Future<void> addRecurringTransactionRule({
    required String name,
    required FinanceTransaction transaction,
    required int intervalMonths,
  }) async {
    final updated = await (await _repo).addRecurringTransactionRule(
      name: name,
      transaction: transaction,
      intervalMonths: intervalMonths,
    );
    _repoNotifier.setRepository(updated);
  }

  /// Deletes a recurring transaction rule.
  Future<void> deleteRecurringTransactionRule(String ruleId) async {
    final updated = await (await _repo).deleteRecurringTransactionRule(ruleId);
    _repoNotifier.setRepository(updated);
  }

  /// Generates future transactions from a recurring rule.
  Future<void> generateRecurringTransactions(
    String ruleId, {
    required int monthsAhead,
  }) async {
    final updated = await (await _repo)
        .generateRecurringTransactions(ruleId, monthsAhead: monthsAhead);
    _repoNotifier.setRepository(updated);
  }
}

/// Provider for transaction CRUD mutations.
final transactionMutationsProvider =
    NotifierProvider<TransactionMutations, void>(TransactionMutations.new);
