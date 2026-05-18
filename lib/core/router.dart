import 'package:go_router/go_router.dart';
import 'package:notecash/features/dashboard/presentation/main_screen.dart';
import 'package:notecash/features/expense/presentation/expense_input_screen.dart';
import 'package:notecash/features/settings/presentation/settings_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const MainScreen()),
    GoRoute(
      path: '/add-expense',
      builder: (context, state) => const ExpenseInputScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
