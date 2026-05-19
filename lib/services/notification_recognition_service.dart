import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:notecash/core/models/user_settings.dart';
import 'package:notecash/core/router.dart';
import 'package:notecash/features/expense/domain/expense.dart';
import 'package:notecash/services/isar_service.dart';
import 'package:notification_listener_service/notification_event.dart';
import 'package:notification_listener_service/notification_listener_service.dart';

@pragma('vm:entry-point')
class NotificationRecognitionService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static IsarService? _isarService;

  static const MethodChannel _permissionChannel = MethodChannel(
    'notecash/notification_permission',
  );

  static final StreamController<ServiceNotificationEvent> _eventController =
      StreamController<ServiceNotificationEvent>.broadcast();
  static Stream<ServiceNotificationEvent> get eventStream =>
      _eventController.stream;

  static StreamSubscription<ServiceNotificationEvent>? _subscription;
  static bool _permissionRequestedThisSession = false;

  static const Map<String, List<String>> _trackedAppPackages = {
    'techcombank': ['vn.com.techcombank.bb.app'],
    'vietinbank': ['com.vietinbank.ipay', 'com.vietinbank.ipaymobile'],
    'timo': ['com.timoapp', 'com.timo'],
    'cake': ['vn.cake', 'com.vpbank.cake'],
    'momo': ['vn.com.momo'],
    'zalopay': ['com.zing.zalopay'],
  };

  static Set<String> _trackedAppKeys = _trackedAppPackages.keys.toSet();

  static void setDatabaseService(IsarService service) {
    _isarService = service;
  }

  static Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload != null) {
          final parts = payload.split('|');
          if (parts.length >= 3) {
            final double amount = double.tryParse(parts[0]) ?? 0;
            final bool isIncome = parts[1] == 'true';
            final String content = parts[2];

            final expense = Expense()
              ..amount = amount
              ..isIncome = isIncome
              ..note = content
              ..category = isIncome
                  ? ExpenseCategory.income
                  : ExpenseCategory.other
              ..createdAt = DateTime.now();

            router.push('/add-expense', extra: expense);
          }
        }
      },
    );
  }

  static void startListening() async {
    final bool hasPermission =
        await NotificationListenerService.isPermissionGranted();

    if (!hasPermission) {
      if (_permissionRequestedThisSession) {
        return;
      }
      _permissionRequestedThisSession = true;
      await _openNotificationListenerSettings();
      return;
    }

    if (_subscription != null) return;
    _subscription = NotificationListenerService.notificationsStream.listen((
      event,
    ) {
      _eventController.add(event);
      _handleNotification(event);
    });
  }

  static Future<void> _openNotificationListenerSettings() async {
    try {
      await _permissionChannel.invokeMethod('openNotificationListenerSettings');
    } catch (_) {}
  }

  static Future<void> updateTrackedApps(Set<String> trackedAppKeys) async {
    _trackedAppKeys = trackedAppKeys;

    final service = _isarService;
    if (service == null) return;

    final settings = await service.getUserSettings() ?? UserSettings();
    settings.trackedNotificationApps = trackedAppKeys.toList();
    settings.updatedAt = DateTime.now();
    await service.saveUserSettings(settings);
  }

  static Future<void> loadTrackedAppsFromDb() async {
    final service = _isarService;
    if (service == null) return;
    final settings = await service.getUserSettings();
    if (settings == null) return;

    final saved = settings.trackedNotificationApps;
    if (saved.isEmpty) return;
    _trackedAppKeys = saved.toSet();
  }

  static void _handleNotification(ServiceNotificationEvent event) {
    final String? content = event.content;
    final String? packageName = event.packageName;

    if (content == null) return;
    if (packageName == null) return;

    final patterns = _trackedAppKeys
        .expand((key) => _trackedAppPackages[key] ?? const <String>[])
        .toList();

    final isTrackedApp = patterns.any(packageName.contains);
    if (!isTrackedApp) return;

    // Also check for keywords in title/content if package name is not specific
    bool containsBankKeywords = content.contains(
      RegExp(r'TK|số dư|biến động|GD|giao dịch', caseSensitive: false),
    );

    if (containsBankKeywords) {
      _processBankNotification(content);
    }
  }

  static void _processBankNotification(String content) {
    // Attempt to parse amount and type from bank notification
    double amount = 0;
    bool isIncome = false;

    // Look for + or - followed by numbers
    final incomeMatch = RegExp(r'\+\s*([0-9,.]+)').firstMatch(content);
    final expenseMatch = RegExp(r'-\s*([0-9,.]+)').firstMatch(content);

    if (incomeMatch != null) {
      isIncome = true;
      amount = _parseAmount(incomeMatch.group(1)!);
    } else if (expenseMatch != null) {
      isIncome = false;
      amount = _parseAmount(expenseMatch.group(1)!);
    } else {
      // Fallback: search for any large number that could be an amount
      final amountMatch = RegExp(
        r'([0-9]{1,3}([,.][0-9]{3})+)',
      ).firstMatch(content);
      if (amountMatch != null) {
        amount = _parseAmount(amountMatch.group(0)!);
      }
    }

    if (amount > 0) {
      _showQuickAddNotification(amount, isIncome, content);
    }
  }

  static double _parseAmount(String str) {
    return double.tryParse(str.replaceAll(',', '').replaceAll('.', '')) ?? 0;
  }

  static Future<void> _showQuickAddNotification(
    double amount,
    bool isIncome,
    String originalContent,
  ) async {
    final String typeStr = isIncome ? 'Thu nhập' : 'Chi tiêu';
    final String amountStr = amount.toStringAsFixed(0);

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'bank_recognition',
          'Nhận diện ngân hàng',
          channelDescription: 'Thông báo khi phát hiện giao dịch ngân hàng',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _notificationsPlugin.show(
      originalContent.hashCode,
      'Phát hiện $typeStr mới',
      'Bạn vừa có giao dịch ${isIncome ? '+' : '-'}$amountStrđ. Nhấn để lưu vào NoteCash!',
      platformChannelSpecifics,
      payload: '$amount|$isIncome|$originalContent',
    );
  }
}
