import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/account.dart' as model;
import '../models/asset_snapshot.dart' as model;
import '../models/budget.dart' as model;
import '../models/category.dart' as model;
import '../models/transaction.dart' as model;
import 'enum_codec.dart';
import 'tables/accounts_table.dart';
import 'tables/asset_snapshots_table.dart';
import 'tables/app_meta_table.dart';
import 'tables/budgets_table.dart';
import 'tables/categories_table.dart';
import 'tables/transactions_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Accounts,
    Categories,
    Budgets,
    Transactions,
    AssetSnapshots,
    AppMeta,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(appMeta);
          }
          if (from < 3) {
            await m.addColumn(transactions, transactions.recordDate);
          }
          if (from < 4) {
            await m.addColumn(transactions, transactions.status);
            await m.addColumn(transactions, transactions.recurringRuleId);
          }
          if (from < 5) {
            await m.addColumn(transactions, transactions.toAmount);
            await m.addColumn(transactions, transactions.toCurrency);
          }
          if (from < 6) {
            await m.addColumn(budgets, budgets.currency);
          }
        },
      );

  Future<List<model.Account>> fetchAccounts() async {
    final rows = await select(accounts).get();
    return rows
        .map(
          (row) => model.Account(
            id: row.id,
            name: row.name,
            accountType: enumByName(model.AccountType.values, row.accountType),
            reportGroup: enumByName(model.ReportGroup.values, row.reportGroup),
            currency: row.currency,
            initialBalance: row.initialBalance,
            currentBalance: row.currentBalance,
            institution: row.institution,
            note: row.note,
            isActive: row.isActive,
          ),
        )
        .toList();
  }

  Future<List<model.Category>> fetchCategories() async {
    final rows = await select(categories).get();
    return rows
        .map(
          (row) => model.Category(
            id: row.id,
            name: row.name,
            type: enumByName(model.CategoryType.values, row.type),
            parentId: row.parentId,
          ),
        )
        .toList();
  }

  Future<List<model.Budget>> fetchBudgets() async {
    final rows = await select(budgets).get();
    return rows
        .map(
          (row) => model.Budget(
            id: row.id,
            categoryId: row.categoryId,
            monthKey: row.monthKey,
            amount: row.amount,
            currency: row.currency,
            alertThreshold: row.alertThreshold,
            rolloverEnabled: row.rolloverEnabled,
          ),
        )
        .toList();
  }

  Future<List<model.FinanceTransaction>> fetchTransactions() async {
    final rows = await select(transactions).get();
    return rows
        .map(
          (row) => model.FinanceTransaction(
            id: row.id,
            type: enumByName(model.TransactionType.values, row.type),
            accountId: row.accountId,
            toAccountId: row.toAccountId,
            categoryId: row.categoryId,
            amount: row.amount,
            currency: row.currency,
            toAmount: row.toAmount,
            toCurrency: row.toCurrency,
            recordDate: row.recordDate ?? row.transactionDate,
            transactionDate: row.transactionDate,
            status: row.status == null
                ? model.TransactionStatus.actual
                : enumByName(model.TransactionStatus.values, row.status!),
            recurringRuleId: row.recurringRuleId,
            description: row.description,
            merchant: row.merchant,
          ),
        )
        .toList();
  }

  Future<List<model.AssetSnapshot>> fetchAssetSnapshots() async {
    final rows = await select(assetSnapshots).get();
    return rows
        .map(
          (row) => model.AssetSnapshot(
            id: row.id,
            accountId: row.accountId,
            snapshotDate: row.snapshotDate,
            marketValue: row.marketValue,
            costBasis: row.costBasis,
            cashBalance: row.cashBalance,
            unrealizedPnl: row.unrealizedPnl,
          ),
        )
        .toList();
  }

  Future<int> accountCount() async {
    final query = selectOnly(accounts)..addColumns([accounts.id.count()]);
    final row = await query.getSingle();
    return row.read(accounts.id.count()) ?? 0;
  }

  Future<bool> hasCompletedSeed() async {
    final row = await (select(appMeta)
          ..where((tbl) => tbl.key.equals('seed_completed')))
        .getSingleOrNull();
    return row?.value == 'true';
  }

  Future<void> markSeedCompleted() {
    return into(appMeta).insertOnConflictUpdate(
      const AppMetaCompanion(
        key: Value('seed_completed'),
        value: Value('true'),
      ),
    );
  }

  Future<String?> getMetaValue(String keyValue) async {
    final row = await (select(appMeta)
          ..where((tbl) => tbl.key.equals(keyValue)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<Map<String, String>> fetchAllMetaValues() async {
    final rows = await select(appMeta).get();
    return {
      for (final row in rows) row.key: row.value,
    };
  }

  Future<void> setMetaValue(String keyValue, String valueText) {
    return into(appMeta).insertOnConflictUpdate(
      AppMetaCompanion(
        key: Value(keyValue),
        value: Value(valueText),
      ),
    );
  }

  Future<void> deleteMetaValue(String keyValue) {
    return (delete(appMeta)..where((tbl) => tbl.key.equals(keyValue))).go();
  }

  Future<void> seedAll({
    required List<model.Account> accountItems,
    required List<model.Category> categoryItems,
    required List<model.Budget> budgetItems,
    required List<model.FinanceTransaction> transactionItems,
    required List<model.AssetSnapshot> snapshotItems,
  }) async {
    await batch((batch) {
      batch.insertAll(
        accounts,
        accountItems
            .map(
              (item) => AccountsCompanion.insert(
                id: item.id,
                name: item.name,
                accountType: item.accountType.name,
                reportGroup: item.reportGroup.name,
                currency: item.currency,
                currentBalance: item.currentBalance,
                initialBalance: Value(item.initialBalance),
                institution: Value(item.institution),
                note: Value(item.note),
                isActive: Value(item.isActive),
              ),
            )
            .toList(),
      );
      batch.insertAll(
        categories,
        categoryItems
            .map(
              (item) => CategoriesCompanion.insert(
                id: item.id,
                name: item.name,
                type: item.type.name,
                parentId: Value(item.parentId),
              ),
            )
            .toList(),
      );
      batch.insertAll(
        budgets,
        budgetItems
            .map(
              (item) => BudgetsCompanion.insert(
                id: item.id,
                categoryId: item.categoryId,
                monthKey: item.monthKey,
                amount: item.amount,
                currency: Value(item.currency),
                alertThreshold: Value(item.alertThreshold),
                rolloverEnabled: Value(item.rolloverEnabled),
              ),
            )
            .toList(),
      );
      batch.insertAll(
        transactions,
        transactionItems
            .map(
              (item) => TransactionsCompanion.insert(
                id: item.id,
                type: item.type.name,
                accountId: item.accountId,
                amount: item.amount,
                currency: item.currency,
                toAmount: Value(item.toAmount),
                toCurrency: Value(item.toCurrency),
                recordDate: Value(item.recordDate),
                transactionDate: item.transactionDate,
                status: Value(item.status.name),
                recurringRuleId: Value(item.recurringRuleId),
                toAccountId: Value(item.toAccountId),
                categoryId: Value(item.categoryId),
                description: Value(item.description),
                merchant: Value(item.merchant),
              ),
            )
            .toList(),
      );
      batch.insertAll(
        assetSnapshots,
        snapshotItems
            .map(
              (item) => AssetSnapshotsCompanion.insert(
                id: item.id,
                accountId: item.accountId,
                snapshotDate: item.snapshotDate,
                marketValue: item.marketValue,
                costBasis: Value(item.costBasis),
                cashBalance: Value(item.cashBalance),
                unrealizedPnl: Value(item.unrealizedPnl),
              ),
            )
            .toList(),
      );
    });
  }

  Future<void> replaceAllWithSeedData({
    required List<model.Account> accountItems,
    required List<model.Category> categoryItems,
    required List<model.Budget> budgetItems,
    required List<model.FinanceTransaction> transactionItems,
    required List<model.AssetSnapshot> snapshotItems,
    Map<String, String>? metaValues,
  }) async {
    await super.transaction(() async {
      await delete(assetSnapshots).go();
      await delete(transactions).go();
      await delete(budgets).go();
      await delete(categories).go();
      await delete(accounts).go();
      await delete(appMeta).go();

      await seedAll(
        accountItems: accountItems,
        categoryItems: categoryItems,
        budgetItems: budgetItems,
        transactionItems: transactionItems,
        snapshotItems: snapshotItems,
      );

      if (metaValues != null && metaValues.isNotEmpty) {
        await batch((batch) {
          batch.insertAll(
            appMeta,
            metaValues.entries
                .map(
                  (entry) => AppMetaCompanion.insert(
                    key: entry.key,
                    value: entry.value,
                  ),
                )
                .toList(),
          );
        });
      }

      await into(appMeta).insertOnConflictUpdate(
        const AppMetaCompanion(
          key: Value('seed_completed'),
          value: Value('true'),
        ),
      );
    });
  }

  Future<void> insertAccount(model.Account account) {
    return into(accounts).insert(
      AccountsCompanion.insert(
        id: account.id,
        name: account.name,
        accountType: account.accountType.name,
        reportGroup: account.reportGroup.name,
        currency: account.currency,
        currentBalance: account.currentBalance,
        initialBalance: Value(account.initialBalance),
        institution: Value(account.institution),
        note: Value(account.note),
        isActive: Value(account.isActive),
      ),
    );
  }

  Future<void> updateAccount(model.Account account) {
    return (update(accounts)..where((tbl) => tbl.id.equals(account.id))).write(
      AccountsCompanion(
        name: Value(account.name),
        accountType: Value(account.accountType.name),
        reportGroup: Value(account.reportGroup.name),
        currency: Value(account.currency),
        initialBalance: Value(account.initialBalance),
        currentBalance: Value(account.currentBalance),
        institution: Value(account.institution),
        note: Value(account.note),
        isActive: Value(account.isActive),
      ),
    );
  }

  Future<bool> accountHasLinkedData(String accountId) async {
    final ownedTransactions = await ((select(transactions)
          ..where((tbl) =>
              tbl.accountId.equals(accountId) |
              tbl.toAccountId.equals(accountId))
          ..limit(1)))
        .getSingleOrNull();
    if (ownedTransactions != null) {
      return true;
    }

    final snapshot = await ((select(assetSnapshots)
          ..where((tbl) => tbl.accountId.equals(accountId))
          ..limit(1)))
        .getSingleOrNull();
    return snapshot != null;
  }

  Future<bool> deleteAccountIfSafe(String accountId) async {
    if (await accountHasLinkedData(accountId)) {
      return false;
    }

    await (delete(accounts)..where((tbl) => tbl.id.equals(accountId))).go();
    return true;
  }

  Future<void> insertCategory(model.Category category) {
    return into(categories).insert(
      CategoriesCompanion.insert(
        id: category.id,
        name: category.name,
        type: category.type.name,
        parentId: Value(category.parentId),
      ),
    );
  }

  Future<void> updateCategory(model.Category category) {
    return (update(categories)..where((tbl) => tbl.id.equals(category.id)))
        .write(
      CategoriesCompanion(
        name: Value(category.name),
        type: Value(category.type.name),
        parentId: Value(category.parentId),
      ),
    );
  }

  Future<bool> categoryHasLinkedData(String categoryId) async {
    final linkedTransaction = await ((select(transactions)
          ..where((tbl) => tbl.categoryId.equals(categoryId))
          ..limit(1)))
        .getSingleOrNull();
    if (linkedTransaction != null) {
      return true;
    }
    final linkedBudget = await ((select(budgets)
          ..where((tbl) => tbl.categoryId.equals(categoryId))
          ..limit(1)))
        .getSingleOrNull();
    return linkedBudget != null;
  }

  Future<bool> deleteCategoryIfSafe(String categoryId) async {
    if (await categoryHasLinkedData(categoryId)) {
      return false;
    }
    await (delete(categories)..where((tbl) => tbl.id.equals(categoryId))).go();
    return true;
  }

  Future<void> upsertBudget(model.Budget budget) async {
    final existing = await (select(budgets)
          ..where((tbl) => tbl.id.equals(budget.id)))
        .getSingleOrNull();

    if (existing == null) {
      final sameMonthRule = await (select(budgets)
            ..where((tbl) =>
                tbl.categoryId.equals(budget.categoryId) &
                tbl.monthKey.equals(budget.monthKey)))
          .getSingleOrNull();

      if (sameMonthRule != null) {
        await (update(budgets)..where((tbl) => tbl.id.equals(sameMonthRule.id)))
            .write(
          BudgetsCompanion(
            categoryId: Value(budget.categoryId),
            monthKey: Value(budget.monthKey),
            amount: Value(budget.amount),
            currency: Value(budget.currency),
            alertThreshold: Value(budget.alertThreshold),
            rolloverEnabled: Value(budget.rolloverEnabled),
          ),
        );
        return;
      }
    }

    if (existing == null) {
      await into(budgets).insert(
        BudgetsCompanion.insert(
          id: budget.id,
          categoryId: budget.categoryId,
          monthKey: budget.monthKey,
          amount: budget.amount,
          currency: Value(budget.currency),
          alertThreshold: Value(budget.alertThreshold),
          rolloverEnabled: Value(budget.rolloverEnabled),
        ),
      );
      return;
    }

    await (update(budgets)..where((tbl) => tbl.id.equals(existing.id))).write(
      BudgetsCompanion(
        categoryId: Value(budget.categoryId),
        monthKey: Value(budget.monthKey),
        amount: Value(budget.amount),
        currency: Value(budget.currency),
        alertThreshold: Value(budget.alertThreshold),
        rolloverEnabled: Value(budget.rolloverEnabled),
      ),
    );
  }

  Future<void> deleteBudget(String budgetId) {
    return (delete(budgets)..where((tbl) => tbl.id.equals(budgetId))).go();
  }

  Future<void> insertTransaction(model.FinanceTransaction entry) async {
    await super.transaction(() async {
      await into(transactions).insert(
        TransactionsCompanion.insert(
          id: entry.id,
          type: entry.type.name,
          accountId: entry.accountId,
          amount: entry.amount,
          currency: entry.currency,
          toAmount: Value(entry.toAmount),
          toCurrency: Value(entry.toCurrency),
          recordDate: Value(entry.recordDate),
          transactionDate: entry.transactionDate,
          status: Value(entry.status.name),
          recurringRuleId: Value(entry.recurringRuleId),
          toAccountId: Value(entry.toAccountId),
          categoryId: Value(entry.categoryId),
          description: Value(entry.description),
          merchant: Value(entry.merchant),
        ),
      );

      await _applyTransactionToBalances(entry);
    });
  }

  Future<void> insertTransactions(
      List<model.FinanceTransaction> entries) async {
    await super.transaction(() async {
      for (final entry in entries) {
        await into(transactions).insert(
          TransactionsCompanion.insert(
            id: entry.id,
            type: entry.type.name,
            accountId: entry.accountId,
            amount: entry.amount,
            currency: entry.currency,
            toAmount: Value(entry.toAmount),
            toCurrency: Value(entry.toCurrency),
            recordDate: Value(entry.recordDate),
            transactionDate: entry.transactionDate,
            status: Value(entry.status.name),
            recurringRuleId: Value(entry.recurringRuleId),
            toAccountId: Value(entry.toAccountId),
            categoryId: Value(entry.categoryId),
            description: Value(entry.description),
            merchant: Value(entry.merchant),
          ),
        );
        await _applyTransactionToBalances(entry);
      }
    });
  }

  Future<void> updateTransaction(model.FinanceTransaction entry) async {
    await super.transaction(() async {
      final existing = await (select(transactions)
            ..where((tbl) => tbl.id.equals(entry.id)))
          .getSingle();
      final previous = model.FinanceTransaction(
        id: existing.id,
        type: enumByName(model.TransactionType.values, existing.type),
        accountId: existing.accountId,
        toAccountId: existing.toAccountId,
        categoryId: existing.categoryId,
        amount: existing.amount,
        currency: existing.currency,
        toAmount: existing.toAmount,
        toCurrency: existing.toCurrency,
        recordDate: existing.recordDate ?? existing.transactionDate,
        transactionDate: existing.transactionDate,
        status: existing.status == null
            ? model.TransactionStatus.actual
            : enumByName(model.TransactionStatus.values, existing.status!),
        recurringRuleId: existing.recurringRuleId,
        description: existing.description,
        merchant: existing.merchant,
      );

      await _reverseTransactionFromBalances(previous);
      await (update(transactions)..where((tbl) => tbl.id.equals(entry.id)))
          .write(
        TransactionsCompanion(
          type: Value(entry.type.name),
          accountId: Value(entry.accountId),
          amount: Value(entry.amount),
          currency: Value(entry.currency),
          toAmount: Value(entry.toAmount),
          toCurrency: Value(entry.toCurrency),
          recordDate: Value(entry.recordDate),
          transactionDate: Value(entry.transactionDate),
          status: Value(entry.status.name),
          recurringRuleId: Value(entry.recurringRuleId),
          toAccountId: Value(entry.toAccountId),
          categoryId: Value(entry.categoryId),
          description: Value(entry.description),
          merchant: Value(entry.merchant),
        ),
      );
      await _applyTransactionToBalances(entry);
    });
  }

  Future<void> deleteTransaction(String transactionId) async {
    await super.transaction(() async {
      final existing = await (select(transactions)
            ..where((tbl) => tbl.id.equals(transactionId)))
          .getSingle();
      final previous = model.FinanceTransaction(
        id: existing.id,
        type: enumByName(model.TransactionType.values, existing.type),
        accountId: existing.accountId,
        toAccountId: existing.toAccountId,
        categoryId: existing.categoryId,
        amount: existing.amount,
        currency: existing.currency,
        toAmount: existing.toAmount,
        toCurrency: existing.toCurrency,
        recordDate: existing.recordDate ?? existing.transactionDate,
        transactionDate: existing.transactionDate,
        status: existing.status == null
            ? model.TransactionStatus.actual
            : enumByName(model.TransactionStatus.values, existing.status!),
        recurringRuleId: existing.recurringRuleId,
        description: existing.description,
        merchant: existing.merchant,
      );

      await _reverseTransactionFromBalances(previous);
      await (delete(transactions)..where((tbl) => tbl.id.equals(transactionId)))
          .go();
    });
  }

  Future<void> insertAssetSnapshot(model.AssetSnapshot snapshot) async {
    await super.transaction(() async {
      await into(assetSnapshots).insert(
        AssetSnapshotsCompanion.insert(
          id: snapshot.id,
          accountId: snapshot.accountId,
          snapshotDate: snapshot.snapshotDate,
          marketValue: snapshot.marketValue,
          costBasis: Value(snapshot.costBasis),
          cashBalance: Value(snapshot.cashBalance),
          unrealizedPnl: Value(snapshot.unrealizedPnl),
        ),
      );

      await (update(accounts)
            ..where((tbl) => tbl.id.equals(snapshot.accountId)))
          .write(
        AccountsCompanion(
          currentBalance: Value(snapshot.marketValue),
        ),
      );
    });
  }

  Future<void> updateAssetSnapshot(model.AssetSnapshot snapshot) async {
    await super.transaction(() async {
      await (update(assetSnapshots)..where((tbl) => tbl.id.equals(snapshot.id)))
          .write(
        AssetSnapshotsCompanion(
          accountId: Value(snapshot.accountId),
          snapshotDate: Value(snapshot.snapshotDate),
          marketValue: Value(snapshot.marketValue),
          costBasis: Value(snapshot.costBasis),
          cashBalance: Value(snapshot.cashBalance),
          unrealizedPnl: Value(snapshot.unrealizedPnl),
        ),
      );

      final latest = await (select(assetSnapshots)
            ..where((tbl) => tbl.accountId.equals(snapshot.accountId))
            ..orderBy([(tbl) => OrderingTerm.desc(tbl.snapshotDate)])
            ..limit(1))
          .getSingleOrNull();
      if (latest != null) {
        await (update(accounts)
              ..where((tbl) => tbl.id.equals(snapshot.accountId)))
            .write(
          AccountsCompanion(
            currentBalance: Value(latest.marketValue),
          ),
        );
      }
    });
  }

  Future<void> deleteAssetSnapshot(String snapshotId) async {
    await super.transaction(() async {
      final existing = await (select(assetSnapshots)
            ..where((tbl) => tbl.id.equals(snapshotId)))
          .getSingleOrNull();
      if (existing == null) {
        return;
      }
      final accountId = existing.accountId;
      await (delete(assetSnapshots)..where((tbl) => tbl.id.equals(snapshotId)))
          .go();

      final latest = await (select(assetSnapshots)
            ..where((tbl) => tbl.accountId.equals(accountId))
            ..orderBy([(tbl) => OrderingTerm.desc(tbl.snapshotDate)])
            ..limit(1))
          .getSingleOrNull();
      await (update(accounts)..where((tbl) => tbl.id.equals(accountId))).write(
        AccountsCompanion(
          currentBalance: Value(latest?.marketValue ?? 0),
        ),
      );
    });
  }

  Future<void> clearAllUserData() async {
    await super.transaction(() async {
      await delete(assetSnapshots).go();
      await delete(transactions).go();
      await delete(budgets).go();
      await delete(categories).go();
      await delete(accounts).go();
      await into(appMeta).insertOnConflictUpdate(
        const AppMetaCompanion(
          key: Value('seed_completed'),
          value: Value('true'),
        ),
      );
    });
  }

  Future<void> _applyTransactionToBalances(
      model.FinanceTransaction transaction) async {
    if (!transaction.affectsBalance) {
      return;
    }
    switch (transaction.type) {
      case model.TransactionType.income:
        await _incrementAccountBalance(
            transaction.accountId, transaction.amount);
        return;
      case model.TransactionType.adjustment:
        await _incrementAccountBalance(
            transaction.accountId, transaction.amount);
        await _syncInvestmentFlowIntoSnapshot(
          accountId: transaction.accountId,
          delta: transaction.amount,
          transactionDate: transaction.transactionDate,
        );
        return;
      case model.TransactionType.expense:
        await _incrementAccountBalance(
            transaction.accountId, -transaction.amount);
        return;
      case model.TransactionType.transfer:
        await _incrementAccountBalance(
            transaction.accountId, -transaction.amount);
        await _syncInvestmentFlowIntoSnapshot(
          accountId: transaction.accountId,
          delta: -transaction.amount,
          transactionDate: transaction.transactionDate,
        );
        if (transaction.toAccountId != null) {
          final incomingAmount = transaction.transferInAmount;
          await _incrementAccountBalance(
              transaction.toAccountId!, incomingAmount);
          await _syncInvestmentFlowIntoSnapshot(
            accountId: transaction.toAccountId!,
            delta: incomingAmount,
            transactionDate: transaction.transactionDate,
          );
        }
        return;
    }
  }

  Future<void> _reverseTransactionFromBalances(
      model.FinanceTransaction transaction) async {
    if (!transaction.affectsBalance) {
      return;
    }
    switch (transaction.type) {
      case model.TransactionType.income:
        await _incrementAccountBalance(
            transaction.accountId, -transaction.amount);
        return;
      case model.TransactionType.adjustment:
        await _incrementAccountBalance(
            transaction.accountId, -transaction.amount);
        await _syncInvestmentFlowIntoSnapshot(
          accountId: transaction.accountId,
          delta: -transaction.amount,
          transactionDate: transaction.transactionDate,
        );
        return;
      case model.TransactionType.expense:
        await _incrementAccountBalance(
            transaction.accountId, transaction.amount);
        return;
      case model.TransactionType.transfer:
        await _incrementAccountBalance(
            transaction.accountId, transaction.amount);
        await _syncInvestmentFlowIntoSnapshot(
          accountId: transaction.accountId,
          delta: transaction.amount,
          transactionDate: transaction.transactionDate,
        );
        if (transaction.toAccountId != null) {
          final incomingAmount = transaction.transferInAmount;
          await _incrementAccountBalance(
              transaction.toAccountId!, -incomingAmount);
          await _syncInvestmentFlowIntoSnapshot(
            accountId: transaction.toAccountId!,
            delta: -incomingAmount,
            transactionDate: transaction.transactionDate,
          );
        }
        return;
    }
  }

  Future<void> _incrementAccountBalance(String accountId, double delta) async {
    final row = await (select(accounts)
          ..where((tbl) => tbl.id.equals(accountId)))
        .getSingle();
    await (update(accounts)..where((tbl) => tbl.id.equals(accountId))).write(
      AccountsCompanion(
        currentBalance: Value(row.currentBalance + delta),
      ),
    );
  }

  Future<void> _syncInvestmentFlowIntoSnapshot({
    required String accountId,
    required double delta,
    required DateTime transactionDate,
  }) async {
    if (delta == 0) {
      return;
    }
    final account = await (select(accounts)
          ..where((tbl) => tbl.id.equals(accountId)))
        .getSingle();
    final reportGroup =
        enumByName(model.ReportGroup.values, account.reportGroup);
    if (reportGroup != model.ReportGroup.investment &&
        reportGroup != model.ReportGroup.retirement) {
      return;
    }

    final latest = await (select(assetSnapshots)
          ..where((tbl) => tbl.accountId.equals(accountId))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.snapshotDate)])
          ..limit(1))
        .getSingleOrNull();
    final first = await (select(assetSnapshots)
          ..where((tbl) => tbl.accountId.equals(accountId))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.snapshotDate)])
          ..limit(1))
        .getSingleOrNull();

    if (latest == null) {
      final seededCost = delta.clamp(0, double.infinity).toDouble();
      final seededMarketValue = account.currentBalance;
      final seededCashBalance =
          account.currentBalance.clamp(0, double.infinity).toDouble();
      await into(assetSnapshots).insert(
        AssetSnapshotsCompanion.insert(
          id: 'snap_${DateTime.now().microsecondsSinceEpoch}',
          accountId: accountId,
          snapshotDate: transactionDate,
          marketValue: seededMarketValue,
          costBasis: Value(seededCost),
          cashBalance: Value(seededCashBalance),
          unrealizedPnl: Value(seededMarketValue - seededCost),
        ),
      );
      return;
    }

    final nextMarketValue = latest.marketValue + delta;
    final nextCashBalance =
        (latest.cashBalance + delta).clamp(0, double.infinity).toDouble();
    final shouldAdjustBaselineCost =
        first != null && !transactionDate.isAfter(first.snapshotDate);
    final nextLatestCostBasis =
        shouldAdjustBaselineCost && first.id == latest.id
            ? (latest.costBasis + delta).clamp(0, double.infinity).toDouble()
            : latest.costBasis;
    await (update(assetSnapshots)..where((tbl) => tbl.id.equals(latest.id)))
        .write(
      AssetSnapshotsCompanion(
        marketValue: Value(nextMarketValue),
        costBasis: Value(nextLatestCostBasis),
        cashBalance: Value(nextCashBalance),
        unrealizedPnl: Value(nextMarketValue - nextLatestCostBasis),
      ),
    );

    if (shouldAdjustBaselineCost && first.id != latest.id) {
      final nextFirstCostBasis =
          (first.costBasis + delta).clamp(0, double.infinity).toDouble();
      await (update(assetSnapshots)..where((tbl) => tbl.id.equals(first.id)))
          .write(
        AssetSnapshotsCompanion(
          costBasis: Value(nextFirstCostBasis),
          unrealizedPnl: Value(first.marketValue - nextFirstCostBasis),
        ),
      );
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, 'finance_app.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
