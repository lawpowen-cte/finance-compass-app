import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/finance_repository.dart';
import '../../models/asset_snapshot.dart';
import '../repository_provider.dart';

/// Asset snapshot CRUD operations.
///
/// Wraps [FinanceRepository] asset-snapshot methods and refreshes the
/// global repository state after every write.
class AssetMutations extends Notifier<void> {
  @override
  void build() {}

  FinanceRepositoryNotifier get _repoNotifier =>
      ref.read(financeRepositoryProvider.notifier);

  Future<FinanceRepository> get _repo =>
      ref.read(financeRepositoryProvider.future);

  /// Creates a new asset snapshot for an account.
  Future<void> addSnapshot(AssetSnapshot snapshot) async {
    final updated = await (await _repo).addAssetSnapshot(snapshot);
    _repoNotifier.setRepository(updated);
  }

  /// Updates an existing asset snapshot.
  Future<void> updateSnapshot(AssetSnapshot snapshot) async {
    final updated = await (await _repo).updateExistingAssetSnapshot(snapshot);
    _repoNotifier.setRepository(updated);
  }

  /// Deletes an asset snapshot by its id.
  Future<void> deleteSnapshot(String snapshotId) async {
    final updated = await (await _repo).deleteExistingAssetSnapshot(snapshotId);
    _repoNotifier.setRepository(updated);
  }
}

/// Provider for asset snapshot CRUD mutations.
final assetMutationsProvider =
    NotifierProvider<AssetMutations, void>(AssetMutations.new);
