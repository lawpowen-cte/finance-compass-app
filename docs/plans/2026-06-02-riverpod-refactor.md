# Finance Compass — Riverpod + Repository 拆分重构计划

> **For Hermes:** Use subagent-driven-development skill to implement this plan task-by-task.

**Goal:** 将 Finance Compass 从纯 setState + callback drilling 架构迁移到 Riverpod 状态管理，同时拆分 2663 行的 FinanceRepository 上帝类。

**Architecture:** Riverpod Provider 管理状态 + 多个 Service 类分工处理业务逻辑，消灭 HomeScreen 的 20+ callback 参数。

**Tech Stack:** Flutter 3.3+ / Dart / Drift (SQLite) / flutter_riverpod

---

## 重构前 vs 重构后对比

### 重构前
```
main.dart → HomeScreen (持有 repository + 20个callback)
  → DashboardScreen (repository)
  → TransactionsScreen (repository + 12个callback)
  → AccountsScreen (repository + 10个callback)
  → BudgetsScreen (repository + callback)
  → ReportsScreen (repository)
  → SettingsScreen (repository + 8个callback)
```

### 重构后
```
main.dart → ProviderScope → FinanceApp
  → HomeScreen (只关心 selectedIndex)
  → DashboardScreen (ref.watch + ref.read)
  → TransactionsScreen (ref.watch + ref.read)
  → AccountsScreen (ref.watch + ref.read)
  → BudgetsScreen (ref.watch + ref.read)
  → ReportsScreen (ref.watch + ref.read)
  → SettingsScreen (ref.watch + ref.read)
```

### Repository 拆分前 (1 file, 2663 lines)
```
FinanceRepository — 所有业务逻辑
```

### Repository 拆分后
```
FinanceRepository (精简版, ~300行) — 加载、刷新、基础getter
├── AccountService — 账户CRUD、余额计算、对账
├── TransactionService — 交易CRUD、模板、周期规则
├── BudgetService — 预算CRUD、余额计算、rollover
├── CategoryService — 分类CRUD
├── AssetService — 资产快照CRUD、投资汇总
├── CurrencyService — 汇率、多币种转换
├── ReportService — 月度汇总、预测、现金流
├── ExportService — JSON导入导出、AI摘要、CSV
└── MetaService — 元数据读写
```

---

## Phase 1: 引入 Riverpod 基础设施

### Task 1.1: 添加 flutter_riverpod 依赖

**Objective:** 安装 Riverpod 包

**Files:**
- Modify: `pubspec.yaml`

**Step 1:** 在 `pubspec.yaml` 的 `dependencies` 下添加:
```yaml
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.6.1
```

在 `dev_dependencies` 下添加:
```yaml
  riverpod_generator: ^2.6.3
  build_runner: ^2.7.1  # 已有
```

**Step 2:** 运行:
```bash
cd ~/projects/finance-compass-app && flutter pub get
```

**Step 3:** Commit:
```bash
git add pubspec.yaml pubspec.lock
git commit -m "deps: add flutter_riverpod"
```

---

### Task 1.2: 包裹 ProviderScope

**Objective:** 在 App 根节点启用 Riverpod

**Files:**
- Modify: `lib/main.dart`
- Modify: `lib/src/app.dart`

**Step 1:** 修改 `lib/main.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app.dart';
import 'src/core/settings/app_settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settingsController = AppSettingsController();
  await settingsController.load();
  runApp(
    ProviderScope(
      child: FinanceApp(settingsController: settingsController),
    ),
  );
}
```

**Step 2:** 修改 `lib/src/app.dart` — 将 `StatelessWidget` 改为 `ConsumerWidget`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/settings/app_settings_controller.dart';
import 'core/theme/finance_theme.dart';
import 'features/home/home_screen.dart';

class FinanceApp extends ConsumerWidget {
  const FinanceApp({
    super.key,
    required this.settingsController,
  });

