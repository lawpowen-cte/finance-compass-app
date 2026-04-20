import 'package:flutter/material.dart';
import 'dart:typed_data';

import '../../core/data/finance_repository.dart';
import '../../core/database/database_provider.dart';
import '../../core/models/account.dart';
import '../../core/models/asset_snapshot.dart';
import '../../core/models/budget.dart';
import '../../core/models/category.dart';
import '../../core/models/transaction.dart';
import '../../core/settings/app_settings_controller.dart';
import '../../core/theme/finance_theme.dart';
import '../accounts/accounts_screen.dart';
import '../budgets/budgets_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/settings_screen.dart';
import '../transactions/transactions_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.repositoryFuture,
    required this.settingsController,
  });

  final Future<FinanceRepository>? repositoryFuture;
  final AppSettingsController settingsController;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  FinanceRepository? repository;
  Object? loadError;
  bool isBusy = true;
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadRepository();
  }

  Future<void> _loadRepository() async {
    setState(() {
      isBusy = true;
      loadError = null;
    });

    try {
      final loadedRepository =
          await (widget.repositoryFuture ?? FinanceRepository.load(DatabaseProvider.instance));
      if (!mounted) {
        return;
      }
      setState(() {
        repository = loadedRepository;
        isBusy = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        loadError = error;
        isBusy = false;
      });
    }
  }

  Future<void> _replaceRepository(Future<FinanceRepository> future) async {
    setState(() => isBusy = true);
    try {
      final nextRepository = await future;
      if (!mounted) {
        return;
      }
      setState(() {
        repository = nextRepository;
        isBusy = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        loadError = error;
        isBusy = false;
      });
    }
  }

  Future<FinanceRepository> _replaceRepositoryAndReturn(Future<FinanceRepository> future) async {
    setState(() => isBusy = true);
    try {
      final nextRepository = await future;
      if (!mounted) {
        return nextRepository;
      }
      setState(() {
        repository = nextRepository;
        isBusy = false;
      });
      return nextRepository;
    } catch (error) {
      if (mounted) {
        setState(() {
          loadError = error;
          isBusy = false;
        });
      }
      rethrow;
    }
  }

  Future<void> _handleAddAccount(Account account) {
    return _replaceRepository(repository!.addAccount(account));
  }

  Future<void> _handleUpdateAccount(Account account) {
    return _replaceRepository(repository!.updateExistingAccount(account));
  }

  Future<void> _handleAddBudget(Budget budget) {
    return _replaceRepository(repository!.addBudget(budget));
  }

  Future<void> _handleDeleteBudget(String budgetId) {
    return _replaceRepository(repository!.deleteExistingBudget(budgetId));
  }

  Future<void> _handleAddCategory(Category category) {
    return _replaceRepository(repository!.addCategory(category));
  }

  Future<void> _handleUpdateCategory(Category category) {
    return _replaceRepository(repository!.updateExistingCategory(category));
  }

  Future<ImportPreview> _handlePreviewImportJson(String path) {
    return repository!.previewImportJson(path);
  }

  Future<void> _handleAddTransaction(FinanceTransaction transaction) {
    return _replaceRepository(repository!.addTransaction(transaction));
  }

  Future<void> _handleUpdateTransaction(FinanceTransaction transaction) {
    return _replaceRepository(repository!.updateExistingTransaction(transaction));
  }

  Future<void> _handleDeleteTransaction(String transactionId) {
    return _replaceRepository(repository!.deleteExistingTransaction(transactionId));
  }

  Future<void> _handleAddSnapshot(AssetSnapshot snapshot) {
    return _replaceRepository(repository!.addAssetSnapshot(snapshot));
  }

  Future<FinanceRepository> _handleUpdateSnapshot(AssetSnapshot snapshot) {
    return _replaceRepositoryAndReturn(repository!.updateExistingAssetSnapshot(snapshot));
  }

  Future<FinanceRepository> _handleDeleteSnapshot(String snapshotId) {
    return _replaceRepositoryAndReturn(repository!.deleteExistingAssetSnapshot(snapshotId));
  }

  Future<void> _handleLoadExampleData() {
    return _replaceRepository(repository!.loadExampleData());
  }

  Future<Uint8List> _handleExportJsonBytes() {
    return repository!.exportJsonSnapshotBytes();
  }

  Future<Uint8List> _handleExportAiSummaryBytes() async {
    final monthKeys = repository!.transactions
        .map((item) => item.transactionDate)
        .map((date) => '${date.year}-${date.month.toString().padLeft(2, '0')}')
        .toSet()
        .toList()
      ..sort();
    return repository!.exportAiSummaryBytes(
      monthKeys: monthKeys,
    );
  }

  Future<void> _handleImportJson(String path) {
    return _replaceRepository(repository!.importJsonSnapshot(path));
  }

  Future<bool> _handleDeleteAccount(String accountId) async {
    final nextRepository = await repository!.deleteAccountIfSafe(accountId);
    if (nextRepository == null) {
      return false;
    }
    if (!mounted) {
      return false;
    }
    setState(() {
      repository = nextRepository;
    });
    return true;
  }

  Future<bool> _handleDeleteCategory(String categoryId) async {
    final nextRepository = await repository!.deleteCategoryIfSafe(categoryId);
    if (nextRepository == null) {
      return false;
    }
    if (!mounted) {
      return false;
    }
    setState(() {
      repository = nextRepository;
    });
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (isBusy && repository == null) {
      return const Scaffold(
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }

    if (loadError != null && repository == null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Failed to open finance database: $loadError'),
            ),
          ),
        ),
      );
    }

    final currentRepository = repository!;
    final palette = paletteForStyle(widget.settingsController.themeStyle);
    final screens = [
      DashboardScreen(repository: currentRepository),
      AccountsScreen(
        repository: currentRepository,
        onAddAccount: _handleAddAccount,
        onEditAccount: _handleUpdateAccount,
        onDeleteAccount: _handleDeleteAccount,
        onAddSnapshot: _handleAddSnapshot,
        onEditSnapshot: _handleUpdateSnapshot,
        onDeleteSnapshot: _handleDeleteSnapshot,
      ),
      TransactionsScreen(
        repository: currentRepository,
        onAddTransaction: _handleAddTransaction,
        onEditTransaction: _handleUpdateTransaction,
        onDeleteTransaction: _handleDeleteTransaction,
        onAddCategory: _handleAddCategory,
        onUpdateCategory: _handleUpdateCategory,
        onDeleteCategory: _handleDeleteCategory,
      ),
      BudgetsScreen(
        repository: currentRepository,
        onAddBudget: _handleAddBudget,
        onDeleteBudget: _handleDeleteBudget,
      ),
      ReportsScreen(repository: currentRepository),
      SettingsScreen(
        settingsController: widget.settingsController,
        onLoadExampleData: _handleLoadExampleData,
        onExportJsonBytes: _handleExportJsonBytes,
        onExportAiSummaryBytes: _handleExportAiSummaryBytes,
        onImportJson: _handleImportJson,
        onPreviewImportJson: _handlePreviewImportJson,
      ),
    ];

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                palette.backgroundTop,
                palette.background,
                palette.backgroundBottom,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(child: screens[selectedIndex]),
            bottomNavigationBar: NavigationBar(
              selectedIndex: selectedIndex,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
              destinations: const [
                NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: ''),
                NavigationDestination(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  label: '',
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  label: '',
                ),
                NavigationDestination(icon: Icon(Icons.savings_outlined), label: ''),
                NavigationDestination(icon: Icon(Icons.insights_outlined), label: ''),
                NavigationDestination(icon: Icon(Icons.tune_outlined), label: ''),
              ],
              onDestinationSelected: (index) {
                setState(() => selectedIndex = index);
              },
            ),
          ),
        ),
        if (isBusy)
          IgnorePointer(
            child: Container(
              color: Colors.black12,
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}
