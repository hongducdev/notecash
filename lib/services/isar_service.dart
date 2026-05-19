import 'package:isar/isar.dart';
import 'package:notecash/core/models/user_settings.dart';
import 'package:notecash/features/expense/domain/expense.dart';
import 'package:notecash/features/notification_log/domain/notification_log.dart';
import 'package:notecash/services/home_widget_service.dart';
import 'package:path_provider/path_provider.dart';

class IsarService {
  late Isar isar;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open([
      ExpenseSchema,
      NotificationLogSchema,
      UserSettingsSchema,
    ], directory: dir.path);
    await updateHomeWidget();
  }

  // User Settings Methods
  Future<void> saveUserSettings(UserSettings settings) async {
    await isar.writeTxn(() async {
      await isar.userSettings.put(settings);
    });
  }

  Future<UserSettings?> getUserSettings() async {
    return await isar.userSettings.get(0);
  }

  Future<bool> isSetupCompleted() async {
    final settings = await getUserSettings();
    return settings?.isSetupCompleted ?? false;
  }

  Future<void> saveExpense(Expense expense) async {
    await isar.writeTxn(() async {
      await isar.expenses.put(expense);
    });
    await updateHomeWidget();
  }

  Future<void> deleteExpense(Id id) async {
    await isar.writeTxn(() async {
      await isar.expenses.delete(id);
    });
    await updateHomeWidget();
  }

  Future<void> updateHomeWidget() async {
    final balance = await getBalanceUntil(DateTime.now());
    await HomeWidgetService.updateBalance(balance);
  }

  Future<List<Expense>> getAllExpenses() async {
    return await isar.expenses.where().sortByCreatedAtDesc().findAll();
  }

  Future<List<Expense>> getTodayExpenses() async {
    final now = DateTime.now();
    return getExpensesByDate(now);
  }

  Future<List<Expense>> getExpensesByDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    return await isar.expenses
        .filter()
        .createdAtBetween(startOfDay, endOfDay)
        .sortByCreatedAtDesc()
        .findAll();
  }

  Future<void> saveNotificationLog(NotificationLog log) async {
    await isar.writeTxn(() async {
      await isar.notificationLogs.put(log);
    });
  }

  Future<List<NotificationLog>> getAllNotificationLogs() async {
    return await isar.notificationLogs.where().sortByReceivedAtDesc().findAll();
  }

  Future<List<NotificationLog>> getUnreadNotificationLogs() async {
    return await isar.notificationLogs
        .filter()
        .isReadEqualTo(false)
        .sortByReceivedAtDesc()
        .findAll();
  }

  Future<void> markNotificationLogAsRead(Id id) async {
    await isar.writeTxn(() async {
      final log = await isar.notificationLogs.get(id);
      if (log != null) {
        log.isRead = true;
        await isar.notificationLogs.put(log);
      }
    });
  }

  Future<void> markAllNotificationLogsAsRead() async {
    await isar.writeTxn(() async {
      final logs = await isar.notificationLogs
          .filter()
          .isReadEqualTo(false)
          .findAll();
      for (final log in logs) {
        log.isRead = true;
        await isar.notificationLogs.put(log);
      }
    });
  }

  Future<void> clearAllNotificationLogs() async {
    await isar.writeTxn(() async {
      await isar.notificationLogs.where().deleteAll();
    });
  }

  Future<double> getBalanceUntil(DateTime date) async {
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    final expenses = await isar.expenses
        .filter()
        .createdAtLessThan(endOfDay)
        .findAll();

    final settings = await getUserSettings();
    double balance = (settings?.initialCashBalance ?? 0) + (settings?.initialBankBalance ?? 0);
    
    for (var e in expenses) {
      if (e.isIncome) {
        balance += e.amount;
      } else {
        balance -= e.amount;
      }
    }
    return balance;
  }

  Future<double> getCashBalance() async {
    final settings = await getUserSettings();
    double balance = settings?.initialCashBalance ?? 0;
    
    final expenses = await isar.expenses
        .filter()
        .paymentMethodEqualTo(PaymentMethod.cash)
        .findAll();
        
    for (var e in expenses) {
      if (e.isIncome) {
        balance += e.amount;
      } else {
        balance -= e.amount;
      }
    }
    return balance;
  }

  Future<double> getBankBalance() async {
    final settings = await getUserSettings();
    double balance = settings?.initialBankBalance ?? 0;
    
    final expenses = await isar.expenses
        .filter()
        .paymentMethodEqualTo(PaymentMethod.bank)
        .findAll();
        
    for (var e in expenses) {
      if (e.isIncome) {
        balance += e.amount;
      } else {
        balance -= e.amount;
      }
    }
    return balance;
  }
}
