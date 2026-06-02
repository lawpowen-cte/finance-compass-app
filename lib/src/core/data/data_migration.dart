import 'dart:convert';

import 'package:drift/drift.dart';

import '../database/app_database.dart'
    hide Account, AssetSnapshot, Budget, Category;
import '../database/enum_codec.dart';

import '../models/account.dart';
import '../models/transaction.dart';
import '../utils/currency_formatter.dart';

/// Handles data migration from older versions of the app and ensures
/// sensible defaults exist for fresh installs.
///
/// Call [migrateLegacyData] during app startup after the database is opened.
/// Call [ensureDefaults] for fresh installs to set up base configuration.

// Meta keys used by the currency system.
const _exchangeRatesMetaKey = 'exchange_rates_to_base_json';
const _currencyPriorityMetaKey = 'currency_priority_json';
const _migrationVersionKey = 'data_migration_version';
const _currentMigrationVersion = 1;

/// Migrates legacy data from the old GitHub version of the app.
///
/// This function is safe to call multiple times — it tracks which migrations
/// have already been applied via a version key in the [AppMeta] table.
Future<void> migrateLegacyData(AppDatabase db) async {
  final appliedVersion = await _appliedMigrationVersion(db);

  if (appliedVersion >= _currentMigrationVersion) {
    return; // Already up to date.
  }

  // Migration 0 → 1: Ensure currency meta defaults and fix data integrity.
  if (appliedVersion < 1) {
    await _ensureCurrencyMetaDefaults(db);
    await _ensureAccountReportGroups(db);
    await _ensureTransactionStatuses(db);
  }

  await db.setMetaValue(_migrationVersionKey, _currentMigrationVersion.toString());
}

/// Sets up sensible defaults for a fresh install.
///
/// This should be called once after seeding sample data or when the user
/// starts with an empty database. It is idempotent — existing values are
/// never overwritten.
Future<void> ensureDefaults(AppDatabase db) async {
  // Ensure currency metadata exists.
  final existingRates = await db.getMetaValue(_exchangeRatesMetaKey);
  if (existingRates == null || existingRates.trim().isEmpty) {
    await db.setMetaValue(
      _exchangeRatesMetaKey,
      jsonEncode(defaultExchangeRatesToBase),
    );
  }

  final existingPriority = await db.getMetaValue(_currencyPriorityMetaKey);
  if (existingPriority == null || existingPriority.trim().isEmpty) {
    await db.setMetaValue(
      _currencyPriorityMetaKey,
      jsonEncode(supportedCurrencies),
    );
  }
}

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

Future<int> _appliedMigrationVersion(AppDatabase db) async {
  final raw = await db.getMetaValue(_migrationVersionKey);
  if (raw == null || raw.trim().isEmpty) {
    return 0;
  }
  return int.tryParse(raw) ?? 0;
}

/// Ensures the exchange rate and currency priority meta values exist.
///
/// Legacy databases from the old app version may not have these keys at all
/// (they were added later). This sets MYR as the base currency with standard
/// default exchange rates.
Future<void> _ensureCurrencyMetaDefaults(AppDatabase db) async {
  final existingRates = await db.getMetaValue(_exchangeRatesMetaKey);
  if (existingRates == null || existingRates.trim().isEmpty) {
    await db.setMetaValue(
      _exchangeRatesMetaKey,
      jsonEncode(defaultExchangeRatesToBase),
    );
  }

  final existingPriority = await db.getMetaValue(_currencyPriorityMetaKey);
  if (existingPriority == null || existingPriority.trim().isEmpty) {
    await db.setMetaValue(
      _currencyPriorityMetaKey,
      jsonEncode(supportedCurrencies),
    );
  }
}

/// Ensures every account has a valid [ReportGroup] value.
///
/// Older data may have empty or invalid reportGroup strings stored in the
/// database. This fixes them by inferring a reasonable default from the
/// account type. Uses raw queries to avoid the model layer crashing on
/// invalid enum values.
Future<void> _ensureAccountReportGroups(AppDatabase db) async {
  final validGroups = ReportGroup.values.map((e) => e.name).toSet();

  // Query raw rows so we don't trigger enumByName on bad data.
  final rawRows = await db.select(db.accounts).get();
  for (final row in rawRows) {
    final reportGroupValue = row.reportGroup;
    if (reportGroupValue.isEmpty || !validGroups.contains(reportGroupValue)) {
      // Infer from the account type; fall back to 'cash' if type is also bad.
      AccountType accountType;
      try {
        accountType = enumByName(AccountType.values, row.accountType);
      } catch (_) {
        accountType = AccountType.cash;
      }
      final inferred = _inferReportGroup(accountType);

      await (db.update(db.accounts)
            ..where((tbl) => tbl.id.equals(row.id)))
          .write(
        AccountsCompanion(
          reportGroup: Value(inferred.name),
        ),
      );
    }
  }
}

/// Ensures every transaction has a valid [TransactionStatus] value.
///
/// The `status` column was added in schema version 4. Transactions that
/// predate this migration will have a NULL status. The Drift fetch layer
/// already defaults to [TransactionStatus.actual], but we persist that
/// default so raw SQL queries and exports also see a consistent value.
Future<void> _ensureTransactionStatuses(AppDatabase db) async {
  // Use a raw update to fix all rows with NULL status at once.
  // This is more efficient than loading every transaction into Dart.
  await db.customUpdate(
    "UPDATE transactions SET status = 'actual' WHERE status IS NULL",
  );
}

/// Infers a [ReportGroup] from an [AccountType] when the stored value is
/// missing or invalid.
ReportGroup _inferReportGroup(AccountType accountType) {
  switch (accountType) {
    case AccountType.creditCard:
      return ReportGroup.credit;
    case AccountType.stock:
    case AccountType.crypto:
    case AccountType.trading:
    case AccountType.fund:
    case AccountType.moneyMarketFund:
      return ReportGroup.investment;
    case AccountType.pension:
      return ReportGroup.retirement;
    case AccountType.cash:
    case AccountType.bankSaving:
    case AccountType.eWallet:
    case AccountType.other:
      return ReportGroup.cash;
  }
}
