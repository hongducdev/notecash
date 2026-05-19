import 'package:go_router/go_router.dart';
import 'package:notecash/features/dashboard/presentation/main_screen.dart';
import 'package:notecash/features/expense/domain/expense.dart';
import 'package:notecash/features/expense/presentation/expense_input_screen.dart';
import 'package:notecash/features/expense/presentation/receipt_scanner_screen.dart';
import 'package:notecash/features/notification_log/presentation/notification_log_screen.dart';
import 'package:notecash/features/settings/presentation/settings_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const MainScreen()),
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
      path: '/notification-log',
      builder: (context, state) => const NotificationLogScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