  final AppSettingsController settingsController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnimatedBuilder(
      animation: settingsController,
      builder: (context, _) {
        return MaterialApp(
          title: 'Finance App',
          debugShowCheckedModeBanner: false,
          theme: buildFinanceTheme(settingsController.themeStyle),
          home: HomeScreen(settingsController: settingsController),
        );
      },
    );
  }
}
```

**Step 3:** 验证编译:
```bash
cd ~/projects/finance-compass-app && flutter analyze --no-fatal-infos
```

**Step 4:** Commit:
```bash
git add lib/main.dart lib/src/app.dart
git commit -m "refactor: wrap app in ProviderScope"
```

---

## Phase 2: 创建 Riverpod Providers

### Task 2.1: 创建 DatabaseProvider (Riverpod)

**Objective:** 用 Riverpod Provider 替换手写的 DatabaseProvider singleton

**Files:**
- Create: `lib/src/core/providers/database_provider.dart`
- Keep (暂时不删): `lib/src/core/database/database_provider.dart`

**Step 1:** 创建 `lib/src/core/providers/database_provider.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';

/// 提供 AppDatabase 单例，Riverpod 管理生命周期
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});
```

**Step 2:** Commit:
```bash
git add lib/src/core/providers/database_provider.dart
git commit -m "feat: add Riverpod database provider"
```

---

### Task 2.2: 创建 FinanceRepository AsyncNotifier

**Objective:** 用 AsyncNotifier 管理 FinanceRepository 的加载和刷新

**Files:**
- Create: `lib/src/core/providers/repository_provider.dart`

**Step 1:** 创建 `lib/src/core/providers/repository_provider.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/finance_repository.dart';
import 'database_provider.dart';

/// 异步加载 FinanceRepository，提供刷新方法
final financeRepositoryProvider =
    AsyncNotifierProvider<FinanceRepositoryNotifier, FinanceRepository>(
  FinanceRepositoryNotifier.new,
);

class FinanceRepositoryNotifier extends AsyncNotifier<FinanceRepository> {
  @override
  Future<FinanceRepository> build() async {
    final db = ref.watch(appDatabaseProvider);
    return FinanceRepository.load(db);
  }

  /// 刷新（重新从数据库加载）
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }
}
```

**Step 2:** Commit:
```bash
git add lib/src/core/providers/repository_provider.dart
git commit -m "feat: add Riverpod financeRepositoryProvider"
```

---

### Task 2.3: 创建 SettingsProvider

**Objective:** 将 AppSettingsController 用 Riverpod 包裹

**Files:**
- Create: `lib/src/core/providers/settings_provider.dart`

**Step 1:** 创建 `lib/src/core/providers/settings_provider.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/app_settings_controller.dart';

/// AppSettingsController 作为 Riverpod StateNotifier
final appSettingsProvider =
    AsyncNotifierProvider<AppSettingsNotifier, AppSettingsController>(
  AppSettingsNotifier.new,
);

class AppSettingsNotifier extends AsyncNotifier<AppSettingsController> {
  @override
  Future<AppSettingsController> build() async {
    final controller = AppSettingsController();
    await controller.load();
    return controller;
  }

  Future<void> setThemeStyle(AppThemeStyle style) async {
    final controller = await future;
    await controller.setThemeStyle(style);
    state = AsyncData(controller);
  }
}
```

注意: 这里 `AppThemeStyle` 需要 import，实际文件需要根据 `app_theme_style.dart` 调整。

**Step 2:** Commit:
```bash
git add lib/src/core/providers/settings_provider.dart
git commit -m "feat: add Riverpod settings provider"
```

---

## Phase 3: 拆分 FinanceRepository

这是最关键也是工作量最大的一步。FinanceRepository 有 2663 行，需要拆分成独立的 Service。

### 拆分策略

**原则：** 每个 Service 负责一个业务领域，FinanceRepository 变成薄代理层。

FinanceRepository 当前的方法分类：

| 领域 | 方法数 | 行数估计 |
|------|--------|----------|
| 账户 (Account) | ~15 | ~200 |
| 交易 (Transaction) | ~20 | ~300 |
| 预算 (Budget) | ~12 | ~250 |
| 分类 (Category) | ~8 | ~100 |
| 资产快照 (Asset) | ~15 | ~300 |
| 货币 (Currency) | ~10 | ~150 |
| 报表 (Report) | ~10 | ~200 |
| 导入导出 (Export) | ~6 | ~500 |
| 元数据 (Meta) | ~5 | ~50 |

### Task 3.1: 创建 CurrencyService

**Objective:** 抽出多币种汇率和转换逻辑

**Files:**
- Create: `lib/src/core/services/currency_service.dart`
- Modify: `lib/src/core/data/finance_repository.dart` (后续统一做)

**Step 1:** 创建 `lib/src/core/services/currency_service.dart`:
```dart
import 'dart:convert';

