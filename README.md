# Finance Compass

完整中文需求与设计文档请看：[finance-app-design.md](finance-app-design.md)。

`Finance Compass` is a Flutter-based personal finance app focused on:

- multi-account bookkeeping
- reusable budgets with rollover
- investment and retirement tracking
- monthly and cumulative reports
- exportable data for external AI analysis

This project is already beyond a simple MVP skeleton. It includes local persistence with `SQLite + Drift`, account and transaction management, reporting, asset snapshots, multi-currency exchange-rate settings, and import/export flows.

## Current Highlights

- Cross-platform Flutter app for Android, Windows, iOS, macOS, Linux, and Web targets.
- Local-first finance database using SQLite and Drift.
- Multi-currency support for `MYR`, `USD`, `CNY`, and `TWD`.
- Per-account currency display with base-currency totals.
- Cross-currency transfers with separate source and target amounts.
- Reusable budgets with positive and negative rollover.
- Planned versus actual transaction states.
- Recurring transaction rules and compact quick templates.
- Account cutoff-month calculations that exclude future transactions.
- Investment and retirement snapshots with contribution, withdrawal, cost, cash balance, and PnL views.
- Multiple net-asset goals with reached-date tracking.
- Full JSON backup/import, AI summary JSON export, and future planning CSV export.
- Exported AI summary can be opened by the operating system so another app can read the JSON.

## Product Scope

The app is designed for personal finance scenarios where the user wants to manage:

- daily cash, e-wallet, savings, and credit accounts
- MYR, USD, CNY, and TWD account and transaction currencies
- category-based income and expense records
- transfer flows between accounts
- investment and retirement accounts with market value tracking
- monthly budgets and rollover logic
- future planned transactions and future budget usage
- planned versus actual cash-flow tracking
- summarized exports for analysis outside the app

## Module Map

### Dashboard

Purpose:

- quick financial overview
- time-filtered period income, expense, and net summary
- monthly comparison
- budget watch
- future expense reservation and simple forecast
- future cash-flow projection from planned transactions
- credit card payment reminders

Key behavior:

- Dashboard is the main page that uses its own selected time range for calculations.
- Period-level values change with the selected year and month filters.

### Accounts

Purpose:

- show grouped balances for `cash`, `credit`, `investment`, and `retirement`
- manage accounts
- view investment and retirement summaries
- manage asset goals

Key behavior:

- Accounts page supports a selectable cutoff month.
- All balances and asset summaries on this page respect that cutoff month.
- Future transactions after the selected cutoff are excluded from displayed values.
- Each account can show a balance trace explaining how the cutoff balance is derived.
- Each account can be marked as reconciled up to a selected month.

### Transactions

Purpose:

- add, edit, delete, and filter transactions
- create recurring monthly transaction records
- reuse common transaction templates for faster entry
- manage recurring transaction rules
- separate transactions into planned and actual states
- maintain categories used by bookkeeping

Key behavior:

- filters support `month from`, `month to`, `type`, `category`, and `account`
- account filtering includes both transfer-out and transfer-in records
- default filter is current month to current month
- transactions can be reused directly or saved as templates
- templates prefill amount, account, category, type, description, merchant, and currency
- planned transactions are shown in planning views but do not change account balances
- recurring rules can generate future planned transactions for 1-12 selected months

### Budgets

Purpose:

- define reusable category budgets
- monitor budget usage by month
- apply rollover logic across months
- compare actual usage and planned usage
- show annualized budget and year-to-date usage

Key behavior:

- budgets are stored as reusable rules by category and effective month
- rollover supports both positive carry and negative carry
- overspending in one month can reduce the next month when rollover is enabled
- budget screens show actual spending, planned spending, and remaining pool balance separately

### Reports

Purpose:

- provide chart and table views for financial data
- compare income and expense trends
- inspect category distributions

Key behavior:

- supports line, pie, and table views
- supports monthly and cumulative modes
- supports last 3 months, last 6 months, last 12 months, and current year

### Settings

Purpose:

- theme selection
- example data setup
- data import and export
- AI summary export

Key behavior:

- full JSON import/export is supported
- full JSON export validates the backup structure before saving
- AI summary export excludes full raw transaction detail and is intended for external analysis
- future planning CSV export is available

## Data Model

The app persists its data in SQLite through Drift.

### `accounts`

Represents real-world accounts such as:

- cash
- bank saving
- e-wallet
- credit card
- pension
- stock
- crypto
- trading
- fund

Important fields:

- `id`
- `name`
- `accountType`
- `reportGroup`
- `currency`
- `initialBalance`
- `currentBalance`
- `institution`
- `note`
- `isActive`

Important distinction:

- `accountType` is the real account type
- `reportGroup` is the reporting bucket used by the app:
  - `cash`
  - `credit`
  - `investment`
  - `retirement`

Supported currencies:

- `MYR`
- `USD`
- `CNY`
- `TWD`

Note:

- Currency selection is stored per account and transaction.
- Currency priority is configured in Settings by drag-and-drop.
- The first currency is the reporting base currency; the second is used as the secondary hint currency.
- Exchange rates are configured as `1 currency = base currency amount`.
- Individual accounts keep their own currency balance; Dashboard, reports, AI summaries, budget usage, and asset goals convert totals back to the selected base currency.

### `categories`

Represents transaction categories.

Category types:

- `income`
- `expense`
- `investment`
- `transfer`

Important fields:

- `id`
- `name`
- `type`
- `parentId`

### `budgets`

Represents reusable category budget rules.

Important fields:

- `id`
- `categoryId`
- `monthKey`
- `amount`
- `currency`
- `alertThreshold`
- `rolloverEnabled`

