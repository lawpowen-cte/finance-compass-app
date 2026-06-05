# Finance Compass Codex 项目速查与 UI 评审

最后分析：2026-06-04  
代码基准：`c623a49`

这份文档是给以后 Codex 快速接手用的工作地图。它不是完整需求文档，而是回答三个问题：

- 用户说要改某个功能时，先找哪些文件。
- 业务逻辑、状态刷新、数据库写入之间怎么串起来。
- 当前各界面 UI 哪里值得优化，优先改什么。

## 1. 快速结论

这是一个 Flutter + Riverpod + Drift 的本地优先个人财务应用。

主要入口：

- `lib/main.dart`：初始化 Flutter、加载 `AppSettingsController`、挂载 `ProviderScope`。
- `lib/src/app.dart`：创建 `MaterialApp`，应用 `buildFinanceTheme()`，进入 `HomeScreen`。
- `lib/src/features/home/home_screen.dart`：主 tab 容器，加载 `financeRepositoryProvider` 后把同一个 `FinanceRepository` 传给 6 个主界面。

主界面顺序：

- 总览：`DashboardScreen`
- 账户：`AccountsScreen`
- 交易：`TransactionsScreen`
- 预算：`BudgetsScreen`
- 报表：`ReportsScreen`
- 设置：`SettingsScreen`

当前实际数据流：

```text
UI Screen
  -> ref.read(xxxMutationsProvider.notifier).doSomething()
  -> mutation provider 读取 financeRepositoryProvider
  -> FinanceRepository 执行业务逻辑和数据库写入
  -> mutation provider setRepository(updated)
  -> HomeScreen 重新传入新的 repository
  -> Screen rebuild
```

重要注意：

- `lib/src/core/services/` 里已经有服务拆分文件，但当前除 `AiAnalysisService` 外，UI 和 mutation 主要还是走 `FinanceRepository`。
- `FinanceRepository` 目前是最大真实业务入口，约 2400 行。以后改核心规则时，先查 repository，再决定是否同步或迁移到 `services/`。
- `lib/src/core/database/app_database.g.dart` 是 Drift 生成文件，不要手改。

## 2. 目录职责

| 目录 | 作用 | 先看时机 |
| --- | --- | --- |
| `lib/src/features/` | UI 层，按主界面拆分 | 用户说“页面、按钮、列表、表单、筛选、展示” |
| `lib/src/core/data/finance_repository.dart` | 当前核心业务入口，含汇率、余额、预算、导入导出、模板、周期规则 | 用户说“计算不对、数据规则、金额、余额、预算、导出内容” |
| `lib/src/core/providers/` | Riverpod provider 和 mutation | 用户说“保存后没刷新、状态不同步、异步加载” |
| `lib/src/core/database/` | Drift 数据库、表、迁移、余额副作用 | 用户说“新增字段、迁移、数据库、导入覆盖、余额写入” |
| `lib/src/core/models/` | 纯数据模型和 enum | 用户说“新增类型、状态、字段” |
| `lib/src/core/theme/` | 全局 ThemeData 和 palette | 用户说“整体风格、深色主题、颜色、字体、按钮” |
| `lib/src/core/settings/` | 主题设置持久化 | 用户说“主题选择保存、设置项” |
| `lib/src/core/utils/` | 月份、ID、金额格式化 | 用户说“金额显示、币种标签、月份范围” |
| `test/` | 关键规则测试 | 修改交易、汇率、周期、表单、AI 时先找这里 |

## 3. 功能定位表