import '../utils/currency_formatter.dart';

class CurrencyService {
  static const _exchangeRatesMetaKey = 'exchange_rates_to_base_json';
  static const _currencyPriorityMetaKey = 'currency_priority_json';

  final Map<String, String> _metaValues;

  CurrencyService(this._metaValues);

  List<String> get currencyPriority {
    final raw = _metaValues[_currencyPriorityMetaKey];
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          final ordered = decoded
              .map((item) => normalizeCurrency('$item'))
              .where(supportedCurrencies.contains)
              .toSet()
              .toList();
          return [
            ...ordered,
            ...supportedCurrencies.where((item) => !ordered.contains(item)),
          ];
        }
      } catch (_) {}
    }
    return List.unmodifiable(supportedCurrencies);
  }

  String get baseCurrency => currencyPriority.first;

  String? get secondaryCurrency {
    final priority = currencyPriority;
    return priority.length < 2 ? null : priority[1];
  }

  Map<String, double> get exchangeRatesToBase {
    final raw = _metaValues[_exchangeRatesMetaKey];
    if (raw == null || raw.trim().isEmpty) {
      return _defaultRatesForBase(baseCurrency);
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final rates = {
          for (final entry in decoded.entries)
            normalizeCurrency(entry.key): entry.value is num
                ? (entry.value as num).toDouble()
                : double.tryParse('${entry.value}') ?? 1,
        };
        return normalizedExchangeRatesToBase(
          rates,
          baseCurrency: baseCurrency,
        );
      }
    } catch (_) {}
    return _defaultRatesForBase(baseCurrency);
  }

  double convertAmount({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) {
    return convertCurrencyAmount(
      amount: amount,
      fromCurrency: fromCurrency,
      toCurrency: toCurrency,
      ratesToBase: exchangeRatesToBase,
      baseCurrency: baseCurrency,
    );
  }

  double convertToBase(double amount, String currency) {
    return convertAmount(
      amount: amount,
      fromCurrency: currency,
      toCurrency: baseCurrency,
    );
  }

  double convertFromBase(double amount, String currency) {
    return convertAmount(
      amount: amount,
      fromCurrency: baseCurrency,
      toCurrency: currency,
    );
  }

  String conversionHintForAmount(double amount, String currency) {
    final normalized = normalizeCurrency(currency);
    final targetCurrency =
        normalized == baseCurrency ? secondaryCurrency : baseCurrency;
    if (targetCurrency == null || targetCurrency == normalized) {
      return '';
    }
    return formatConversionHint(
      amount: amount,
      fromCurrency: normalized,
      toCurrency: targetCurrency,
      ratesToBase: exchangeRatesToBase,
      baseCurrency: baseCurrency,
    );
  }

  List<String> _normalizeCurrencyPriority(List<String> currencies) {
    final seen = <String>{};
    final result = <String>[];
    for (final c in currencies) {
      final normalized = normalizeCurrency(c);
      if (supportedCurrencies.contains(normalized) && seen.add(normalized)) {
        result.add(normalized);
      }
    }
    for (final c in supportedCurrencies) {
      if (seen.add(c)) result.add(c);
    }
    return result;
  }

  Map<String, double> _defaultRatesForBase(String baseCurrency) {
    return {
      for (final c in supportedCurrencies)
        c: c == baseCurrency ? 1.0 : 1.0,
    };
  }
}
```

**Step 2:** Commit:
```bash
git add lib/src/core/services/currency_service.dart
git commit -m "feat: extract CurrencyService from FinanceRepository"
```

---

### Task 3.2: 创建 AccountService

**Objective:** 抽出账户 CRUD 和余额计算逻辑

**Files:**
- Create: `lib/src/core/services/account_service.dart`

**Step 1:** 创建文件，包含账户相关方法：
- `addAccount`, `updateExistingAccount`, `deleteAccountIfSafe`, `canDeleteAccount`
- `accountBalanceAt`, `accountBalanceAtBase`, `accountsByGroup`
- `reconciledMonthForAccount`, `isAccountReconciledForMonth`, `setAccountReconciledMonth`
- `displayTotalAssetsByGroup`, `totalAssets`, `displayTotalAssets`
- `investmentAccounts`

从 FinanceRepository 中提取这些方法，保留原始逻辑。

**Step 2:** Commit:
```bash
git add lib/src/core/services/account_service.dart
git commit -m "feat: extract AccountService from FinanceRepository"
```

---

### Task 3.3: 创建 TransactionService

**Objective:** 抽出交易 CRUD、模板、周期规则

**Files:**
- Create: `lib/src/core/services/transaction_service.dart`

**Step 1:** 包含：
- `addTransaction`, `addTransactions`, `updateExistingTransaction`, `deleteExistingTransaction`
- `transactionTemplates`, `addTransactionTemplate`, `deleteTransactionTemplate`
- `recurringTransactionRules`, `addRecurringTransactionRule`, `deleteRecurringTransactionRule`
- `generateRecurringTransactions`
- `recentTransactions`, `upcomingExpenseTransactions`

**Step 2:** Commit:
```bash
git add lib/src/core/services/transaction_service.dart
git commit -m "feat: extract TransactionService from FinanceRepository"
```

---

### Task 3.4: 创建 BudgetService

**Objective:** 抽出预算逻辑

**Files:**
- Create: `lib/src/core/services/budget_service.dart`

**Step 1:** 包含：
- `activeBudgetsForMonth`, `budgetMonthKeys`, `totalBudgetAmount`, `budgetAmountInBase`
- `effectiveBudgetForMonth`, `totalEffectiveBudgetForMonth`
- `totalBudgetExpenseForMonth`, `totalPlannedBudgetExpenseForMonth`
- `expenseTotalForCategory`, `actualExpenseTotalForCategory`, `plannedExpenseTotalForCategory`
- `addBudget`, `deleteExistingBudget`
- `reusableBudgets`

**Step 2:** Commit:
```bash
git add lib/src/core/services/budget_service.dart
git commit -m "feat: extract BudgetService from FinanceRepository"
```

---

### Task 3.5: 创建 AssetService

**Objective:** 抽出资产快照和投资逻辑

**Files:**
- Create: `lib/src/core/services/asset_service.dart`

**Step 1:** 包含：
- `addAssetSnapshot`, `updateExistingAssetSnapshot`, `deleteExistingAssetSnapshot`
- `latestSnapshotForAccount`, `latestSnapshotForAccountUpTo`
- `snapshotsForAccount`, `snapshotsForAccountUpTo`, `firstSnapshotForAccount`
- `snapshotCostBasis`, `snapshotRemainingCostBasis`, `snapshotUnrealizedPnl`, `snapshotPnlRatio`
- `totalAssetHistory`, `assetGoalSummaries`
- `addAssetGoal`, `updateAssetGoal`, `deleteAssetGoal`, `assetGoals`
- `totalAssetsAt`, `totalTargetAssets`

**Step 2:** Commit:
```bash
git add lib/src/core/services/asset_service.dart
git commit -m "feat: extract AssetService from FinanceRepository"
```

---

### Task 3.6: 创建 ReportService

**Objective:** 抽出报表和预测逻辑

**Files:**
- Create: `lib/src/core/services/report_service.dart`

**Step 1:** 包含：
- `monthlySummaries`, `categoryTotalsForMonths`
- `totalIncomeForMonth`, `totalExpenseForMonth`
- `plannedIncomeForMonth`, `plannedExpenseForMonth`
- `forecastSummary`, `totalFutureExpense`, `futureExpenseSummaries`
- `futureCashFlowProjection`, `creditCardPaymentReminders`

**Step 2:** Commit:
```bash
git add lib/src/core/services/report_service.dart
git commit -m "feat: extract ReportService from FinanceRepository"
```

---

### Task 3.7: 创建 ExportService

**Objective:** 抽出导入导出逻辑

**Files:**
- Create: `lib/src/core/services/export_service.dart`

**Step 1:** 包含：
- JSON 导出/导入
- AI Summary 导出
- Future Planning CSV 导出
- ImportPreview 逻辑

**Step 2:** Commit:
```bash
git add lib/src/core/services/export_service.dart
git commit -m "feat: extract ExportService from FinanceRepository"
```

---

### Task 3.8: 创建 CategoryService

**Objective:** 抽出分类逻辑

**Files:**
- Create: `lib/src/core/services/category_service.dart`

**Step 1:** 包含：
- `addCategory`, `updateExistingCategory`, `deleteCategoryIfSafe`, `canDeleteCategory`
- `categoryName`, `categoriesByType`, `sortedCategories`

**Step 2:** Commit:
```bash
git add lib/src/core/services/category_service.dart
git commit -m "feat: extract CategoryService from FinanceRepository"
```

---

### Task 3.9: 精简 FinanceRepository 为代理层

**Objective:** 将 FinanceRepository 从 2663 行精简到 ~300 行

**Files:**
- Modify: `lib/src/core/data/finance_repository.dart`

**Step 1:** FinanceRepository 保留：
- `load()`, `refresh()`, `preview()`
- 基础 getter (accounts, categories, budgets, transactions, snapshots, metaValues)
- 内部持有各个 Service 实例
- 委托方法（每个 Service 的方法都有一个一行的委托）
- 内部类 (ImportPreview, AccountBalanceTrace, TransactionTemplate, RecurringTransactionRule, CashFlowProjectionPoint, CreditCardPaymentReminder, AssetGoalHistoryPoint, AssetGoal, AssetGoalProgressSummary 等)

**Step 2:** 保持原有公开 API 不变，内部委托给 Service:
```dart
class FinanceRepository {
  FinanceRepository._({
    required this.database,
    required List<Account> accounts,
    // ...
  }) : _currencyService = CurrencyService(metaValues),
       _accountService = AccountService(accounts, transactions, snapshots, ...),
       // ...