Meaning:

- `monthKey` is the month when that rule starts being effective
- later months reuse the latest applicable rule
- budget amounts keep their own currency and are converted into the selected base currency before monitoring, rollover, reports, and exports are calculated

### `transactions`

Represents bookkeeping entries.

Transaction types:

- `income`
- `expense`
- `transfer`
- `adjustment`

Important fields:

- `id`
- `type`
- `accountId`
- `toAccountId`
- `categoryId`
- `amount`
- `currency`
- `toAmount`
- `toCurrency`
- `transactionDate`
- `status`
- `recurringRuleId`
- `description`
- `merchant`

Business meaning:

- `income`: increases one account
- `expense`: reduces one account
- `transfer`: moves funds between two accounts; `amount/currency` is the source account amount and `toAmount/toCurrency` is the target account amount
- `adjustment`: contribution or manual funding adjustment, mainly for investment and retirement accounts
- `status = planned`: used for expected future cash flow and budget planning; it does not affect account balances
- `status = actual`: counted as real bookkeeping and affects account balances

### `asset_snapshots`

Represents periodic valuation records for investment and retirement accounts.

Important fields:

- `id`
- `accountId`
- `snapshotDate`
- `marketValue`
- `costBasis`
- `cashBalance`
- `unrealizedPnl`

Meaning:

- snapshots are the valuation anchor for investment-style accounts
- later calculations are rewound or projected from snapshots plus transactions

### `app_meta`

Stores app-level metadata such as:

- theme selection
- seed/example data state
- asset goals
- account reconciliation month markers
- transaction templates
- recurring transaction rules

## Core Business Rules

### Time Semantics

- Dashboard uses its own selected time filter.
- Accounts page uses its selected cutoff month.
- If no special cutoff is chosen, account-related calculations default to current month.
- Future transactions are not included in present-time account calculations.

### Ledger Traceability

- Account balances can be traced from the current account balance or the latest eligible asset snapshot.
- The trace shows the cutoff date, source amount, future transactions reversed for that cutoff, and the final traced balance.
- Reconciliation markers are stored per account so the user can see which month has already been checked against real-world statements.

### Budget Rollover

- If rollover is disabled, unused or overspent budget does not carry forward.
- If rollover is enabled:
  - positive remaining budget carries to next month
  - negative remaining budget also carries to next month
- This means overspending can reduce next month’s available budget.

### Planned Vs Actual

- Planned transactions are for forecasts, future commitments, and budget reservation.
- Actual transactions are treated as real ledger entries.
- Future cash-flow projection reads planned transactions, recurring generated transactions, and future-dated real transactions.
- Budget monitoring separates actual spend from planned spend so future commitments do not look like already-spent money.

### Recurring Transactions

- A transaction can be saved as a recurring rule.
- Rules support monthly, every-2-months, quarterly, and yearly intervals.
- Generating a rule asks for a 1-12 month range and avoids already generated months.

### Credit Card Reminders

- Credit accounts with negative balances are surfaced as payment reminders.
- The first version uses a default reminder date of the 25th of the next month.

### Investment and Retirement Calculations

For investment and retirement accounts:

- contribution flows affect:
  - market value
  - cost basis
  - cash balance
- cumulative contribution and withdrawal are derived from transaction history
- unrealized PnL is based on remaining cost basis, not only raw cumulative cost

Current display values for these accounts are aligned by cutoff date:

- market value
- cumulative contribution
- cumulative withdrawal
- cumulative cost basis
- cash balance
- unrealized PnL

### Transfer Filtering

When filtering transactions by account:

- transfer-out records are included
- transfer-in records are also included

This keeps account-based transaction history complete.

## Import / Export

Supported exports:

- full JSON export
- AI summary JSON export
- future planning CSV export

Supported import:

- full JSON import with preview

Notes:

- full JSON export is intended for backup and restore
- full JSON export validates required backup sections such as accounts, categories, budgets, transactions, snapshots, and metadata
- AI summary JSON is intended for external AI analysis when AI is not directly integrated inside the app

## Project Structure

Main structure under `lib/src`:

- `core/data`
  - repository logic
  - sample data
- `core/database`
  - Drift database
  - tables
  - seed/bootstrap services
- `core/models`
  - domain models
- `core/settings`
  - theme and app settings state
- `core/theme`
  - visual theme system
- `core/utils`
  - formatters and helper functions
- `features/dashboard`
  - overview screen
- `features/accounts`
  - account screens and asset snapshot flows
- `features/transactions`
  - transaction list and transaction form
- `features/budgets`
  - budget list and budget form
- `features/reports`
  - report views and charts
- `features/settings`
  - import/export and app settings
- `features/shared`
  - reusable UI building blocks

## Development

Run from the project folder:

```powershell
C:\Users\dell\.puro\envs\stable\flutter\bin\flutter.bat pub get
C:\Users\dell\.puro\envs\stable\flutter\bin\flutter.bat analyze
C:\Users\dell\.puro\envs\stable\flutter\bin\flutter.bat test
```

Build Android APK:

```powershell
C:\Users\dell\.puro\envs\stable\flutter\bin\flutter.bat build apk
```

Build Android release APK and copy it to an app-named file:

```powershell
cd C:\Users\dell\ai_labs\finance_app
puro flutter build apk --release
Copy-Item -LiteralPath build\app\outputs\flutter-apk\app-release.apk -Destination build\app\outputs\flutter-apk\Finance_Compass_release.apk -Force
```

Build Windows release:

```powershell
Get-Process finance_app -ErrorAction SilentlyContinue | Stop-Process -Force
C:\Users\dell\.puro\envs\stable\flutter\bin\flutter.bat build windows
```
