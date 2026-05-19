import 'package:isar/isar.dart';

part 'expense.g.dart';

@collection
class Expense {
  Id id = Isar.autoIncrement;

  late String note;

  late double amount;

  late DateTime createdAt;

  @enumerated
  late ExpenseCategory category;

  late bool isIncome;

  @enumerated
  late PaymentMethod paymentMethod;
}

enum PaymentMethod { cash, bank }

enum ExpenseCategory {
  foodAndDrink,
  transport,
  shopping,
  bills,
  entertainment,
  income,
  other,
}