  final CurrencyService _currencyService;
  final AccountService _accountService;
  // ...

  // 委托示例
  String get baseCurrency => _currencyService.baseCurrency;
  double convertToBase(double amount, String currency) =>
      _currencyService.convertToBase(amount, currency);
  // ...
}
```

**Step 3:** 运行测试确认:
```bash
cd ~/projects/finance-compass-app && flutter test
```

**Step 4:** Commit:
```bash
git add lib/src/core/data/finance_repository.dart
git commit -m "refactor: slim FinanceRepository to delegation layer (~300 lines)"
```

---

## Phase 4: 消灭 Callback Drilling

### Task 4.1: 创建 Repository Mutation Providers

**Objective:** 将 HomeScreen 的 20+ callback 转为 Riverpod 方法

**Files:**
- Create: `lib/src/core/providers/mutations/account_mutations.dart`
- Create: `lib/src/core/providers/mutations/transaction_mutations.dart`
- Create: `lib/src/core/providers/mutations/budget_mutations.dart`
- Create: `lib/src/core/providers/mutations/category_mutations.dart`
- Create: `lib/src/core/providers/mutations/asset_mutations.dart`
- Create: `lib/src/core/providers/mutations/export_mutations.dart`

**Step 1:** 以 `transaction_mutations.dart` 为例:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/finance_repository.dart';
import '../../models/transaction.dart';
import '../repository_provider.dart';

/// 交易相关操作的 Provider
final transactionMutationsProvider = Provider<TransactionMutations>((ref) {
  return TransactionMutations(ref);
});

class TransactionMutations {
  TransactionMutations(this._ref);

  final Ref _ref;

  FinanceRepository get _repo =>
      _ref.read(financeRepositoryProvider).requireValue;

  Future<void> addTransaction(FinanceTransaction transaction) async {
    final notifier = _ref.read(financeRepositoryProvider.notifier);
    final updated = await _repo.addTransaction(transaction);
    notifier.state = AsyncData(updated);
  }

  Future<void> addTransactions(List<FinanceTransaction> transactions) async {
    final notifier = _ref.read(financeRepositoryProvider.notifier);
    final updated = await _repo.addTransactions(transactions);
    notifier.state = AsyncData(updated);
  }

  Future<void> editTransaction(FinanceTransaction transaction) async {
    final notifier = _ref.read(financeRepositoryProvider.notifier);
    final updated = await _repo.updateExistingTransaction(transaction);
    notifier.state = AsyncData(updated);
  }

  Future<void> deleteTransaction(String id) async {
    final notifier = _ref.read(financeRepositoryProvider.notifier);
    final updated = await _repo.deleteExistingTransaction(id);
    notifier.state = AsyncData(updated);
  }
}
```

