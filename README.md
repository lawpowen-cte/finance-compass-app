# Finance Compass

Cross-platform personal finance app built with Flutter for:

- account tracking
- budget planning with rollover
- income, expense, transfer, and contribution records
- investment and retirement tracking
- reports and AI-ready exports

## Current capabilities

- Accounts
  - custom accounts grouped into `cash`, `credit`, `investment`, and `retirement`
  - account page supports a selectable cutoff month
  - account totals, asset goals, balances, and investment summaries all respect the selected cutoff month
- Transactions
  - add, edit, and delete transactions
  - recurring monthly transaction generation
  - filters for month-from, month-to, type, category, and account
  - account filter includes both transfer-out and transfer-in records
- Budgets
  - reusable category budgets with rollover
  - rollover supports both positive carry and negative carry for overspending
  - budget page supports month selection and future-month review
- Investments
  - asset snapshots for investment and retirement accounts
  - current market value, cumulative contribution, withdrawal, cost basis, and cash balance
  - unrealized PnL based on remaining cost basis
  - all account-level investment calculations default to current-month cutoff unless a specific cutoff is chosen
- Reports
  - income and expense line chart
  - pie and table views
  - monthly or cumulative mode
  - ranges for last 3 months, last 6 months, last 12 months, and current year
- Import / Export
  - full JSON export and import
  - AI summary JSON export
  - future planning CSV export

## Data rules

- Only Dashboard uses its own selected time filter for period analysis.
- Account-related pages use the selected account cutoff month, or current month by default.
- Future transactions are not included in present-time account calculations.
- For investment and retirement accounts, contribution flows affect:
  - market value
  - cost basis
  - cash balance

## Tech stack

- Flutter
- SQLite + Drift

## Development

From the project folder:

```powershell
C:\Users\dell\.puro\envs\stable\flutter\bin\flutter.bat pub get
C:\Users\dell\.puro\envs\stable\flutter\bin\flutter.bat analyze
C:\Users\dell\.puro\envs\stable\flutter\bin\flutter.bat test
```

Build Android APK:

```powershell
C:\Users\dell\.puro\envs\stable\flutter\bin\flutter.bat build apk
```

Build Windows release:

```powershell
Get-Process finance_app -ErrorAction SilentlyContinue | Stop-Process -Force
C:\Users\dell\.puro\envs\stable\flutter\bin\flutter.bat build windows
```
