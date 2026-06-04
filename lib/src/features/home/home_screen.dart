import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/repository_provider.dart';
import '../../core/settings/app_settings_controller.dart';
import '../../core/theme/finance_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../accounts/accounts_screen.dart';
import '../budgets/budgets_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/settings_screen.dart';
import '../transactions/transactions_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, required this.settingsController});

  final AppSettingsController settingsController;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final repositoryAsync = ref.watch(financeRepositoryProvider);

    return repositoryAsync.when(
      loading: () => const Scaffold(
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      ),
      error: (error, _) => Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Failed to open finance database: $error'),
            ),
          ),
        ),
      ),
      data: (repository) {
        setActiveBaseCurrency(repository.baseCurrency);
        final palette = paletteForStyle(widget.settingsController.themeStyle);
        final screens = [
          DashboardScreen(repository: repository),
          AccountsScreen(repository: repository),
          TransactionsScreen(repository: repository),
          BudgetsScreen(repository: repository),
          ReportsScreen(repository: repository),
          SettingsScreen(
            repository: repository,
            settingsController: widget.settingsController,
          ),
        ];

        return Container(
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
              labelBehavior:
                  NavigationDestinationLabelBehavior.onlyShowSelected,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  label: '总览',
                ),
                NavigationDestination(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  label: '账户',
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  label: '交易',
                ),
                NavigationDestination(
                  icon: Icon(Icons.savings_outlined),
                  label: '预算',
                ),
                NavigationDestination(
                  icon: Icon(Icons.insights_outlined),
                  label: '报表',
                ),
                NavigationDestination(
                  icon: Icon(Icons.tune_outlined),
                  label: '设置',
                ),
              ],
              onDestinationSelected: (index) {
                setState(() => selectedIndex = index);
              },
            ),
          ),
        );
      },
    );
  }
}
