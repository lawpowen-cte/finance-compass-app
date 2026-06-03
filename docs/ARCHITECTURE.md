# Finance Compass — 软件架构设计文档

> 最后更新：2026-06-03
> 版本：0.3.0 (AI Gateway 版)

## 1. 项目概览

Finance Compass 是一个跨平台个人理财 Flutter 应用，核心功能包括：
- 多账户记账（现金/银行/电子钱包/信用卡/投资/养老金）
- 多币种支持（MYR/USD/CNY/TWD）+ 汇率转换
- 预算管理 + rollover
- 资产快照 + 投资跟踪
- 周期交易 + 快速模板
- 报表 + 预测 + 现金流
- JSON 导入导出 + AI 摘要
- AI 财务分析（通过 FastAPI 网关代理调用大模型）

**技术栈**：Flutter 3.29 / Dart 3.7 / Drift (SQLite) / Riverpod

---

## 2. 目录结构

```
lib/
├── main.dart                          # 入口：ProviderScope + AppSettingsController
├── src/
│   ├── app.dart                       # MaterialApp (ConsumerWidget)
│   │
│   ├── core/                          # 核心层（数据、业务逻辑、工具）
│   │   ├── data/
│   │   │   ├── finance_repository.dart   # 仓库代理层（~300行，委托给 Service）
│   │   │   ├── data_migration.dart       # 旧版本数据迁移
│   │   │   └── sample_data.dart          # 示例数据
│   │   │
│   │   ├── database/
│   │   │   ├── app_database.dart         # Drift 数据库定义 + 查询
│   │   │   ├── app_database.g.dart       # Drift 自动生成
│   │   │   ├── enum_codec.dart           # 枚举编解码
│   │   │   ├── finance_seed_service.dart # 种子数据
│   │   │   └── tables/                   # Drift 表定义
│   │   │       ├── accounts_table.dart
│   │   │       ├── categories_table.dart
│   │   │       ├── transactions_table.dart
│   │   │       ├── budgets_table.dart
│   │   │       ├── asset_snapshots_table.dart
│   │   │       └── app_meta_table.dart
│   │   │
│   │   ├── models/                      # 纯数据模型（无依赖）
│   │   │   ├── account.dart              # Account, AccountType, ReportGroup
│   │   │   ├── category.dart             # Category, CategoryType
│   │   │   ├── transaction.dart          # FinanceTransaction, TransactionType, TransactionStatus
│   │   │   ├── budget.dart               # Budget
│   │   │   ├── asset_snapshot.dart       # AssetSnapshot
│   │   │   ├── monthly_summary.dart      # MonthlySummary
│   │   │   └── forecast_summary.dart     # ForecastSummary
│   │   │
│   │   ├── services/                    # 业务逻辑层（从 Repository 拆分）
│   │   │   ├── currency_service.dart     # 汇率、多币种转换
│   │   │   ├── account_service.dart      # 账户 CRUD、余额、对账
│   │   │   ├── transaction_service.dart  # 交易 CRUD、模板、周期规则
│   │   │   ├── budget_service.dart       # 预算 CRUD、rollover、有效余额
│   │   │   ├── category_service.dart     # 分类 CRUD
│   │   │   ├── asset_service.dart        # 资产快照、投资跟踪、目标
│   │   │   ├── report_service.dart       # 月度汇总、预测、现金流
│   │   │   ├── export_service.dart       # JSON 导入导出、AI 摘要、CSV
│   │   │   └── ai_analysis_service.dart  # AI 分析（调用网关）
│   │   │   └── service_helpers.dart      # 共享工具函数
│   │   │
│   │   ├── providers/                   # Riverpod 状态管理
│   │   │   ├── database_provider.dart    # AppDatabase 单例
│   │   │   ├── repository_provider.dart  # FinanceRepository AsyncNotifier
│   │   │   ├── settings_provider.dart    # AppSettingsController
│   │   │   └── mutations/               # 写操作（触发 Repository 刷新）
│   │   │       ├── account_mutations.dart
│   │   │       ├── transaction_mutations.dart
│   │   │       ├── budget_mutations.dart
│   │   │       ├── category_mutations.dart
│   │   │       ├── asset_mutations.dart
│   │   │       └── export_mutations.dart
│   │   │
│   │   ├── settings/
│   │   │   ├── app_settings_controller.dart  # 主题设置（ChangeNotifier）
│   │   │   └── app_theme_style.dart          # 主题枚举
│   │   │
│   │   ├── theme/
│   │   │   └── finance_theme.dart        # 主题定义（7 种配色）
│   │   │
│   │   └── utils/
│   │       ├── currency_formatter.dart   # formatMoney, formatMoneyValue, normalizeCurrency
│   │       ├── id_generator.dart         # UUID 生成
│   │       ├── month_key.dart            # "YYYY-MM" 格式工具
│   │       └── month_range.dart          # 月份范围生成
│   │
│   └── features/                        # UI 层（Screen + Widget）
│       ├── home/
│       │   └── home_screen.dart          # 主框架：BottomNav + 页面切换
│       ├── dashboard/
│       │   └── dashboard_screen.dart     # 总览：指标卡片、预算、预测
│       ├── transactions/
│       │   ├── transactions_screen.dart  # 交易列表 + 筛选 + 模板/周期
│       │   └── transaction_form_dialog.dart
│       ├── accounts/
│       │   ├── accounts_screen.dart      # 账户列表 + 资产快照
│       │   ├── account_detail_screen.dart
│       │   ├── account_form_dialog.dart
│       │   └── asset_snapshot_form_dialog.dart
│       ├── budgets/
│       │   ├── budgets_screen.dart       # 预算列表（按月份合并）
│       │   └── budget_form_dialog.dart
│       ├── categories/
│       │   └── category_form_dialog.dart
│       ├── reports/
│       │   └── reports_screen.dart       # 报表（折线/饼图/表格）
│       ├── settings/
│       │   └── settings_screen.dart      # 设置（主题/汇率/导入导出）
│       └── shared/
│           ├── finance_form_fields.dart  # 共享表单组件
│           ├── screen_header.dart        # 页面标题栏
│           ├── section_card.dart         # 卡片容器
│           └── simple_charts.dart        # 自绘图表
```

