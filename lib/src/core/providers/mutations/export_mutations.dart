import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/finance_repository.dart';
import '../repository_provider.dart';

/// Export / Import operations.
///
/// These are data-portability actions that either produce a file path /
/// bytes (export) or replace the entire database contents (import). After
/// an import the global [financeRepositoryProvider] is refreshed so the
/// UI reflects the new data.
class ExportMutations extends Notifier<void> {
  @override
  void build() {}

  FinanceRepositoryNotifier get _repoNotifier =>
      ref.read(financeRepositoryProvider.notifier);

  Future<FinanceRepository> get _repo =>
      ref.read(financeRepositoryProvider.future);

  /// Exports the full data snapshot as a JSON file.
  ///
  /// Returns the absolute path of the written file.
  Future<String> exportJson([String? targetPath]) async {
    return (await _repo).exportJsonSnapshot(targetPath);
  }

  /// Exports the full data snapshot as UTF-8 encoded JSON bytes.
  Future<Uint8List> exportJsonBytes() async {
    return (await _repo).exportJsonSnapshotBytes();
  }

  /// Exports an AI-friendly summary JSON for the given [monthKeys].
  ///
  /// Returns the absolute path of the written file.
  Future<String> exportAiSummary(
    String targetPath, {
    required List<String> monthKeys,
  }) async {
    return (await _repo).exportAiSummaryJson(targetPath, monthKeys: monthKeys);
  }

  /// Exports AI summary as bytes.
  Future<Uint8List> exportAiSummaryBytes({
    required List<String> monthKeys,
  }) async {
    return (await _repo).exportAiSummaryBytes(monthKeys: monthKeys);
  }

  /// Exports future planning CSV as bytes.
  Future<Uint8List> exportFuturePlanningCsvBytes({int months = 24}) async {
    return (await _repo).exportFuturePlanningCsvBytes(months: months);
  }

  /// Previews an import file without writing to the database.
  Future<ImportPreview> previewImport(String path) async {
    return (await _repo).previewImportJson(path);
  }

  /// Imports a JSON snapshot, replacing all existing data.
  ///
  /// After import the [financeRepositoryProvider] is refreshed so the
  /// entire UI rebuilds with the new data.
  Future<void> importJson(String path) async {
    final updated = await (await _repo).importJsonSnapshot(path);
    _repoNotifier.setRepository(updated);
  }

  /// Clears all user data and reloads an empty repository.
  Future<void> clearAllData() async {
    final updated = await (await _repo).clearAllData();
    _repoNotifier.setRepository(updated);
  }

  /// Loads the bundled example / seed data.
  Future<void> loadExampleData() async {
    final updated = await (await _repo).loadExampleData();
    _repoNotifier.setRepository(updated);
  }
}

/// Provider for export / import mutations.
final exportMutationsProvider =
    NotifierProvider<ExportMutations, void>(ExportMutations.new);