其他 Mutations 文件类似，各自负责各自的领域操作。

**Step 2:** Commit:
```bash
git add lib/src/core/providers/mutations/
git commit -m "feat: add Riverpod mutation providers for all domains"
```

---

### Task 4.2: 重构 HomeScreen — 移除 callback 参数

**Objective:** HomeScreen 从 441 行缩减到 ~150 行

**Files:**
- Modify: `lib/src/features/home/home_screen.dart`

**Step 1:** HomeScreen 改为 `ConsumerStatefulWidget`，不再持有 repository，不再传递 callback:
```dart
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
    final repoAsync = ref.watch(financeRepositoryProvider);

    return repoAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('加载失败: $error')),
      ),
      data: (repository) {
        return Scaffold(
          body: _buildBody(repository),
          bottomNavigationBar: _buildNavBar(),
        );
      },
    );
  }

  Widget _buildBody(FinanceRepository repository) {
    switch (selectedIndex) {
      case 0:
        return DashboardScreen(repository: repository);
      case 1:
        return TransactionsScreen(repository: repository);  // 无需 callback！
      case 2:
        return AccountsScreen(repository: repository);       // 无需 callback！
      case 3:
        return BudgetsScreen(repository: repository);
      case 4:
        return ReportsScreen(repository: repository);
      case 5:
        return SettingsScreen(
          repository: repository,
          settingsController: widget.settingsController,
        );
      default:
        return DashboardScreen(repository: repository);
    }
  }
}
```

