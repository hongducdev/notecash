import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:notecash/core/providers.dart';
import 'package:notecash/features/bills/presentation/widgets/bill_tile.dart';
import 'package:notecash/features/dashboard/presentation/widgets/dashboard_calendar.dart';
import 'package:notecash/features/dashboard/presentation/widgets/expense_tile.dart';
import 'package:notecash/shared/widgets/app_logo.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final dateExpensesAsync = ref.watch(dateExpensesProvider(selectedDate));
    final monthKey = DateTime(selectedDate.year, selectedDate.month);
    final monthExpensesAsync = ref.watch(monthExpensesProvider(monthKey));
    final recurringBillsAsync = ref.watch(recurringBillsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              title: const AppLogo(size: 32),
              actions: const [SizedBox(width: 8)],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSpendingOverview(context, ref),
                    const SizedBox(height: 24),
                    DashboardCalendar(
                      monthExpensesAsync: monthExpensesAsync,
                      recurringBillsAsync: recurringBillsAsync,
                      selectedDate: selectedDate,
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
            recurringBillsAsync.when(
              data: (allBills) {
                final selectedDay = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                );
                final dueBills = allBills.where((bill) {
                  if (!bill.isActive) return false;
                  final dueDate = DateTime(
                    bill.nextDueDate.year,
                    bill.nextDueDate.month,
                    bill.nextDueDate.day,
                  );
                  return dueDate == selectedDay;
                }).toList();

                return dateExpensesAsync.when(
                  data: (expenses) {
                    if (expenses.isEmpty && dueBills.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Text(
                              'Không có giao dịch nào trong ngày này',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                    return SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        if (index < dueBills.length) {
                          return BillTile(bill: dueBills[index]);
                        }
                        final expense = expenses[index - dueBills.length];
                        return ExpenseTile(expense: expense);
                      }, childCount: dueBills.length + expenses.length),
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
}
