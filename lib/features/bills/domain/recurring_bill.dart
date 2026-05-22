import 'package:isar/isar.dart';
import 'package:notecash/features/expense/domain/expense.dart';

part 'recurring_bill.g.dart';

enum BillFrequency { monthly, quarterly, annual }

@collection
class RecurringBill {
  Id id = Isar.autoIncrement;

  late String name;

  late double amount;

  @enumerated
  late ExpenseCategory category;

  @enumerated
  late BillFrequency frequency;

  late DateTime nextDueDate;

  @enumerated
  late PaymentMethod paymentMethod;

  late bool isActive;

  late int reminderDaysBefore;

  DateTime? lastPaidDate;

  DateTime? createdAt;

  int get daysUntilDue {
    final now = DateTime.now();
    final dueDate = DateTime(
      nextDueDate.year,
      nextDueDate.month,
      nextDueDate.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    return dueDate.difference(today).inDays;
  }

  bool get isOverdue => daysUntilDue < 0;

  bool get isDueSoon => daysUntilDue >= 0 && daysUntilDue <= reminderDaysBefore;

  DateTime getNextDueDateAfterPayment() {
    switch (frequency) {
      case BillFrequency.monthly:
        return _addMonthsPreservingDay(1);
      case BillFrequency.quarterly:
        return _addMonthsPreservingDay(3);
      case BillFrequency.annual:
        final lastDayOfMonth = DateTime(
          nextDueDate.year + 1,
          nextDueDate.month + 1,
          0,
        ).day;
        return DateTime(
          nextDueDate.year + 1,
          nextDueDate.month,
          nextDueDate.day > lastDayOfMonth ? lastDayOfMonth : nextDueDate.day,
        );
    }
  }

  DateTime _addMonthsPreservingDay(int monthsToAdd) {
    final totalMonths = nextDueDate.month + monthsToAdd;
    final targetYear = nextDueDate.year + ((totalMonths - 1) ~/ 12);
    final targetMonth = ((totalMonths - 1) % 12) + 1;
    final lastDayOfMonth = DateTime(targetYear, targetMonth + 1, 0).day;

    return DateTime(
      targetYear,
      targetMonth,
      nextDueDate.day > lastDayOfMonth ? lastDayOfMonth : nextDueDate.day,
    );
  }

  String getFrequencyLabel() {
    switch (frequency) {
      case BillFrequency.monthly:
        return 'Hàng tháng';
      case BillFrequency.quarterly:
        return 'Hàng quý';
      case BillFrequency.annual:
        return 'Hàng năm';
    }
  }
}