**Step 2:** Commit:
```bash
git add lib/src/features/home/home_screen.dart
git commit -m "refactor: HomeScreen drops callback drilling, uses Riverpod"
```

---

### Task 4.3: 重构 TransactionsScreen — 自管理状态

**Objective:** TransactionsScreen 从 1406 行缩减到 ~600 行

**Files:**
- Modify: `lib/src/features/transactions/transactions_screen.dart`

**Step 1:** 改为 `ConsumerStatefulWidget`，移除 12 个 callback 参数，直接读取 mutation providers:
```dart
class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key, required this.repository});
  final FinanceRepository repository;

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  // ... 筛选状态保留

  @override
  Widget build(BuildContext context) {
    final mutations = ref.read(transactionMutationsProvider);
    final categoryMutations = ref.read(categoryMutationsProvider);
    // 直接用 mutations 调用方法，不再需要 widget.onXxx
  }
}
```

**Step 2:** Commit:
```bash
git add lib/src/features/transactions/transactions_screen.dart
git commit -m "refactor: TransactionsScreen uses Riverpod, drops callbacks"
```

---

### Task 4.4: 重构 AccountsScreen — 同理移除 callback

**Objective:** AccountsScreen 从 1086 行缩减到 ~500 行

**Files:**
- Modify: `lib/src/features/accounts/accounts_screen.dart`

**Step 1:** 同样改为 ConsumerStatefulWidget，移除 10 个 callback。

**Step 2:** Commit:
```bash
git add lib/src/features/accounts/accounts_screen.dart
git commit -m "refactor: AccountsScreen uses Riverpod, drops callbacks"
```

---

### Task 4.5: 重构其余 Screen (BudgetsScreen, SettingsScreen)

**Objective:** 统一迁移到 Riverpod

