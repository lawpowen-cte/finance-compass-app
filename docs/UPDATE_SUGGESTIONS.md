# Finance Compass 更新建议文档

生成日期：2026-06-11

本文档基于代码审查和功能分析，整理出所有可优化的用户体验改进项和数据展示缺失项。

---

## 一、报表部分缺失数据（10项）

### 高影响（建议优先实现）

#### 1. 支出分类明细
**现状：** 报表只显示总支出数字，无法看到钱花在哪里
**缺失数据：** 按类别分组的支出/收入明细
**可用方法：** `categoryTotalsForMonths(type: CategoryType.expense, monthKeys: [...])` 返回 `Map<String, double>`
**建议实现：** 添加水平条形图或排名列表，显示前10大支出类别
**参考文件：** `lib/src/features/reports/reports_screen.dart`

#### 2. 净资产/资产趋势线
**现状：** 只有静态总资产数字，没有历史趋势
**缺失数据：** 资产随时间变化的数据点
**可用方法：** `totalAssetHistory(cutoffDate: ...)` 返回 `List<AssetGoalHistoryPoint>`
**建议实现：** 添加折线图显示资产走势（复用已有的 `SimpleLineChart` 组件）
**参考文件：** `lib/src/features/reports/reports_screen.dart`

#### 3. 未来现金流预测
**现状：** 报表完全没有前瞻部分
**缺失数据：** 未来收入、支出、结余预测
**可用方法：**
- `futureCashFlowProjection(months: 6)` 返回 `List<CashFlowProjectionPoint>`
- `forecastSummary(months: 3)` 返回 `ForecastSummary`
- `creditCardPaymentReminders()` 返回信用卡还款提醒
**建议实现：** 添加"未来展望"区块，包含现金流预测图和还款提醒
**参考文件：** `lib/src/features/reports/reports_screen.dart`

### 中影响

#### 4. 储蓄率/预测
**现状：** 没有显示储蓄率和预计存款里程碑
**可用方法：** `forecastSummary()` 返回 `averageMonthlySavings`、`projectedSavingsInThreeMonths` 等
**建议实现：** 添加 KPI 卡片显示储蓄率(%)和预计存款

#### 5. 投资盈亏汇总
**现状：** 报表有资产分组饼图，但没有投资表现数据
**可用方法：**
- `investmentFlowSummaryForAccount(accountId)` 累计投入/取出
- `costBasisForAccount(accountId)` 成本基础
- `snapshotUnrealizedPnl(snapshot)` 未实现盈亏
- `snapshotPnlRatio(snapshot)` 盈亏比例
**建议实现：** 添加"投资表现"卡片，显示汇总成本、总未实现盈亏、整体回报率

#### 6. 环比变化
**现状：** 没有显示"本月支出比上月减少12%"这类对比
**可用方法：** `totalIncomeForMonth(monthKey)` / `totalExpenseForMonth(monthKey)`
**建议实现：** 在 KPI 卡片上添加变化箭头和百分比

### 低影响

#### 7. 转账活动
**现状：** 转账在报表中完全不可见
**建议实现：** 添加"转账"指标卡或在柱状图中包含转账量

#### 8. 按账户支出排名
**现状：** 不知道哪个账户花钱最多
**可用方法：** `expenseBreakdownForAccount(accountId, monthKey)`
**建议实现：** 添加"支出最多账户"排名

#### 9. 实际 vs 预计对比
**现状：** 无法看到预算偏差
**可用方法：** `plannedExpenseTotalForCategory(categoryId, monthKey)`
**建议实现：** 添加"预算偏差"区块，用颜色标注超支/节省

#### 10. 周期性支出汇总
**现状：** 无法看到每月固定支出总额
**可用方法：** `recurringTransactionRules`、`futureExpenseSummaries(months: N)`
**建议实现：** 显示"每月固定支出"摘要卡片

---

## 二、整体 UX 问题（15项）

### 颜色不一致

#### 问题 1：收入/支出颜色两套系统
- **报表页面：** 收入 `#6AAF8A`，支出 `#E07B7B`（柔和色）
- **Dashboard/交易页面：** 收入 `#15803D`，支出 `#B91C1C`（饱和色）
- **建议：** 统一为一套语义化颜色，定义为常量

#### 问题 2：预算阈值颜色不同
- **报表页面：** 超支 `#E07B7B`，警告 `#E8A838`，安全 `#6AAF8A`
- **Dashboard 页面：** 超支 `#B91C1C`，警告 `#EA580C`，安全 `#15803D`
- **建议：** 统一为一套颜色

### 空状态处理不一致

#### 问题 3：空状态样式混乱
- **报表：** `'暂无预算数据'` + 硬编码灰色
- **Dashboard：** 使用 `Theme.of(context).textTheme.bodySmall`
- **账户：** 有图标和操作按钮（好模式）
- **交易：** `'暂无交易'` 纯文字，无图标无建议
- **建议：** 统一空状态组件，包含图标、文字和操作按钮

