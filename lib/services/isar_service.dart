import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:notecash/features/expense/domain/expense.dart';

class IsarService {
  late Isar isar;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open([ExpenseSchema], directory: dir.path);
  }

  Future<void> saveExpense(Expense expense) async {
    await isar.writeTxn(() async {
      await isar.expenses.put(expense);
    });
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
}
