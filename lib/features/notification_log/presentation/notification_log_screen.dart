import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:notecash/core/providers.dart';
import 'package:notecash/features/expense/domain/expense.dart';
import 'package:notecash/features/notification_log/domain/notification_log.dart';

class NotificationLogScreen extends ConsumerWidget {
  const NotificationLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(notificationLogsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Thông báo ứng dụng'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Đánh dấu tất cả đã đọc',
            onPressed: () async {
              final service = ref.read(isarServiceProvider);
              await service.markAllNotificationLogsAsRead();
              ref.invalidate(notificationLogsProvider);
              ref.invalidate(unreadNotificationLogsProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Xóa tất cả',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Xóa thông báo'),
                  content: const Text('Xóa tất cả thông báo đã lưu?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Hủy'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(
                        'Xóa',
                        style: TextStyle(color: colorScheme.error),
                      ),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                final service = ref.read(isarServiceProvider);
                await service.clearAllNotificationLogs();
                ref.invalidate(notificationLogsProvider);
                ref.invalidate(unreadNotificationLogsProvider);
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: logsAsync.when(
        data: (logs) {
          if (logs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none,
                    size: 80, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có thông báo nào',
                    style: TextStyle(
                      fontSize: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bật tính năng trong Cài đặt để bắt đầu theo dõi',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: logs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final log = logs[index];
              return _NotificationLogTile(log: log);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Lỗi: $err')),
      ),
    );
  }
}

class _NotificationLogTile extends ConsumerWidget {
  final NotificationLog log;

  const _NotificationLogTile({required this.log});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final timeStr = DateFormat('HH:mm').format(log.receivedAt);
    final dateStr = DateFormat('dd/MM').format(log.receivedAt);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        if (!log.isRead) {
          final service = ref.read(isarServiceProvider);
          await service.markNotificationLogAsRead(log.id);
          ref.invalidate(notificationLogsProvider);
          ref.invalidate(unreadNotificationLogsProvider);
        }
        if (log.isBankRelated && log.parsedAmount != null && log.text != null) {
          _showBankActionSheet(context, ref, log);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: log.isRead
              ? Colors.transparent
              : colorScheme.primaryContainer.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: log.isRead
                ? colorScheme.outlineVariant.withValues(alpha: 0.3)
                : colorScheme.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: log.isBankRelated
                    ? colorScheme.tertiaryContainer
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                log.isBankRelated ? Icons.account_balance : Icons.apps,
                size: 20,
                color: log.isBankRelated
                    ? colorScheme.onTertiaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          log.packageName ?? 'Không xác định',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$dateStr $timeStr',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (log.title != null && log.title!.isNotEmpty)
                    Text(
                      log.title!,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (log.text != null && log.text!.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: log.title != null ? 2 : 0),
                      child: Text(
                        log.text!,
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (log.isBankRelated && log.parsedAmount != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          Icon(
                            log.isIncome == true
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            size: 16,
                            color: log.isIncome == true
                                ? Colors.greenAccent
                                : Colors.redAccent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            NumberFormat.currency(locale: 'vi', symbol: 'đ')
                                .format(log.parsedAmount),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: log.isIncome == true
                                  ? Colors.greenAccent
                                  : Colors.redAccent,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.tertiaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Ngân hàng',
                              style: TextStyle(
                                fontSize: 10,
                                color: colorScheme.onTertiaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            if (!log.isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

void _showBankActionSheet(
    BuildContext context, WidgetRef ref, NotificationLog log) {
  showModalBottomSheet(
    context: context,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Giao dịch ngân hàng',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            log.text ?? '',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                log.isIncome == true ? Icons.arrow_upward : Icons.arrow_downward,
                color: log.isIncome == true ? Colors.greenAccent : Colors.redAccent,
              ),
              const SizedBox(width: 8),
              Text(
                NumberFormat.currency(locale: 'vi', symbol: '')
                    .format(log.parsedAmount),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 4),
              Text(
                'đ',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Thêm vào giao dịch'),
              onPressed: () {
                final expense = Expense()
                  ..amount = log.parsedAmount ?? 0
                  ..isIncome = log.isIncome ?? false
                  ..note = log.text ?? ''
                  ..category = (log.isIncome == true)
                      ? ExpenseCategory.income
                      : ExpenseCategory.other
                  ..createdAt = DateTime.now();
                Navigator.pop(ctx);
                context.push('/add-expense', extra: expense);
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
