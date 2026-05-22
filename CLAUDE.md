# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

* **Run application:** `flutter run`
* **Fetch dependencies:** `flutter pub get`
* **Run tests:** `flutter test`
* **Run single test:** `flutter test test/path_to_test.dart`
* **Code generation:** `flutter pub run build_runner build --delete-conflicting-outputs`
* **Format code:** `dart format .`
* **Static analysis:** `flutter analyze`

## Architecture & Structure

NoteCash uses **Riverpod** for state management, **GoRouter** for routing, and **Isar** as a local database.

### 1. Project Layout
* `lib/main.dart` - Entrypoint initializing HomeWidget, local/push reminders, and Isar schemas.
* `lib/core/` - Application core logic, providers, global themes, and shared models.
* `lib/features/` - Feature-driven modules (e.g., `bills`, `expense`, `dashboard`, `settings`). Each module bundles its presentation widgets/screens and data models.
* `lib/services/` - App-wide services handling background operations, data exports, local auth, and notification intercepting.

### 2. Global Services & State Boundaries
* **State Management (`lib/core/providers.dart`):** Centralizes all Riverpod providers for data (cash/bank balances, daily expenses, pending bills). Directly calls `IsarService` APIs.
* **Storage (`lib/services/isar_service.dart`):** Manages Isar transactions and collections (`Expense`, `UserSettings`, `RecurringBill`). Handles balance logic and auto-reschedules reminders.
* **Notification Recognition (`lib/services/notification_recognition_service.dart`):** Runs on Android as a service, listening to banking/wallet transactions (`Techcombank`, `Vietinbank`, `Timo`, `Cake`, `Momo`, `ZaloPay`), parsing text with regexes to pull amounts, and dispatching local quick-actions.
* **Backup/Security:** `backup_service.dart` coordinates XML import/export. `security_service.dart` works with local PIN hash and biometric authentication.

### 3. Routing (`lib/core/router.dart`)
GoRouter handles navigation with these routes:
* `/` - MainScreen (dashboard with bottom nav)
* `/lock` - LockScreen (PIN/biometric entry)
* `/pin-setup` - PinSetupScreen
* `/notification-permission` - NotificationPermissionScreen
* `/setup` - SetupBalanceScreen (initial cash/bank balance)
* `/add-expense` - ExpenseInputScreen (accepts `Expense?` via `extra`)
* `/scan-receipt` - ReceiptScannerScreen (OCR via ML Kit)
* `/settings` - SettingsScreen
* `/bills` - BillsScreen
* `/add-bill` - BillInputScreen (accepts `RecurringBill?` via `extra`)

### 4. Code Generation
* **Isar collections:** Domain models annotated with `@collection` generate `.g.dart` files. Run `flutter pub run build_runner build --delete-conflicting-outputs` after modifying `Expense`, `UserSettings`, or `RecurringBill`.
* **Riverpod:** Uses `riverpod_annotation` for code-generated providers (though current providers in `lib/core/providers.dart` are manually written).

### 5. App Lock Flow
* `AppLockController` (in `lib/core/app_lock_controller.dart`) listens to app lifecycle. When app goes to background (`AppLifecycleState.paused`), it locks if a PIN is set.
* `main.dart` wraps `MaterialApp.router` with a `builder` that shows `LockScreen` overlay when `appLock.isLocked == true`.
* Unlock via PIN or biometric (if enabled) calls `appLockController.unlock()`.

### 6. Home Widget Integration
* `HomeWidgetService` updates Android/iOS widgets with current balance and upcoming bills.
* Widget clicks route to `/add-expense`, `/bills`, or `/` via deep links (`HomeWidget.widgetClicked` stream).
* Every Isar write that affects balance or bills triggers `updateHomeWidget()`.

### 7. Bill Reminders
* `BillReminderService` schedules local notifications using `flutter_local_notifications` with timezone support.
* Reminders fire `reminderDaysBefore` days before `nextDueDate` at 9:00 AM.
* When a bill is marked paid, `IsarService.markBillAsPaid()` creates an `Expense` record, updates `nextDueDate`, and reschedules the reminder.

### 8. Notification Parsing
* `NotificationRecognitionService` uses regex patterns to extract transaction amounts from Vietnamese banking notifications.
* Patterns match signed amounts (`+1000`, `-500`), currency-prefixed amounts (`đ 1000`), and increase/decrease keywords (`tăng`, `giảm`).
* Parsed transactions show quick-add notifications with inline input for manual amount entry.

## Important Notes
* The app is localized in Vietnamese (`vi_VN`).
* All currency formatting uses `NumberFormat.currency(locale: 'vi_VN', symbol: '₫')`.
* Balance calculations aggregate from `initialCashBalance` + `initialBankBalance` plus all `Expense` records (income adds, expense subtracts).
* No tests currently exist in the repository.
