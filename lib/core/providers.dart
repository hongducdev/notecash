import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notecash/core/app_lock_controller.dart';
import 'package:notecash/core/models/user_settings.dart';
import 'package:notecash/features/bills/domain/recurring_bill.dart';
import 'package:notecash/features/expense/domain/expense.dart';
import 'package:notecash/services/backup_service.dart';
import 'package:notecash/services/isar_service.dart';
import 'package:notecash/services/security_service.dart';

final isarServiceProvider = Provider<IsarService>((ref) {
  return IsarService();
});

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(ref.watch(isarServiceProvider));
});

final securityServiceProvider = Provider<SecurityService>((ref) {
  return SecurityService(ref.watch(isarServiceProvider));
});

final appLockControllerProvider = Provider<AppLockController>((ref) {
  return AppLockController(ref.watch(securityServiceProvider));
});

final userSettingsProvider = FutureProvider<UserSettings?>((ref) async {
  final service = ref.watch(isarServiceProvider);
  return service.getUserSettings();
});

final cashBalanceProvider = FutureProvider<double>((ref) async {
  final service = ref.watch(isarServiceProvider);
  return service.getCashBalance();
});

final bankBalanceProvider = FutureProvider<double>((ref) async {
  final service = ref.watch(isarServiceProvider);
  return service.getBankBalance();
});

final todayExpensesProvider = FutureProvider<List<Expense>>((ref) async {
  final service = ref.watch(isarServiceProvider);
  return service.getTodayExpenses();
});

final selectedDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

final dateExpensesProvider = FutureProvider.family<List<Expense>, DateTime>((
  ref,
  date,
) async {
  final service = ref.watch(isarServiceProvider);
  return service.getExpensesByDate(date);
});

final cumulativeBalanceProvider = FutureProvider.family<double, DateTime>((
  ref,
  date,
) async {
  final service = ref.watch(isarServiceProvider);
  return service.getBalanceUntil(date);
});

final monthExpensesProvider = FutureProvider.family<List<Expense>, DateTime>((
  ref,
  monthKey,
) async {
  final service = ref.watch(isarServiceProvider);
  final start = DateTime(monthKey.year, monthKey.month);
  final end = DateTime(monthKey.year, monthKey.month + 1);
  return service.getExpensesBetween(start, end);
});

final allExpensesProvider = FutureProvider<List<Expense>>((ref) async {
  final service = ref.watch(isarServiceProvider);
  return service.getAllExpenses();
});

final recurringBillsProvider = FutureProvider<List<RecurringBill>>((ref) async {
  final service = ref.watch(isarServiceProvider);
  return service.getAllRecurringBills();
});

final upcomingBillsProvider = FutureProvider<List<RecurringBill>>((ref) async {
  final service = ref.watch(isarServiceProvider);
  return service.getUpcomingBills();
});