| 要改的功能 | UI 入口 | 核心逻辑入口 | 写入/状态入口 | 常看测试 |
| --- | --- | --- | --- | --- |
| 主导航、tab 顺序 | `features/home/home_screen.dart` | 无 | `financeRepositoryProvider` 加载在这里 | `widget_test.dart` |
| 全局主题 | `core/theme/finance_theme.dart` | `core/settings/app_settings_controller.dart` | `SettingsScreen` 调用 controller | 需要手动 UI 验证 |
| 总览指标 | `features/dashboard/dashboard_screen.dart` | `FinanceRepository.totalIncomeForMonth`, `totalExpenseForMonth`, `displayTotalAssetsByGroup`, `futureCashFlowProjection` | 多数只读 | 可加 repository 规则测试 |
| 月度对比/预测 | `dashboard_screen.dart` | `monthlySummaries`, `futureExpenseSummaries`, `forecastSummary` | 多数只读 | 可加 report 规则测试 |
| 账户列表 | `features/accounts/accounts_screen.dart` | `accountsByGroup`, `displayTotalAssetsByGroup`, `accountBalanceAt` | `account_mutations.dart` | `account_trace_test.dart` |
| 账户详情 | `features/accounts/account_detail_screen.dart` | `snapshotsForAccount`, `investmentFlowSummaryForAccount` | `asset_mutations.dart` | `account_trace_test.dart` |
| 账户表单 | `features/accounts/account_form_dialog.dart` | `Account` model | `account_mutations.dart` | 可加表单 widget test |
| 资产快照 | `asset_snapshot_form_dialog.dart`, `account_detail_screen.dart`, `accounts_screen.dart` | `latestSnapshotForAccount`, `costBasisForAccount`, `cashBalanceForAccount` | `asset_mutations.dart`, `app_database.dart` 快照写入 | `account_trace_test.dart` |
| 资产目标 | `accounts_screen.dart`, `reports_screen.dart` | `assetGoals`, `assetGoalSummaries`, `_syncAssetGoalReachedAt` | `account_mutations.dart`, meta key `asset_goals_json` | 可加 goal 规则测试 |
| 交易列表 | `features/transactions/transactions_screen.dart` | 过滤逻辑在 screen 内，金额转换走 repository | `transaction_mutations.dart` | `cross_currency_transfer_test.dart` |
| 交易表单 | `features/transactions/transaction_form_dialog.dart` | `FinanceTransaction` model, currency helpers | `transaction_mutations.dart` | `transaction_form_dialog_test.dart` |
| 交易模板 | `transactions_screen.dart` | `transactionTemplates`, `addTransactionTemplate`, `deleteTransactionTemplate` | `transaction_mutations.dart`, meta key `transaction_templates_json` | `transaction_template_test.dart` |
| 周期交易 | `transactions_screen.dart` | `recurringTransactionRules`, `generateRecurringTransactions` | `transaction_mutations.dart`, meta key `recurring_transaction_rules_json` | `recurring_transaction_rule_test.dart` |
| 类别管理 | `transactions_screen.dart`, `category_form_dialog.dart` | `sortedCategories`, `categoriesByType` | `category_mutations.dart` | 可加 category delete test |
| 预算页 | `features/budgets/budgets_screen.dart`, `budget_form_dialog.dart` | `activeBudgetsForMonth`, `effectiveBudgetForMonth`, `totalEffectiveBudgetForMonth` | `budget_mutations.dart` | 可加 budget rollover test |
| 报表 | `features/reports/reports_screen.dart` | `categoryTotalsForMonths`, `totalAssets`, `assetGoalSummaries` | 多数只读 | 可加 report 规则测试 |
| AI 分析 | `reports_screen.dart`, `settings_screen.dart` | `providers/ai_analysis_provider.dart`, `services/ai_analysis_service.dart` | `saveAiGatewayUrl`, `financeRepositoryProvider` invalidate | `ai_analysis_integration_test.dart` |
| 汇率/币种优先级 | `settings_screen.dart`, account/transaction forms | `currencyPriority`, `exchangeRatesToBase`, `convertAmount`, `conversionHintForAmount` | `account_mutations.updateExchangeRates` | `currency_formatter_test.dart`, `cross_currency_transfer_test.dart` |
| JSON 导入导出 | `settings_screen.dart` | `buildJsonSnapshotPayload`, `importJsonSnapshot`, `previewImportJson` | `export_mutations.dart`, `app_database.replaceAllWithSeedData` | 可加 import/export roundtrip test |
| CSV/AI 摘要导出 | `settings_screen.dart` | `buildAiSummaryPayload`, `exportFuturePlanningCsvBytes` | `export_mutations.dart` | `ai_analysis_integration_test.dart` 可参考 payload |

