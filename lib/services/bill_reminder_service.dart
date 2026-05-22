import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:notecash/features/bills/domain/recurring_bill.dart';
import 'package:notecash/services/isar_service.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class BillReminderService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _notificationsPlugin.initialize(settings);
  }

  static Future<void> rescheduleAll(IsarService isarService) async {
    final bills = await isarService.getAllRecurringBills();
    for (final bill in bills) {
      if (bill.isActive) {
        await scheduleReminder(bill);
      } else {
        await cancelReminder(bill.id);
      }
    }
  }

  static Future<void> scheduleReminder(RecurringBill bill) async {
    await cancelReminder(bill.id);
    if (!bill.isActive) return;

    final dueDate = DateTime(
      bill.nextDueDate.year,
      bill.nextDueDate.month,
      bill.nextDueDate.day,
      9,
      0,
    );

    final reminderDate = dueDate.subtract(
      Duration(days: bill.reminderDaysBefore),
    );

    if (dueDate.isBefore(DateTime.now())) return;

    final scheduledDate = reminderDate.isBefore(DateTime.now())
        ? DateTime.now().add(const Duration(seconds: 10))
        : reminderDate;

    try {
      final canScheduleExact =
          await _notificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.canScheduleExactNotifications() ??
          false;

      await _scheduleNotification(
        bill: bill,
        scheduledDate: scheduledDate,
        dueDate: dueDate,
        useExactAlarm: canScheduleExact,
      );
    } catch (e) {
      print('Failed to schedule notification: $e');
      try {
        await _scheduleNotification(
          bill: bill,
          scheduledDate: scheduledDate,
          dueDate: dueDate,
          useExactAlarm: false,
        );
      } catch (e2) {
        print('Failed to schedule inexact notification: $e2');
      }
    }
  }

  static Future<void> _scheduleNotification({
    required RecurringBill bill,
    required DateTime scheduledDate,
    required DateTime dueDate,
    bool useExactAlarm = true,
  }) async {
    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);
    final today = DateTime.now();
    final dayOnlyToday = DateTime(today.year, today.month, today.day);
    final dayOnlyDue = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final days = dayOnlyDue.difference(dayOnlyToday).inDays;
    final timeStr = days == 0
        ? 'hôm nay'
        : days == 1
        ? 'ngày mai'
        : 'sau $days ngày nữa';

    const androidDetails = AndroidNotificationDetails(
      'bill_reminders',
      'Nhắc nhở hóa đơn',
      channelDescription: 'Thông báo nhắc nhở thanh toán hóa đơn định kỳ',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.zonedSchedule(
      bill.id,
      'Nhắc nhở thanh toán: ${bill.name}',
      'Đến hạn thanh toán ${bill.amount.toStringAsFixed(0)}đ $timeStr.',
      tzDate,
      details,
      androidScheduleMode: useExactAlarm
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'bill_${bill.id}',
    );
  }

  static Future<void> cancelReminder(int billId) async {
    await _notificationsPlugin.cancel(billId);
  }
}
