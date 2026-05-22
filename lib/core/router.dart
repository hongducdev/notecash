import 'package:go_router/go_router.dart';
import 'package:notecash/features/bills/domain/recurring_bill.dart';
import 'package:notecash/features/bills/presentation/bills_screen.dart';
import 'package:notecash/features/bills/presentation/bill_input_screen.dart';
import 'package:notecash/features/dashboard/presentation/main_screen.dart';
import 'package:notecash/features/expense/domain/expense.dart';
import 'package:notecash/features/expense/presentation/expense_input_screen.dart';
import 'package:notecash/features/expense/presentation/receipt_scanner_screen.dart';
import 'package:notecash/features/settings/presentation/settings_screen.dart';
import 'package:notecash/features/settings/presentation/notification_permission_screen.dart';
import 'package:notecash/features/settings/presentation/setup_balance_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const MainScreen()),
    GoRoute(
      path: '/notification-permission',
      builder: (context, state) => const NotificationPermissionScreen(),
    ),
    GoRoute(
      path: '/setup',
      builder: (context, state) => const SetupBalanceScreen(),
    ),
    GoRoute(
      path: '/add-expense',
      builder: (context, state) =>
          ExpenseInputScreen(expenseToEdit: state.extra as Expense?),
    ),
    GoRoute(
      path: '/scan-receipt',
      builder: (context, state) => const ReceiptScannerScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(path: '/bills', builder: (context, state) => const BillsScreen()),
    GoRoute(
      path: '/add-bill',
      builder: (context, state) =>
          BillInputScreen(billToEdit: state.extra as RecurringBill?),
    ),
  ],
);