**Files:**
- Modify: `lib/src/features/budgets/budgets_screen.dart`
- Modify: `lib/src/features/settings/settings_screen.dart`

**Step 1:** 同理移除 callback，使用 mutation providers。

**Step 2:** Commit:
```bash
git add lib/src/features/budgets/ lib/src/features/settings/
git commit -m "refactor: BudgetsScreen & SettingsScreen use Riverpod"
```

---

## Phase 5: 清理和验证

### Task 5.1: 删除旧 DatabaseProvider

**Objective:** 移除手写的 singleton，全部用 Riverpod

**Files:**
- Delete: `lib/src/core/database/database_provider.dart`
- Update 所有引用旧 DatabaseProvider 的文件

**Step 1:** 搜索并替换:
```bash
grep -rn "DatabaseProvider" lib/
```

**Step 2:** Commit:
```bash
git add -A
git commit -m "chore: remove old DatabaseProvider singleton"
```

---

### Task 5.2: 运行全部测试

**Objective:** 确保重构后功能不退化

**Step 1:**
```bash
cd ~/projects/finance-compass-app && flutter test
```

**Step 2:** 修复失败的测试。

---

### Task 5.3: flutter analyze + 清理

**Objective:** 消除 analyzer warnings

**Step 1:**
```bash
cd ~/projects/finance-compass-app && flutter analyze
```

**Step 2:** 修复所有 warning。

**Step 3:** 最终 commit:
```bash
git add -A
git commit -m "chore: clean up analyzer warnings after refactor"
```

---

## 最终目录结构

```
lib/
├── main.dart                              # ProviderScope 包裹
├── src/
│   ├── app.dart                           # ConsumerWidget
│   ├── core/
│   │   ├── data/
│   │   │   ├── finance_repository.dart    # ~300行 (代理层)
│   │   │   └── sample_data.dart           # 不变
│   │   ├── database/
│   │   │   ├── app_database.dart          # 不变
│   │   │   ├── app_database.g.dart        # 自动生成
│   │   │   ├── enum_codec.dart
│   │   │   ├── finance_seed_service.dart
│   │   │   └── tables/                    # 不变
│   │   ├── models/                        # 不变
│   │   ├── providers/                     # 🆕 Riverpod Providers
│   │   │   ├── database_provider.dart
│   │   │   ├── repository_provider.dart
│   │   │   ├── settings_provider.dart
│   │   │   └── mutations/
│   │   │       ├── account_mutations.dart
│   │   │       ├── transaction_mutations.dart
│   │   │       ├── budget_mutations.dart
│   │   │       ├── category_mutations.dart
│   │   │       ├── asset_mutations.dart
│   │   │       └── export_mutations.dart
│   │   ├── services/                      # 🆕 拆分后的 Service
│   │   │   ├── account_service.dart
│   │   │   ├── asset_service.dart
│   │   │   ├── budget_service.dart
│   │   │   ├── category_service.dart
│   │   │   ├── currency_service.dart
│   │   │   ├── export_service.dart
│   │   │   ├── report_service.dart
│   │   │   └── transaction_service.dart
│   │   ├── settings/                      # 不变
│   │   ├── theme/                         # 不变
│   │   └── utils/                         # 不变
│   └── features/                          # 瘦身后的 Screens
│       ├── accounts/
│       ├── budgets/
│       ├── categories/
│       ├── dashboard/
│       ├── home/                          # 大幅精简
│       ├── reports/
│       ├── settings/
│       ├── shared/
│       └── transactions/                  # 移除 callback
```

---

## 风险和注意事项

1. **渐进式迁移** — 每个 Phase 独立可测试，不要一次性改完
2. **FinanceRepository 公开 API 保持不变** — 重构期间，下游 Screen 不需要一次性全部改
3. **先 Phase 2-3（Riverpod + Service 拆分），再 Phase 4（消灭 callback）** — 这样可以逐步验证
4. **测试覆盖率** — 重构前先确认现有测试全部通过，作为 baseline
5. **app_database.dart 和 tables/ 完全不动** — Drift 层保持稳定
6. **models/ 完全不动** — 数据模型保持不变