## 4. 常见修改路线

### 4.1 新增数据库字段

改这些位置：

- `lib/src/core/models/<model>.dart`
- `lib/src/core/database/tables/<table>.dart`
- `lib/src/core/database/app_database.dart`
  - `schemaVersion`
  - `migration.onUpgrade`
  - fetch/insert/update/import/export mapping
- `lib/src/core/data/finance_repository.dart`
  - JSON 导入导出
  - AI summary 如需暴露
  - 相关计算逻辑
- 对应 form dialog 和列表展示 screen
- 相关测试

最后运行：

```powershell
flutter pub run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

### 4.2 改余额或交易影响规则

优先看：

- `FinanceTransaction.affectsBalance`
- `FinanceRepository.transactionDeltaForAccount`
- `FinanceRepository._accountBalanceAt`
- `AppDatabase.insertTransaction`
- `AppDatabase.updateTransaction`
- `AppDatabase.deleteTransaction`

高风险点：

- planned 不应影响真实余额。
- transfer 同时影响 `accountId` 和 `toAccountId`。
- 跨币种转账的 `amount/currency` 和 `toAmount/toCurrency` 不能混用。
- 投资/退休账户会受到资产快照、cost basis、cash balance、adjustment 的影响。

推荐测试：

- `cross_currency_transfer_test.dart`
- `account_trace_test.dart`
- 需要时新增 update/delete transaction 的余额回滚测试。

### 4.3 改预算规则

优先看：

- `FinanceRepository.activeBudgetsForMonth`
- `FinanceRepository.effectiveBudgetForMonth`
- `FinanceRepository.totalBudgetExpenseForMonth`
- `FinanceRepository.totalPlannedBudgetExpenseForMonth`
- `features/budgets/budgets_screen.dart`
- `features/dashboard/dashboard_screen.dart` 里的预算监控
- `features/reports/reports_screen.dart` 里的预算执行

注意：

- 预算规则是 reusable rule，同一分类取目标月份之前最新规则。
- rollover 包含正结转和负结转。
- 实际支出和预计支出在 UI 上需要分开展示。

### 4.4 改汇率或币种

优先看：

- `core/utils/currency_formatter.dart`
- `FinanceRepository.currencyPriority`
- `FinanceRepository.exchangeRatesToBase`
- `FinanceRepository.convertAmount`
- `features/settings/settings_screen.dart`
- `features/accounts/account_form_dialog.dart`
- `features/transactions/transaction_form_dialog.dart`

注意：

- 主币种是 `currencyPriority.first`。
- 第二币种用于换算提示。
- 账户和交易都带币种。
- 修改换算公式后跑跨币种测试。

### 4.5 改 AI 分析

优先看：

- `core/providers/ai_analysis_provider.dart`
- `core/services/ai_analysis_service.dart`
- `features/reports/reports_screen.dart` 的 `_AiAnalysisButton` 和 `_AiResultDisplay`
- `features/settings/settings_screen.dart` 的 AI 网关配置
- `FinanceRepository.aiGatewayUrl`

注意：

- 网关地址存在 `app_meta.ai_gateway_url`。
- 当前请求发到 `$gatewayUrl/api/analyze`。
- 返回字段当前读取 `summary`。
- 如果网关返回结构改变，优先改 `AiAnalysisService.generateAnalysis`。

### 4.6 改一个页面 UI

先用这些命令定位：

```powershell
rg -n "ScreenHeader|SectionCard|Dropdown|SegmentedButton|FilledButton|IconButton|ListView|Wrap" lib/src/features/<feature>
rg -n "class _|Widget build" lib/src/features/<feature>
```

通常先改：

- 页面 build 方法里的 section 顺序和控件布局。
- 页面底部的私有 widget，例如 `_MetricCard`, `_BudgetTile`, `_KpiCard`。
- `features/shared/` 里的共享组件，如果多个页面都需要统一。

## 5. 文件大小与维护风险

| 文件 | 行数级别 | 风险说明 |
| --- | --- | --- |
| `core/data/finance_repository.dart` | 2400+ | 核心业务集中，容易重复逻辑，修改要配测试 |
| `features/transactions/transactions_screen.dart` | 1300+ | 筛选、列表、模板、周期、类别都在一个文件 |
| `features/accounts/accounts_screen.dart` | 1000+ | 账户列表、目标、追溯、快照摘要都在一个文件 |
| `features/reports/reports_screen.dart` | 900+ | 报表筛选、图表、AI 分析混在一个文件 |
| `features/dashboard/dashboard_screen.dart` | 800+ | 指标、预算、预测、现金流、最近交易混在一个文件 |
| `features/settings/settings_screen.dart` | 750+ | 主题、汇率、导入导出、AI 网关在一个长页面 |

建议以后渐进拆分，不要一次性大重构。优先把私有 widget 移到同 feature 的 `widgets/` 子目录，业务逻辑先保持行为不变。

## 6. UI 评审总览

### 全局问题

1. 底部导航隐藏 label，可发现性偏低。  
   当前 `NavigationBar` 设置 `alwaysHide`，移动端用户很难只靠图标记住 6 个模块。建议至少显示选中项 label，或者显示短 label。

2. UI 组件风格不完全统一。  
   多数页面用 `SectionCard`，预算页用原生 `Card`，报表页有自定义 KPI card。建议沉淀 `FinanceMetricCard`, `FinanceStatusChip`, `FinanceFilterBar`。

3. 筛选区占据首屏太多。  
   交易和报表尤其明显。建议改为折叠筛选区 + active filter chips，默认只露出关键筛选。

4. 硬编码颜色较多。  
   Dashboard、Reports、Budgets、Transactions 里有大量 `Color(0x...)` 和 `Colors.grey[...]`。建议统一走 `FinanceThemePalette` 的语义色，例如 income、expense、warning、success、muted。

5. 巨型页面文件导致 UI 改动定位慢。  
   大页面内混合数据计算、交互动作、私有 widget。建议按 section 拆成子 widget，先拆纯展示组件。

6. 图表交互不足。  
   当前多为固定高度 CustomPaint 或静态 bar。建议加 tooltip、横向滚动、空状态说明、选中月份联动，尤其是 12 个月报表。

7. 复杂表单仍是 `AlertDialog`。  
   `TransactionFormDialog` 信息量很大，手机上容易拥挤。建议手机端用 full-screen dialog 或 modal sheet，桌面端保留固定宽度 dialog。

8. 文本密度和信息层级需要再压一层。  
   财务 app 适合高密度，但现在部分 section 标题、说明、指标和列表混在同一个视觉重量。建议更明确地区分“主要数字、次要说明、状态标签、操作”。

### 总览页

位置：`lib/src/features/dashboard/dashboard_screen.dart`

优点：

- 一页覆盖现金、信用、投资、退休、收支、预算、预测、现金流。
- 时间筛选已经会影响 period 计算，逻辑实用。

建议：

- 9 个指标卡首屏太重。建议把“净资产、期间结余、期间收入、期间支出”作为首屏主指标，其余资产分组折叠或放第二行。
- 年/月两个 dropdown 可改为 segmented quick range 加月份选择，例如“本月、上月、今年、全部”。
- `MonthlyMatrix` 在多月份时横向空间紧张，可改为 mini bar chart 或横向滚动表。
- “预算监控”建议按风险排序：超支、接近阈值、正常、无支出。
- “未来支出、未来 3 个月预留、未来现金流、信用卡提醒”可合并成一个“未来现金流”区块，减少 section 数。

### 账户页

位置：`lib/src/features/accounts/accounts_screen.dart`

优点：

- 截止月份、余额追溯、对账状态、资产目标这些财务场景很有价值。
- 投资/退休账户快照摘要与小趋势线很贴合使用场景。

建议：

- 顶部三个 icon action 在移动端含义不够直观。建议保留 icon，但在宽屏加文字按钮，或加一个主 FAB 专门新增账户。
- 账户分组列表较长时，建议每个 report group 可折叠，并把组总额放在醒目右侧。
- “资产目标”也在报表页出现，建议抽成共享 goal progress 组件，避免两边视觉和规则不一致。
- 对账状态很好，但可以加“仅看未对账”筛选，帮助月末检查。
- 快照摘要对普通现金账户可能不必要，建议只对 investment/retirement 展开更复杂信息。

### 交易页

位置：`lib/src/features/transactions/transactions_screen.dart`

优点：

- 功能完整：模板、周期交易、筛选、类别管理、交易列表、复用新增。
- 交易行已经做了紧凑化，适合高频录入。

建议：

- 筛选表单太高。建议默认收起为一行 active chips，例如“2026-06 至 2026-06 · 全账户 · 支出”，点击进入筛选面板。
- 模板和周期交易放在同一个 SectionCard，长按操作较隐藏。建议每个 chip 右侧有小菜单，或拆成两个 tab。
- 类别管理放在交易页中段，会打断记账流。建议移到设置或独立管理入口，交易页只保留“新增类别”快捷入口。
- 交易行需要更明确显示 transfer 方向，比如 “A -> B”，目前主要显示转出账户和 meta chip。
- 金额、日期、菜单在小屏可能过密。建议给交易行稳定高度，并把日期和状态做成右侧小 column。
- 可以加搜索框，按说明、商户、账户、类别筛选。

### 预算页

位置：`lib/src/features/budgets/budgets_screen.dart`

优点：

- 有月预算、实际、预计、预算池余额，且预算 tile 支持展开看年度数据。
- rollover 用符号提示，信息密度高。

建议：

- 预算页使用原生 `Card`，和其他页面的 `SectionCard` 不一致。建议统一。
- 月份选项当前只生成当前月起 7 个月，建议合并 repository 中已有预算月份，支持回看历史预算。
- rollover 的 `↻` 符号建议改为带 tooltip 的状态 chip，例如“结转”。
- 删除预算目前没有显式二次确认，建议加确认 dialog。
- `_InlineBudgetSummary` 在窄屏可能挤压类别名，建议在小屏换行显示。

### 报表页

位置：`lib/src/features/reports/reports_screen.dart`

优点：

- 报表范围、单月/累计、已发生/含预计都已覆盖。
- AI 分析入口和结果展示已经接入全局 provider。

建议：

- 标题里有 emoji，而其他页面用纯文字和 Material icon。建议统一为 icon + 文本或纯文本。
- range dropdown 放在 header action，和后面的 segmented controls 分散。建议组成统一 filter bar。
- `_KpiCard` 用 `MediaQuery` 直接计算宽度，放进不同父容器时不够稳。建议用 `LayoutBuilder`。
- 12 个月柱状图每月只有很窄空间，建议横向滚动或按季度聚合。
- 图表颜色硬编码，深色主题下灰色网格和文字可能对比不足。建议走 palette。
- AI result 当前插在顶部，建议改为状态 banner + 可展开结果面板，避免占据常规报表流。

### 设置页

位置：`lib/src/features/settings/settings_screen.dart`

优点：

- 主题、汇率、导入导出、AI 网关都集中，功能入口清晰。
- 汇率优先级用拖拽排序，很符合“主币种/次币种”的模型。

建议：

- 页面较长，建议分成 “外观”、“货币”、“数据”、“AI” 四段，或做顶部 tab。
- 主题 chip 固定 3 列，在窄屏/大字模式下可能挤。建议用最小宽度 + Wrap 自适应。
- 导出成功 snackbar 包含长路径，不易阅读。建议改为 dialog 或 bottom sheet，提供“打开文件”按钮。
- 导入、写入示例资料这类覆盖数据动作建议使用 danger 风格，并提示先导出备份。
- AI 网关建议增加“测试连接”按钮，保存前校验 URL 和 `/health` 或 `/api/analyze` 可达性。

## 7. UI 优化优先级

### P0：低风险，高收益

- 底部导航显示 label，至少显示选中项。
- 把预算页主容器统一成 `SectionCard`。
- 预算删除加确认 dialog。
- 交易筛选区增加收起状态和 active filter chips。
- 报表标题去掉 emoji，统一视觉语言。
- 把常用颜色改成 theme semantic getter，先从收入、支出、warning、success 开始。

### P1：中等改动

- 抽共享组件：`FinanceMetricCard`, `FinanceFilterBar`, `FinanceStatusChip`, `FinanceActionMenuButton`。
- 拆 `TransactionsScreen`：筛选、模板/周期、类别管理、交易列表各自成 widget。
- 拆 `AccountsScreen`：目标区、账户组、账户 tile、追溯 dialog 各自成 widget。
- 报表 chart 改用 `LayoutBuilder` 和可横向滚动月份轴。
- 交易表单在手机端改 full-screen dialog。

### P2：体验增强

- 交易页加搜索、批量操作、按账户/类别快速分组。
- Dashboard 支持自定义首页卡片顺序。
- 图表支持点击月份/分类，联动筛选到交易列表。
- 设置页加 AI 网关测试连接。
- 导入导出加最近备份记录和恢复确认流程。

## 8. 推荐验证命令

常规改动：

```powershell
flutter analyze
flutter test
```

数据库 schema 改动：

```powershell
flutter pub run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

