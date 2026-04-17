import '../data/sample_data.dart';
import 'app_database.dart';

class FinanceSeedService {
  FinanceSeedService(this.database);

  final AppDatabase database;

  Future<void> seedIfNeeded() async {
    final hasCompletedSeed = await database.hasCompletedSeed();
    if (hasCompletedSeed) {
      return;
    }

    final hasAccounts = await database.accountCount();
    if (hasAccounts > 0) {
      await database.markSeedCompleted();
      return;
    }

    await database.seedAll(
      accountItems: SampleData.accounts(),
      categoryItems: SampleData.categories(),
      budgetItems: SampleData.budgets(),
      transactionItems: SampleData.transactions(),
      snapshotItems: SampleData.snapshots(),
    );
    await database.markSeedCompleted();
  }
}
