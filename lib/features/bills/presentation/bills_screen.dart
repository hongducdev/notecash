import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:notecash/core/providers.dart';
import 'package:notecash/features/bills/domain/recurring_bill.dart';
import 'package:intl/intl.dart';

class BillsScreen extends ConsumerStatefulWidget {
  const BillsScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _BillsScreenState();
}

class _BillsScreenState extends ConsumerState<BillsScreen> {
  @override
  Widget build(BuildContext context) {
    final billsAsync = ref.watch(recurringBillsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Hóa đơn định kỳ')),
      body: billsAsync.when(
        data: (bills) {
          if (bills.isEmpty) {
            return Center(
              child: Text(
                'Chưa có hóa đơn nào',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            );
          }
          return ListView.separated(
            itemCount: bills.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final bill = bills[index];
              final dueStr = bill.daysUntilDue == 0
                  ? 'Hôm nay'
                  : bill.daysUntilDue == 1
                  ? 'Ngày mai'
                  : 'Sau ${bill.daysUntilDue} ngày';
              final amountStr = NumberFormat.currency(
                locale: 'vi_VN',
                symbol: '',
                decimalDigits: 0,
              ).format(bill.amount);
              return ListTile(
                title: Text(bill.name),
                subtitle: Text(
                  '${bill.getFrequencyLabel()} • $amountStrđ • $dueStr',
                ),
                trailing: Icon(
                  bill.isActive
                      ? Icons.check_circle
                      : Icons.pause_circle_filled,
                  color: bill.isActive ? Colors.green : Colors.red,
                ),
                onTap: () => context.push('/add-bill', extra: bill),
                onLongPress: () => _showActions(bill),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
      ),
    );
  }

  void _showActions(RecurringBill bill) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Sửa'),
            onTap: () {
              Navigator.pop(context);
              context.push('/add-bill', extra: bill);
            },
          ),
          ListTile(
            leading: const Icon(Icons.check),
            title: const Text('Đánh dấu đã thanh toán'),
            onTap: () async {
              Navigator.pop(context);
              final service = ref.read(isarServiceProvider);
              await service.markBillAsPaid(bill);
              ref.invalidate(recurringBillsProvider);
              ref.invalidate(upcomingBillsProvider);
              ref.invalidate(allExpensesProvider);
              ref.invalidate(cashBalanceProvider);
              ref.invalidate(bankBalanceProvider);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Xóa'),
            onTap: () async {
              Navigator.pop(context);
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('Xác nhận'),
                  content: const Text('Bạn có chắc muốn xóa hóa đơn này?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('Hủy'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: const Text('Xóa'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                final service = ref.read(isarServiceProvider);
                await service.deleteRecurringBill(bill.id);
                ref.invalidate(recurringBillsProvider);
                ref.invalidate(upcomingBillsProvider);
              }
            },
          ),
        ],
      ),
    );
  }
}