只改 UI：

```powershell
flutter analyze
flutter test test/widget_test.dart
```

交易/汇率/余额：

```powershell
flutter test test/cross_currency_transfer_test.dart
flutter test test/account_trace_test.dart
flutter test test/transaction_form_dialog_test.dart
```

周期交易/模板：

```powershell
flutter test test/recurring_transaction_rule_test.dart
flutter test test/transaction_template_test.dart
```

AI 分析：

```powershell
flutter test test/ai_analysis_integration_test.dart
```

## 9. 下次接手时的最短流程

1. 先读用户说的页面或功能名，对照第 3 节定位文件。
2. 用 `rg` 找中文 label、方法名或 meta key。
3. 如果是保存后刷新问题，先看 mutation provider 有没有 `setRepository(updated)` 或 invalidate。
4. 如果是金额/余额/预算问题，优先查 `FinanceRepository`，再查 `AppDatabase` 写入副作用。
5. 如果是 UI 问题，先看对应 screen 内私有 widget，再决定是否抽到 `features/shared/`。
6. 修改后按第 8 节跑最小测试集。

## 10. 待更新事项

### 6. 组件抽取包

状态：已完成，2026-06-05。

目标：为后续维护提速，不一定第一轮做；优先保证行为不变，再逐步替换重复 UI。

已抽取：

- `lib/src/features/shared/finance_metric_card.dart`
  - `FinanceMetricCard`
  - `FinanceMetricGrid`
- `lib/src/features/shared/finance_filter_bar.dart`
  - `FinanceFilterBar`
  - `FinanceFilterChipData`
- `lib/src/features/shared/finance_status_chip.dart`
  - `FinanceStatusChip`
- `lib/src/features/shared/finance_action_menu_button.dart`
  - `FinanceActionMenuButton`
  - `FinanceActionMenuItem`

已接入页面：

- `TransactionsScreen`：筛选条、active filter chips、结果汇总指标、交易/模板/周期菜单、状态 chip。
- `AccountsScreen`：账户操作菜单、对账状态 chip。
- `ReportsScreen`：KPI 总览指标。
- `BudgetsScreen`：预算概览、展开指标、预算操作菜单。

后续继续拆分原则：

- 第一轮已只抽纯展示组件和轻状态组件，没有搬业务计算。
- 之后每次抽一个页面 section，例如账户目标区、报表趋势图、交易类别管理。
- 抽取后优先放在 `lib/src/features/shared/`；如果只服务单页，先放该 feature 的 `widgets/` 子目录。
