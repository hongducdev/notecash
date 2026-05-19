import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notecash/features/expense/domain/expense.dart';
import 'package:notecash/features/notification_log/domain/notification_log.dart';
import 'package:notecash/services/isar_service.dart';

final isarServiceProvider = Provider<IsarService>((ref) {
  return IsarService();
});

final expensesProvider = FutureProvider((ref) async {
  final service = ref.watch(isarServiceProvider);
  return service.getAllExpenses();
});

final todayExpensesProvider = FutureProvider((ref) async {
  final service = ref.watch(isarServiceProvider);
  return service.getTodayExpenses();
});

final selectedDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

final dateExpensesProvider = FutureProvider.family<List<Expense>, DateTime>((ref, date) async {
  final service = ref.watch(isarServiceProvider);
  return service.getExpensesByDate(date);
});

final cumulativeBalanceProvider = FutureProvider.family<double, DateTime>((ref, date) async {
  final service = ref.watch(isarServiceProvider);
  return service.getBalanceUntil(date);
});

final allExpensesProvider = FutureProvider((ref) async {
  final service = ref.watch(isarServiceProvider);
  return service.getAllExpenses();
});

final notificationLogsProvider = FutureProvider<List<NotificationLog>>((ref) async {
  final service = ref.watch(isarServiceProvider);
  return service.getAllNotificationLogs();
});

final unreadNotificationLogsProvider = FutureProvider<List<NotificationLog>>((ref) async {
  final service = ref.watch(isarServiceProvider);
  return service.getUnreadNotificationLogs();
});
