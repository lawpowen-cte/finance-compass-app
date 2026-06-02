import 'package:drift/drift.dart';

import 'categories_table.dart';

class Budgets extends Table {
  TextColumn get id => text()();
  TextColumn get categoryId => text().references(Categories, #id)();
  TextColumn get monthKey => text()();
  RealColumn get amount => real()();
  TextColumn get currency => text().withDefault(const Constant('MYR'))();
  RealColumn get alertThreshold => real().withDefault(const Constant(0.8))();
  BoolColumn get rolloverEnabled =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