---

## 3. 架构模式

### 3.1 数据流

```
用户操作 → Screen (ConsumerStatefulWidget)
         → ref.read(xxxMutationsProvider.notifier).doSomething()
         → Mutations Provider 调用 FinanceRepository 方法
         → Repository 委托给对应 Service
         → Service 执行业务逻辑 + 写入 AppDatabase (Drift)
         → Mutations Provider 更新 financeRepositoryProvider.state
         → ref.watch 自动刷新所有相关 Screen
```

### 3.2 Riverpod Provider 层级

| Provider | 类型 | 用途 |
|----------|------|------|
| `appDatabaseProvider` | `Provider<AppDatabase>` | 数据库单例 |
| `financeRepositoryProvider` | `AsyncNotifierProvider<..., FinanceRepository>` | 异步加载 + 刷新 |
| `appSettingsProvider` | `AsyncNotifierProvider<..., AppSettingsController>` | 主题设置 |
| `accountMutationsProvider` | `Notifier<void>` | 账户写操作 |
| `transactionMutationsProvider` | `Notifier<void>` | 交易写操作 |
| `budgetMutationsProvider` | `Notifier<void>` | 预算写操作 |
| `categoryMutationsProvider` | `Notifier<void>` | 分类写操作 |
| `assetMutationsProvider` | `Notifier<void>` | 资产写操作 |
| `exportMutationsProvider` | `Notifier<void>` | 导入导出操作 |

### 3.3 Mutation 模式

所有写操作遵循同一模式：

```dart
class XxxMutations extends Notifier<void> {
  @override
  void build() {}  // 无状态

  Future<void> addXxx(Xxx item) async {
    final notifier = ref.read(financeRepositoryProvider.notifier);
    final repo = ref.read(financeRepositoryProvider).requireValue;
    final updated = await repo.addXxx(item);  // 返回新 Repository
    notifier.state = AsyncData(updated);       // 触发 UI 刷新
  }
}
```

---

## 4. 数据库设计 (Drift)

### 4.1 表结构

| 表名 | 主键 | 关键字段 |
|------|------|----------|
| `accounts` | `id` | name, accountType, reportGroup, currency, initialBalance, currentBalance, institution, isActive |
| `categories` | `id` | name, type (income/expense/investment/transfer), parentId |
| `transactions` | `id` | type, accountId, toAccountId, categoryId, amount, currency, toAmount, toCurrency, recordDate, transactionDate, status, recurringRuleId, description, merchant |
| `budgets` | `id` | categoryId, monthKey, amount, currency, alertThreshold, rolloverEnabled |
| `asset_snapshots` | `id` | accountId, snapshotDate, marketValue, costBasis, cashBalance, contribution, withdrawal |
| `app_meta` | `key` | value (键值对存储) |

