import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/finance_repository.dart';
import 'database_provider.dart';

/// Manages the lifecycle of [FinanceRepository].
///
/// On build the repository is loaded from the database. Mutation providers
/// update [state] after every write so the whole widget tree re-renders.
class FinanceRepositoryNotifier extends AsyncNotifier<FinanceRepository> {
  @override
  Future<FinanceRepository> build() async {
    final db = ref.watch(appDatabaseProvider);
    return FinanceRepository.load(db);
  }

  /// Discards the current repository and reloads everything from disk.
  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return FinanceRepository.load(ref.read(appDatabaseProvider));
    });
  }

  /// Replaces the current [AsyncValue] with a pre-loaded [repository].
  ///
  /// Used by mutation providers to propagate the refreshed instance without
  /// triggering a second database round-trip.
  void setRepository(FinanceRepository repository) {
    state = AsyncData(repository);
  }
}

/// The central data source for the entire app.
///
/// UI code watches this provider; mutation providers read its notifier to
/// call repository methods and then push the refreshed instance back via
/// [FinanceRepositoryNotifier.setRepository].
final financeRepositoryProvider =
    AsyncNotifierProvider<FinanceRepositoryNotifier, FinanceRepository>(
  FinanceRepositoryNotifier.new,
);
