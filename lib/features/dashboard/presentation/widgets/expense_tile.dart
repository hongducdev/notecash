import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:notecash/core/providers.dart';
import 'package:notecash/features/expense/domain/expense.dart';

class ExpenseTile extends ConsumerWidget {
  final Expense expense;
  const ExpenseTile({super.key, required this.expense});

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
                  final selectedDateNormalized = DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                  );
                  final selectedMonthKey = DateTime(
                    selectedDate.year,
                    selectedDate.month,
                  );

                  final expenseDate = DateTime(
                    expense.createdAt.year,
                    expense.createdAt.month,
                    expense.createdAt.day,
                  );
                  final expenseMonthKey = DateTime(
                    expense.createdAt.year,
                    expense.createdAt.month,
                  );

                  ref.invalidate(todayExpensesProvider);
                  ref.invalidate(allExpensesProvider);
                  ref.invalidate(dateExpensesProvider(expenseDate));
                  ref.invalidate(monthExpensesProvider(expenseMonthKey));
                  ref.invalidate(cumulativeBalanceProvider(expenseDate));

                  if (expenseDate != selectedDateNormalized) {
                    ref.invalidate(
                      dateExpensesProvider(selectedDateNormalized),
                    );
                    ref.invalidate(
                      cumulativeBalanceProvider(selectedDateNormalized),
                    );
                  }

                  if (expenseMonthKey != selectedMonthKey) {
                    ref.invalidate(monthExpensesProvider(selectedMonthKey));
                  }

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
