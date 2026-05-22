import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:notecash/core/providers.dart';
import 'package:notecash/features/bills/domain/recurring_bill.dart';
import 'package:notecash/features/bills/utils/bill_icon_utils.dart';

class BillTile extends ConsumerWidget {
  final RecurringBill bill;
  const BillTile({super.key, required this.bill});

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
                context.push('/add-bill', extra: bill);
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: const Text('Đánh dấu đã thanh toán'),
              onTap: () async {
                context.pop();
                final service = ref.read(isarServiceProvider);
                await service.markBillAsPaid(bill);
                final selectedDate = ref.read(selectedDateProvider);
                final monthKey = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                );
                ref.invalidate(recurringBillsProvider);
                ref.invalidate(upcomingBillsProvider);
                ref.invalidate(dateExpensesProvider(selectedDate));
                ref.invalidate(monthExpensesProvider(monthKey));
                ref.invalidate(allExpensesProvider);
                ref.invalidate(cashBalanceProvider);
                ref.invalidate(bankBalanceProvider);
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
                      'Bạn có chắc chắn muốn xóa hóa đơn này không?',
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
                  await service.deleteRecurringBill(bill.id);
                  ref.invalidate(recurringBillsProvider);
                  ref.invalidate(upcomingBillsProvider);

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
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '',
      decimalDigits: 0,
    );
    final colorScheme = Theme.of(context).colorScheme;

    final dueStr = bill.daysUntilDue == 0
        ? 'Hôm nay'
        : bill.daysUntilDue == 1
        ? 'Ngày mai'
        : bill.daysUntilDue < 0
        ? 'Quá hạn ${-bill.daysUntilDue} ngày'
        : 'Sau ${bill.daysUntilDue} ngày';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Card(
        margin: EdgeInsets.zero,
        color: bill.isOverdue
            ? colorScheme.errorContainer.withValues(alpha: 0.3)
            : null,
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
            child: BillIconUtils.getIconWidget(bill.name, colorScheme),
          ),
          title: Text(
            bill.name,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          subtitle: Text(
            '${bill.getFrequencyLabel()} • ${currencyFormat.format(bill.amount)}₫ • $dueStr',
            style: TextStyle(
              color: bill.isOverdue
                  ? colorScheme.error
                  : colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
          trailing: Icon(
            Icons.receipt_long,
            color: bill.isOverdue ? colorScheme.error : colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
