import 'package:drift/drift.dart';

import 'accounts_table.dart';

class AssetSnapshots extends Table {
  TextColumn get id => text()();
  TextColumn get accountId => text().references(Accounts, #id)();
  DateTimeColumn get snapshotDate => dateTime()();
  RealColumn get marketValue => real()();
  RealColumn get costBasis => real().withDefault(const Constant(0))();
  RealColumn get cashBalance => real().withDefault(const Constant(0))();
  RealColumn get unrealizedPnl => real().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
