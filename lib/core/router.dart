import 'package:go_router/go_router.dart';
import 'package:notecash/core/providers.dart';
import 'package:notecash/features/dashboard/presentation/main_screen.dart';
import 'package:notecash/features/expense/domain/expense.dart';
import 'package:notecash/features/expense/presentation/expense_input_screen.dart';
import 'package:notecash/features/expense/presentation/receipt_scanner_screen.dart';
import 'package:notecash/features/notification_log/presentation/notification_log_screen.dart';
import 'package:notecash/features/settings/presentation/settings_screen.dart';
import 'package:notecash/features/settings/presentation/setup_balance_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) async {
    // This is a simple redirect. In a real app, you might want to 
    // use a more reactive approach with Riverpod.
    // However, for initial setup, checking Isar directly is fine.
    
    // We can't easily access Riverpod here without a container.
    // But we can check the database status.
    // Since we need to be careful with async redirects in GoRouter,
    // let's assume the MainScreen or NoteCashApp will handle the initial check.
    
    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (context, state) => const MainScreen()),
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
      path: '/notification-log',
      builder: (context, state) => const NotificationLogScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