### 4.2 Schema 版本历史

| 版本 | 变更 |
|------|------|
| 1 | 初始表：accounts, categories, transactions, budgets |
| 2 | 新增 app_meta 表 |
| 3 | transactions 新增 recordDate |
| 4 | transactions 新增 status, recurringRuleId |
| 5 | transactions 新增 toAmount, toCurrency |
| 6 | budgets 新增 currency |

### 4.3 Meta 键值

| Key | 用途 |
|-----|------|
| `exchange_rates_to_base_json` | 汇率配置 JSON |
| `currency_priority_json` | 币种优先级 JSON |
| `transaction_templates_json` | 快速模板 JSON |
| `recurring_transaction_rules_json` | 周期规则 JSON |
| `asset_goals_json` | 资产目标 JSON |
| `asset_goal_amount` | 旧版资产目标（兼容） |
| `asset_goal_reached_at` | 旧版达成时间（兼容） |
| `theme_style` | 主题选择 |
| `reconciled_<accountId>` | 账户对账月份 |
| `data_migration_version` | 数据迁移版本 |

---

## 5. 核心业务规则

### 5.1 预算合并逻辑

**关键方法**：`BudgetService.activeBudgetsForMonth(monthKey)`

- 对每个分类，取 `monthKey <= 目标月份` 的**最新**预算
- 切换月份时自动显示该月生效的预算金额
- 同分类不同月份的预算会自动合并（取最新）

**有效余额计算**：`effectiveBudgetForMonth(budget, monthKey)`

```
本月有效余额 = 本月预算金额 + rollover 结转
rollover 结转 = 上月(有效余额 - 实际支出)  [仅当 rolloverEnabled]
```

### 5.2 账户余额计算

**余额追溯**：`accountBalanceAt(accountId, date)`

- 优先使用最近的资产快照（≤ date）
- 从快照日期开始，累加后续交易的 delta
- 不同交易类型的 delta 计算：
  - expense: -amount（从账户扣款）
  - income: +amount（入账）
  - transfer: 转出账户 -amount，转入账户 +toAmount
  - adjustment: ±amount

### 5.3 多币种转换

**汇率存储**：`exchange_rates_to_base_json` 存储各币种到主币种的汇率

**转换公式**：
```
amount_in_base = amount / ratesToBase[fromCurrency] * ratesToBase[toCurrency]
```

**主币种**：`currencyPriority` 列表的第一个

### 5.4 交易状态

| 状态 | 含义 | 对余额影响 |
|------|------|------------|
| `planned` | 预计交易 | ❌ 不影响 |
| `actual` | 已发生 | ✅ 影响 |
| `settled` | 历史兼容 | ✅ 等同 actual |

---

## 6. UI 组件说明

### 6.1 页面职责

| 页面 | 文件 | 功能 |
|------|------|------|
| 总览 | `dashboard_screen.dart` | 指标卡片、预算监控、储蓄预测、现金流、信用卡提醒 |
| 交易 | `transactions_screen.dart` | 交易列表、筛选、快速模板、周期规则、分类管理 |
| 账户 | `accounts_screen.dart` | 账户列表、资产快照、余额追溯、目标追踪 |
| 预算 | `budgets_screen.dart` | 预算列表（按月合并）、rollover、新增/编辑 |
| 报表 | `reports_screen.dart` | 折线图/饼图/表格、月度/累计、自定义时间范围 |
| 设置 | `settings_screen.dart` | 主题、汇率、导入导出、示例数据 |

### 6.2 共享组件

| 组件 | 文件 | 用途 |
|------|------|------|
| `SectionCard` | `section_card.dart` | 带标题的卡片容器 |
| `ScreenHeader` | `screen_header.dart` | 页面标题 + 操作按钮 |
| `_MetaChip` | 在 transactions_screen 中 | 小标签（账号/类别） |
| `_PlannedChip` | 在 transactions_screen 中 | 橙色"预计"标签 |
| `LineChart` / `PieChart` | `simple_charts.dart` | 自绘图表 |

### 6.3 交易列表 UI 规则

- 金额 + 类型标签在左侧，结算日期(dd-MM)在右侧
- 描述仅在有意义时显示（不与类型标签重复）
- 账号/类别/状态显示为紧凑标签
- 快速模板和周期交易为横向滚动标签
- 点击标签直接使用，长按弹出编辑/删除

