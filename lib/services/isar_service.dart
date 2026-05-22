import 'package:isar/isar.dart';
import 'package:notecash/core/models/user_settings.dart';
import 'package:notecash/features/bills/domain/recurring_bill.dart';
import 'package:notecash/features/expense/domain/expense.dart';
import 'package:notecash/services/bill_reminder_service.dart';
import 'package:notecash/services/home_widget_service.dart';
import 'package:notecash/services/notification_recognition_service.dart';
import 'package:path_provider/path_provider.dart';

class IsarService {
  late Isar isar;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open([
      ExpenseSchema,
      UserSettingsSchema,
      RecurringBillSchema,
    ], directory: dir.path);
    NotificationRecognitionService.setDatabaseService(this);
    await updateHomeWidget();
    await BillReminderService.rescheduleAll(this);
  }

  // User Settings Methods
  Future<void> saveUserSettings(UserSettings settings) async {
    await isar.writeTxn(() async {
      await isar.userSettings.put(settings);
    });
  }

  Future<UserSettings?> getUserSettings() async {
    return isar.userSettings.get(0);
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

  Future<void> saveExpenses(List<Expense> expenses) async {
    if (expenses.isEmpty) return;
    await isar.writeTxn(() async {
      await isar.expenses.putAll(expenses);
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
    final upcomingBills = await getUpcomingBills(limit: 3);
    await HomeWidgetService.updateBalance(balance);
    await HomeWidgetService.updateBills(upcomingBills);
  }

  Future<void> saveRecurringBill(RecurringBill bill) async {
    await isar.writeTxn(() async {
      await isar.recurringBills.put(bill);
    });
    await updateHomeWidget();
    await BillReminderService.scheduleReminder(bill);
  }

  Future<void> deleteRecurringBill(Id id) async {
    await isar.writeTxn(() async {
      await isar.recurringBills.delete(id);
    });
    await updateHomeWidget();
    await BillReminderService.cancelReminder(id);
  }

  Future<List<RecurringBill>> getAllRecurringBills() async {
    return isar.recurringBills.where().findAll();
  }

  Future<List<RecurringBill>> getUpcomingBills({int limit = 5}) async {
    return isar.recurringBills
        .filter()
        .isActiveEqualTo(true)
        .sortByNextDueDate()
        .limit(limit)
        .findAll();
  }

  Future<void> markBillAsPaid(RecurringBill bill) async {
    final expense = Expense()
      ..amount = bill.amount
      ..isIncome = false
      ..note = bill.name
      ..category = bill.category
      ..paymentMethod = bill.paymentMethod
      ..createdAt = DateTime.now();

    bill.lastPaidDate = DateTime.now();
    bill.nextDueDate = bill.getNextDueDateAfterPayment();

    await isar.writeTxn(() async {
      await isar.expenses.put(expense);
      await isar.recurringBills.put(bill);
    });
    await updateHomeWidget();
    await BillReminderService.scheduleReminder(bill);
  }

  Future<List<Expense>> getAllExpenses() async {
    return isar.expenses.where().sortByCreatedAtDesc().findAll();
  }

  Future<List<Expense>> getTodayExpenses() async {
    final now = DateTime.now();
    return getExpensesByDate(now);
  }

  Future<List<Expense>> getExpensesByDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endExclusive = startOfDay.add(const Duration(days: 1));
    return isar.expenses
        .filter()
        .createdAtBetween(startOfDay, endExclusive, includeUpper: false)
        .sortByCreatedAtDesc()
        .findAll();
  }

  Future<List<Expense>> getExpensesBetween(
    DateTime startInclusive,
    DateTime endExclusive,
  ) async {
    return isar.expenses
        .filter()
        .createdAtBetween(startInclusive, endExclusive, includeUpper: false)
        .sortByCreatedAtDesc()
        .findAll();
  }

  Future<double> getBalanceUntil(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endExclusive = startOfDay.add(const Duration(days: 1));
    final expenses = await isar.expenses
        .filter()
        .createdAtLessThan(endExclusive)
        .findAll();

    final settings = await getUserSettings();
    double balance =
        (settings?.initialCashBalance ?? 0) +
        (settings?.initialBankBalance ?? 0);

    for (final e in expenses) {
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

    for (final e in expenses) {
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

    for (final e in expenses) {
      if (e.isIncome) {
        balance += e.amount;
      } else {
        balance -= e.amount;
      }
    }
    return balance;
  }
}
