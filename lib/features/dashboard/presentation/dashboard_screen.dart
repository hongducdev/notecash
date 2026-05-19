import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:notecash/core/providers.dart';
import 'package:notecash/features/expense/domain/expense.dart';
import 'package:notecash/shared/widgets/app_logo.dart';
import 'package:table_calendar/table_calendar.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final dateExpensesAsync = ref.watch(dateExpensesProvider(selectedDate));
    final monthKey = DateTime(selectedDate.year, selectedDate.month);
    final monthExpensesAsync = ref.watch(monthExpensesProvider(monthKey));
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              title: const AppLogo(size: 32),
              actions: [
                IconButton(
                  onPressed: () => context.push('/settings'),
                  icon: const Icon(Icons.settings_outlined),
                ),
                const SizedBox(width: 8),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSpendingOverview(context, ref),
                    const SizedBox(height: 24),
                    _buildCalendar(
                      context,
                      ref,
                      monthExpensesAsync,
                      selectedDate,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Giao dịch ngày ${DateFormat('dd/MM').format(selectedDate)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            dateExpensesAsync.when(
              data: (expenses) {
                if (expenses.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          'Không có giao dịch nào trong ngày này',
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final expense = expenses[index];
                    return _ExpenseTile(expense: expense);
                  }, childCount: expenses.length),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => SliverToBoxAdapter(
                child: Center(
                  child: Text(
                    'Lỗi: $err',
                    style: TextStyle(color: colorScheme.error),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpendingOverview(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final dateExpensesAsync = ref.watch(dateExpensesProvider(selectedDate));
    final cumulativeBalanceAsync = ref.watch(
      cumulativeBalanceProvider(selectedDate),
    );
    final cashBalanceAsync = ref.watch(cashBalanceProvider);
    final bankBalanceAsync = ref.watch(bankBalanceProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return dateExpensesAsync.when(
      data: (expenses) {
        double totalIncome = 0;
        double totalExpense = 0;

        for (var e in expenses) {
          if (e.isIncome) {
            totalIncome += e.amount;
          } else {
            totalExpense += e.amount;
          }
        }

        final currencyFormat = NumberFormat.currency(
          locale: 'vi_VN',
          symbol: '₫',
        );

        return Card(
          margin: EdgeInsets.zero,
          color: colorScheme.surfaceContainerLow,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildOverviewItem(
                        context,
                        'Thu nhập',
                        totalIncome,
                        Colors.green,
                        currencyFormat,
                      ),
                    ),
                    Container(
                      height: 40,
                      width: 1,
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                    Expanded(
                      child: _buildOverviewItem(
                        context,
                        'Chi tiêu',
                        totalExpense,
                        Colors.redAccent,
                        currencyFormat,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),
                _buildBalanceRow(
                  context,
                  'Tiền mặt',
                  cashBalanceAsync,
                  colorScheme.onSurfaceVariant,
                  currencyFormat,
                ),
                const SizedBox(height: 8),
                _buildBalanceRow(
                  context,
                  'Ngân hàng',
                  bankBalanceAsync,
                  colorScheme.onSurfaceVariant,
                  currencyFormat,
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tổng số dư',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    cumulativeBalanceAsync.when(
                      data: (balance) => Text(
                        currencyFormat.format(balance),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: balance >= 0 ? Colors.green : Colors.redAccent,
                        ),
                      ),
                      loading: () => const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      error: (err, _) => const Icon(Icons.error, size: 20),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading: () =>
          const Card(child: SizedBox(height: 120, width: double.infinity)),
      error: (_, _) =>
          const Card(child: SizedBox(height: 120, width: double.infinity)),
    );
  }

  Widget _buildBalanceRow(
    BuildContext context,
    String label,
    AsyncValue<double> balanceAsync,
    Color color,
    NumberFormat format,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: color)),
        balanceAsync.when(
          data: (balance) => Text(
            format.format(balance),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          loading: () => const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 1.5),
          ),
          error: (_, _) => const Icon(Icons.error, size: 14),
        ),
      ],
    );
  }

  Widget _buildOverviewItem(
    BuildContext context,
    String label,
    double amount,
    Color color,
    NumberFormat format,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          format.format(amount),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendar(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Expense>> monthExpensesAsync,
    DateTime selectedDate,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: monthExpensesAsync.when(
        data: (monthExpenses) {
          final Map<DateTime, List<Expense>> groupedExpenses = {};
          for (final expense in monthExpenses) {
            final date = DateTime(
              expense.createdAt.year,
              expense.createdAt.month,
              expense.createdAt.day,
            );
            groupedExpenses.putIfAbsent(date, () => []).add(expense);
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
              defaultBuilder: (context, day, focusedDay) => _buildCalendarDay(
                day,
                groupedExpenses[DateTime(day.year, day.month, day.day)],
                colorScheme,
              ),
              selectedBuilder: (context, day, focusedDay) => _buildCalendarDay(
                day,
                groupedExpenses[DateTime(day.year, day.month, day.day)],
                colorScheme,
                isSelected: true,
              ),
              todayBuilder: (context, day, focusedDay) => _buildCalendarDay(
                day,
                groupedExpenses[DateTime(day.year, day.month, day.day)],
                colorScheme,
                isToday: true,
              ),
              outsideBuilder: (context, day, focusedDay) => Opacity(
                opacity: 0.3,
                child: _buildCalendarDay(day, null, colorScheme),
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
          child: Center(child: Text('Lỗi tải lịch: $err')),
        ),
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
            if (totalIncome > 0)
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

class _ExpenseTile extends ConsumerWidget {
  final Expense expense;
  const _ExpenseTile({required this.expense});

  void _showActions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Chỉnh sửa'),
              onTap: () {
                context.pop();
                context.push('/add-expense', extra: expense);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: Colors.redAccent,
              ),
              title: const Text(
                'Xóa',
                style: TextStyle(color: Colors.redAccent),
              ),
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Xác nhận xóa'),
                    content: const Text(
                      'Bạn có chắc chắn muốn xóa giao dịch này không?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Hủy'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          'Xóa',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  final service = ref.read(isarServiceProvider);
                  await service.deleteExpense(expense.id);

                  final selectedDate = ref.read(selectedDateProvider);
                  final monthKey = DateTime(
                    selectedDate.year,
                    selectedDate.month,
                  );

                  ref.invalidate(todayExpensesProvider);
                  ref.invalidate(dateExpensesProvider(selectedDate));
                  ref.invalidate(monthExpensesProvider(monthKey));
                  ref.invalidate(cumulativeBalanceProvider(selectedDate));
                  ref.invalidate(cashBalanceProvider);
                  ref.invalidate(bankBalanceProvider);

                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          onTap: () => _showActions(context, ref),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getCategoryIcon(expense.category),
              color: colorScheme.onSecondaryContainer,
            ),
          ),
          title: Text(
            expense.note,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          subtitle: Text(
            DateFormat('HH:mm').format(expense.createdAt),
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          trailing: Text(
            '${expense.isIncome ? "+" : "-"}${currencyFormat.format(expense.amount)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: expense.isIncome ? Colors.green : colorScheme.error,
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.foodAndDrink:
        return Icons.restaurant_outlined;
      case ExpenseCategory.transport:
        return Icons.directions_car_outlined;
      case ExpenseCategory.shopping:
        return Icons.shopping_bag_outlined;
      case ExpenseCategory.bills:
        return Icons.receipt_long_outlined;
      case ExpenseCategory.entertainment:
        return Icons.sports_esports_outlined;
      case ExpenseCategory.income:
        return Icons.attach_money_outlined;
      default:
        return Icons.category_outlined;
    }
  }
}
