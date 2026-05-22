import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notecash/core/providers.dart';
import 'package:notecash/features/bills/domain/recurring_bill.dart';
import 'package:notecash/features/bills/utils/bill_icon_utils.dart';
import 'package:notecash/features/expense/domain/expense.dart';
import 'package:table_calendar/table_calendar.dart';

class DashboardCalendar extends ConsumerWidget {
  final AsyncValue<List<Expense>> monthExpensesAsync;
  final AsyncValue<List<RecurringBill>> recurringBillsAsync;
  final DateTime selectedDate;

  const DashboardCalendar({
    super.key,
    required this.monthExpensesAsync,
    required this.recurringBillsAsync,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: monthExpensesAsync.when(
        data: (monthExpenses) {
          return recurringBillsAsync.when(
            data: (recurringBills) {
              final Map<DateTime, List<Expense>> groupedExpenses = {};
              for (final expense in monthExpenses) {
                final date = DateTime(
                  expense.createdAt.year,
                  expense.createdAt.month,
                  expense.createdAt.day,
                );
                groupedExpenses.putIfAbsent(date, () => []).add(expense);
              }

              final Map<DateTime, List<RecurringBill>> groupedBills = {};
              for (final bill in recurringBills) {
                if (!bill.isActive) continue;
                final date = DateTime(
                  bill.nextDueDate.year,
                  bill.nextDueDate.month,
                  bill.nextDueDate.day,
                );
                groupedBills.putIfAbsent(date, () => []).add(bill);
              }

              return TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: selectedDate,
                calendarFormat: CalendarFormat.month,
                rowHeight: 64,
                availableCalendarFormats: const {CalendarFormat.month: 'Tháng'},
                selectedDayPredicate: (day) => isSameDay(selectedDate, day),
                onDaySelected: (selectedDay, focusedDay) {
                  ref.read(selectedDateProvider.notifier).state = selectedDay;
                },
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) =>
                      _buildCalendarDay(
                        day,
                        groupedExpenses[DateTime(day.year, day.month, day.day)],
                        groupedBills[DateTime(day.year, day.month, day.day)],
                        colorScheme,
                      ),
                  selectedBuilder: (context, day, focusedDay) =>
                      _buildCalendarDay(
                        day,
                        groupedExpenses[DateTime(day.year, day.month, day.day)],
                        groupedBills[DateTime(day.year, day.month, day.day)],
                        colorScheme,
                        isSelected: true,
                      ),
                  todayBuilder: (context, day, focusedDay) => _buildCalendarDay(
                    day,
                    groupedExpenses[DateTime(day.year, day.month, day.day)],
                    groupedBills[DateTime(day.year, day.month, day.day)],
                    colorScheme,
                    isToday: true,
                  ),
                  outsideBuilder: (context, day, focusedDay) => Opacity(
                    opacity: 0.3,
                    child: _buildCalendarDay(
                      day,
                      groupedExpenses[DateTime(day.year, day.month, day.day)],
                      groupedBills[DateTime(day.year, day.month, day.day)],
                      colorScheme,
                    ),
                  ),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: colorScheme.onSurface,
                  ),
                  leftChevronIcon: Icon(
                    Icons.chevron_left,
                    color: colorScheme.onSurface,
                  ),
                  rightChevronIcon: Icon(
                    Icons.chevron_right,
                    color: colorScheme.onSurface,
                  ),
                ),
                calendarStyle: const CalendarStyle(
                  outsideDaysVisible: true,
                  todayDecoration: BoxDecoration(),
                  selectedDecoration: BoxDecoration(),
                  markerDecoration: BoxDecoration(),
                ),
              );
            },
            loading: () => const SizedBox(
              height: 300,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => SizedBox(
              height: 300,
              child: Center(child: Text('Lỗi tải hóa đơn: $err')),
            ),
          );
        },
        loading: () => const SizedBox(
          height: 300,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (err, _) => SizedBox(
          height: 300,
          child: Center(child: Text('Lỗi tải lịch: $err')),
        ),
      ),
    );
  }

  Widget _buildCalendarDay(
    DateTime day,
    List<Expense>? expenses,
    List<RecurringBill>? dueBills,
    ColorScheme colorScheme, {
    bool isSelected = false,
    bool isToday = false,
  }) {
    double totalIncome = 0;
    double totalExpense = 0;

    if (expenses != null) {
      for (var e in expenses) {
        if (e.isIncome) {
          totalIncome += e.amount;
        } else {
          totalExpense += e.amount;
        }
      }
    }

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer
              : (isToday ? colorScheme.surfaceContainerHighest : null),
          borderRadius: BorderRadius.circular(8),
          border: isToday
              ? Border.all(color: colorScheme.primary, width: 1)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (dueBills != null && dueBills.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 2,
                  children: dueBills.take(3).map((bill) {
                    return BillIconUtils.getIconWidget(
                      bill.name,
                      colorScheme,
                      size: 10,
                    );
                  }).toList(),
                ),
              )
            else if (totalIncome > 0)
              Text(
                '+${_formatCompact(totalIncome)}',
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              )
            else
              const SizedBox(height: 10),
            Text(
              '${day.day}',
              style: TextStyle(
                fontWeight: (isSelected || isToday)
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurface,
                fontSize: 12,
              ),
            ),
            if (totalExpense > 0)
              Text(
                '-${_formatCompact(totalExpense)}',
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              )
            else
              const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  String _formatCompact(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}k';
    return amount.toStringAsFixed(0);
  }
}