---

## 7. 关键路径速查

| 想改什么 | 修改位置 |
|----------|----------|
| 新增交易字段 | `models/transaction.dart` + `tables/transactions_table.dart` + `app_database.dart` (migration) + `transaction_form_dialog.dart` |
| 修改汇率逻辑 | `services/currency_service.dart` |
| 修改预算合并规则 | `services/budget_service.dart` → `activeBudgetsForMonth()` |
| 修改余额计算 | `services/account_service.dart` → `_accountBalanceAt()` |
| 修改交易筛选 | `transactions_screen.dart` → `filteredTransactions` |
| 修改总览指标 | `dashboard_screen.dart` → `_MetricCard` |
| 添加新主题配色 | `theme/finance_theme.dart` → `paletteForStyle()` |
| 修改导入导出格式 | `services/export_service.dart` |
| 添加新的 Provider | `providers/` 目录，遵循 mutation 模式 |
| 修改数据迁移 | `data/data_migration.dart` |

---

## 8. 构建环境

```bash
# 环境变量
JAVA_HOME=$HOME/jdk-17.0.2
ANDROID_HOME=$HOME/android-sdk

# 常用命令
flutter pub get                    # 安装依赖
flutter analyze                    # 静态分析
flutter test                       # 运行测试
flutter build apk --release        # 编译 APK

# 或使用 check.sh
bash scripts/check.sh
```

---

## 9. 注意事项

1. **不要直接修改 `app_database.g.dart`** — Drift 自动生成，运行 `dart run build_runner build` 重新生成
2. **Schema 升级必须在 `app_database.dart` 的 `onUpgrade` 中添加迁移逻辑**
3. **所有写操作通过 Mutation Provider** — 不要直接在 Screen 中调用 Repository
4. **`local.properties` 会被 Flutter 覆盖** — 用 `flutter config --android-sdk` 设置 SDK 路径
5. **Models 不依赖任何其他层** — 保持纯数据类
6. **Services 不依赖 Provider** — 保持纯业务逻辑
7. **负数金额** — `formatMoney()` 自动处理负号前缀

---

## 10. AI 分析网关架构

### 10.1 架构图

```
Flutter App (手机端)
    ↓ HTTP POST /api/analyze
FastAPI Gateway (WSL, port 5000)
    ↓ 路由到对应模型 API
├── MiMo v2.5 Pro (默认)
├── GPT-4 (可扩展)
├── DeepSeek (可扩展)
└── ...
```

### 10.2 网关配置

**网关代码位置**：`~/projects/finance-compass-gateway/main.py`

**启动命令**：
```bash
cd ~/projects/finance-compass-gateway
source venv/bin/activate
uvicorn main:app --host 0.0.0.0 --port 5000
```

**健康检查**：`http://localhost:5000/health`

**添加新模型**：编辑 `main.py` 中的 `MODELS` 字典

### 10.3 App 端配置

Settings 页面 → AI 网关 → 输入网关地址（如 `http://100.x.x.x:8888`）

### 10.4 API 接口

**POST /api/analyze**

请求：
```json
{
  "model": "mimo",  // 可选，默认 mimo
  "data": {
    "accounts": [...],
    "current_month": {"income": 0, "expense": 0, "net": 0},
    "last_month": {"income": 0, "expense": 0},
    "budgets": [...],
    "goals": [...],
    "recent_transactions": [...]
  }
}
```

响应：
```json
{
  "html": "<div>...</div>",
  "model_used": "mimo"
}
```

### 10.5 端口分配

| 端口 | 用途 | 服务 |
|------|------|------|
| 5000 | API 网关 | FastAPI (uvicorn) |
| 8888 | HTML/文件传输 | Python HTTP Server |

**外部访问**：
- API: `http://100.72.179.116:5000/api/analyze`
- 文件: `http://100.72.179.116:8888/<filename>`

### 10.6 关键文件

| 文件 | 用途 |
|------|------|
| `lib/src/core/services/ai_analysis_service.dart` | App 端 AI 服务（调用网关） |
| `lib/src/features/reports/reports_screen.dart` | 报表页面 AI 分析按钮 |
| `lib/src/features/settings/settings_screen.dart` | 设置页面网关配置 |
| `lib/src/core/data/finance_repository.dart` | `aiGatewayUrl` getter |
| `~/projects/finance-compass-gateway/main.py` | FastAPI 网关服务 |
