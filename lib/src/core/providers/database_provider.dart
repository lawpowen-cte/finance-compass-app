import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../database/database_provider.dart';

/// Provides the singleton [AppDatabase] instance to the widget tree.
///
/// This is a synchronous provider — the database is lazily opened on first
/// access via the existing [DatabaseProvider.instance] singleton.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return DatabaseProvider.instance;
});