### 组件复用问题

#### 问题 4：Dashboard 重复造轮子
- Dashboard 自己写了 `_DashboardKpiCard` 和 `_DashboardKpiGrid`
- 没有复用共享的 `FinanceMetricCard` 和 `FinanceMetricGrid`
- **建议：** 统一使用共享组件

#### 问题 5：`_groupLabel` 重复定义
- `reports_screen.dart` 第893行
- `accounts_screen.dart` 第734行
- 完全相同的方法
- **建议：** 集中到 model 或共享工具类

#### 问题 6：`_accountTypeLabel` 重复定义
- 两个文件中标签略有不同（如"储蓄" vs "储蓄账户"）
- **建议：** 统一标签并集中定义

### 缺失状态

#### 问题 7：无加载状态
- 所有页面都没有 loading 指示器或骨架屏
- **建议：** 添加 shimmer/skeleton 加载动画

#### 问题 8：无错误状态
- 没有错误边界处理
- 数据损坏时会直接崩溃
- **建议：** 添加 ErrorWidget 和错误状态页面

### 导航摩擦

#### 问题 9：报表页面无快速摘要
- 打开报表直接是控件和图表，无法快速了解概况
- **建议：** 添加一行摘要："本月：收入 X，支出 Y，结余 Z"

#### 问题 10：Dashboard 预算区块位置深
- 预算月份选择器在 KPI 卡片、资产组合、月度矩阵之后
- **建议：** 考虑将预算区块上移

#### 问题 11：无下拉刷新
- 所有页面都不支持下拉刷新手势
- **建议：** 添加 `RefreshIndicator`

#### 问题 12：AI 按钮不够突出
- AI 分析按钮放在控件区内，不够显眼
- **建议：** 作为独立醒目按钮放置

### 视觉不一致

#### 问题 13：圆角半径不统一
- Dashboard 交易项：`BorderRadius.circular(16)`
- 交易页面交易项：`BorderRadius.circular(10)`
- 账户页面：混合使用 14 和 16
- **建议：** 统一圆角半径

#### 问题 14：字体大小不一致
- 各页面的 label/body/title 使用不一致
- **建议：** 建立统一的排版系统

#### 问题 15：间距不统一
- 各页面的 SizedBox(height: X) 数值不一致（8, 12, 14, 16 混用）
- **建议：** 建立统一的间距规范（如 8, 12, 16, 24, 32）

---

## 三、建议实现优先级

### 第一批（高影响 + 低成本）

| 序号 | 改进项 | 影响 | 工作量 |
|------|--------|------|--------|
| 1 | 支出分类明细 | ⭐⭐⭐ | 中 |
| 2 | 资产趋势线 | ⭐⭐⭐ | 低 |
| 3 | 统一颜色系统 | ⭐⭐ | 低 |

### 第二批（高影响 + 中成本）

| 序号 | 改进项 | 影响 | 工作量 |
|------|--------|------|--------|
| 4 | 未来现金流预测 | ⭐⭐⭐ | 中 |
| 5 | 储蓄率/预测 | ⭐⭐ | 低 |
| 6 | 投资盈亏汇总 | ⭐⭐ | 中 |

### 第三批（UX 一致性）

| 序号 | 改进项 | 影响 | 工作量 |
|------|--------|------|--------|
| 7 | 统一空状态处理 | ⭐⭐ | 中 |
| 8 | 统一组件复用 | ⭐⭐ | 中 |
| 9 | 添加下拉刷新 | ⭐ | 低 |
| 10 | 统一圆角和间距 | ⭐ | 低 |

### 第四批（低影响）

| 序号 | 改进项 | 影响 | 工作量 |
|------|--------|------|--------|
| 11 | 环比变化指示 | ⭐ | 低 |
| 12 | 实际 vs 预计对比 | ⭐ | 中 |
| 13 | 转账活动显示 | ⭐ | 低 |
| 14 | 按账户支出排名 | ⭐ | 低 |
| 15 | 周期性支出汇总 | ⭐ | 低 |

---

## 四、相关文件索引

| 文件 | 行数 | 问题项 |
|------|------|--------|
| `lib/src/features/reports/reports_screen.dart` | 1223 | 缺失数据 1-10、颜色不一致 |
| `lib/src/features/dashboard/dashboard_screen.dart` | 1170 | 组件复用、颜色不一致 |
| `lib/src/features/accounts/accounts_screen.dart` | 1187 | _groupLabel 重复 |
| `lib/src/features/transactions/transactions_screen.dart` | 1738 | 空状态处理 |
| `lib/src/features/settings/settings_screen.dart` | 820 | - |
| `lib/src/core/data/finance_repository.dart` | 2670 | 数据方法已就绪 |
| `lib/src/features/shared/finance_metric_card.dart` | - | 共享组件 |
| `lib/src/features/shared/simple_charts.dart` | - | SimpleLineChart 可复用 |
