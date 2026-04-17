import 'package:drift/drift.dart';

import 'accounts_table.dart';
import 'categories_table.dart';

class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()();
  TextColumn get accountId => text().references(Accounts, #id)();
  TextColumn get toAccountId => text().nullable().references(Accounts, #id)();
  TextColumn get categoryId => text().nullable().references(Categories, #id)();
  RealColumn get amount => real()();
  TextColumn get currency => text()();
  DateTimeColumn get transactionDate => dateTime()();
  TextColumn get description => text().nullable()();
  TextColumn get merchant => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
