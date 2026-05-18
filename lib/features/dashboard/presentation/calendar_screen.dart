import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:notecash/core/providers.dart';
import 'package:notecash/features/expense/domain/expense.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final dateExpensesAsync = ref.watch(dateExpensesProvider(selectedDate));
    final allExpensesAsync = ref.watch(allExpensesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch chi tiêu'),
      ),
      body: Column(
        children: [
          allExpensesAsync.when(
            data: (allExpenses) {
              // Group expenses by date for quick lookup in calendar builders
              final Map<DateTime, List<Expense>> groupedExpenses = {};
              for (var expense in allExpenses) {
                final date = DateTime(expense.createdAt.year, expense.createdAt.month, expense.createdAt.day);
                groupedExpenses.putIfAbsent(date, () => []).add(expense);
              }

              return TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: selectedDate,
                calendarFormat: CalendarFormat.month,
                rowHeight: 64, // Tăng chiều cao hàng để đủ chỗ hiển thị số tiền
                selectedDayPredicate: (day) => isSameDay(selectedDate, day),
                onDaySelected: (selectedDay, focusedDay) {
                  ref.read(selectedDateProvider.notifier).state = selectedDay;
                },
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) => _buildCalendarDay(day, groupedExpenses[DateTime(day.year, day.month, day.day)], colorScheme, isSelected: false),
                  selectedBuilder: (context, day, focusedDay) => _buildCalendarDay(day, groupedExpenses[DateTime(day.year, day.month, day.day)], colorScheme, isSelected: true),
                  todayBuilder: (context, day, focusedDay) => _buildCalendarDay(day, groupedExpenses[DateTime(day.year, day.month, day.day)], colorScheme, isToday: true),
                  outsideBuilder: (context, day, focusedDay) => Opacity(
                    opacity: 0.3,
                    child: _buildCalendarDay(day, null, colorScheme),
                  ),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
                calendarStyle: const CalendarStyle(
                  // Vô hiệu hóa các decoration mặc định để dùng custom builder hoàn toàn
                  outsideDaysVisible: true,
                  todayDecoration: BoxDecoration(),
                  selectedDecoration: BoxDecoration(),
                  markerDecoration: BoxDecoration(),
                ),
              );
            },
            loading: () => const SizedBox(height: 300, child: Center(child: CircularProgressIndicator())),
            error: (err, _) => SizedBox(height: 300, child: Center(child: Text('Lỗi tải lịch: $err'))),
          ),
          const Divider(height: 1),
          Expanded(
            child: dateExpensesAsync.when(
              data: (expenses) {
                if (expenses.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_note, size: 64, color: colorScheme.outlineVariant),
                        const SizedBox(height: 16),
                        Text(
                          'Không có chi tiêu nào',
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    final expense = expenses[index];
                    return _ExpenseItem(expense: expense);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Lỗi: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarDay(
    DateTime day,
    List<Expense>? expenses,
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

    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isSelected ? colorScheme.primaryContainer : (isToday ? colorScheme.surfaceVariant : null),
        borderRadius: BorderRadius.circular(8),
        border: isToday ? Border.all(color: colorScheme.primary, width: 1) : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Thu nhập (ở trên)
          if (totalIncome > 0)
            Text(
              '+${_formatCompact(totalIncome)}',
              style: const TextStyle(color: Colors.green, fontSize: 9, fontWeight: FontWeight.bold),
            )
          else
            const SizedBox(height: 11),
          
          // Ngày
          Text(
            '${day.day}',
            style: TextStyle(
              fontWeight: (isSelected || isToday) ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
              fontSize: 14,
            ),
          ),
          
          // Chi tiêu (ở dưới)
          if (totalExpense > 0)
            Text(
              '-${_formatCompact(totalExpense)}',
              style: const TextStyle(color: Colors.redAccent, fontSize: 9, fontWeight: FontWeight.bold),
            )
          else
            const SizedBox(height: 11),
        ],
      ),
    );
  }

  String _formatCompact(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}k';
    }
    return amount.toStringAsFixed(0);
  }
}

class _ExpenseItem extends StatelessWidget {
  final Expense expense;

  const _ExpenseItem({required this.expense});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getCategoryIcon(expense.category),
            color: colorScheme.onSecondaryContainer,
            size: 20,
          ),
        ),
        title: Text(expense.note, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(DateFormat('HH:mm').format(expense.createdAt)),
        trailing: Text(
          '${expense.isIncome ? "+" : "-"}${currencyFormat.format(expense.amount)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: expense.isIncome ? Colors.green : colorScheme.error,
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.foodAndDrink: return Icons.restaurant_outlined;
      case ExpenseCategory.transport: return Icons.directions_car_outlined;
      case ExpenseCategory.shopping: return Icons.shopping_bag_outlined;
      case ExpenseCategory.bills: return Icons.receipt_long_outlined;
      case ExpenseCategory.entertainment: return Icons.sports_esports_outlined;
      case ExpenseCategory.income: return Icons.attach_money_outlined;
      default: return Icons.category_outlined;
    }
  }
}
