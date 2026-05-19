import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:notecash/core/router.dart';
import 'package:notecash/features/expense/domain/expense.dart';
import 'package:notecash/features/notification_log/domain/notification_log.dart';
import 'package:notecash/services/isar_service.dart';

class NotificationRecognitionService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static IsarService? _isarService;

  static bool _isListening = false;

  static void setDatabaseService(IsarService service) {
    _isarService = service;
  }

  static Future<void> init() async {
    _isListening = false;
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

    await NotificationsListener.initialize();
    debugPrint('[NotiService] Initialized');
  }

  static Future<void> startListening() async {
    bool hasPermission = await NotificationsListener.hasPermission ?? false;
    debugPrint('[NotiService] hasPermission: $hasPermission');
    if (hasPermission) {
      _setupReceivePortListener();
      bool isRunning = await NotificationsListener.isRunning ?? false;
      debugPrint('[NotiService] isRunning: $isRunning');
      if (!isRunning) {
        final started = await NotificationsListener.startService(
          title: 'NoteCash',
          description: 'Đang theo dõi thông báo',
        );
        debugPrint('[NotiService] startService result: $started');
      }
    }
  }

  static void _setupReceivePortListener() {
    if (_isListening) {
      debugPrint('[NotiService] Already listening, skipping');
      return;
    }
    final port = NotificationsListener.receivePort;
    if (port == null) {
      debugPrint('[NotiService] receivePort is null');
      return;
    }
    _isListening = true;
    debugPrint('[NotiService] Setting up ReceivePort listener');
    port.listen((event) {
      debugPrint('[NotiService] Received event: $event');
      if (event is NotificationEvent) {
        _handleNotification(event);
      }
    });
  }

  static Future<void> setupListenerAfterPermission() async {
    _setupReceivePortListener();
    bool isRunning = await NotificationsListener.isRunning ?? false;
    debugPrint('[NotiService] setupListenerAfterPermission - isRunning: $isRunning');
    if (!isRunning) {
      await NotificationsListener.startService(
        title: 'NoteCash',
        description: 'Đang theo dõi thông báo',
      );
    }
  }

  static void _handleNotification(NotificationEvent event) {
    final String? title = event.title;
    final String? content = event.text;
    final String? packageName = event.packageName;

    debugPrint('[NotiService] Handling notification from: $packageName');

    bool isBank = false;
    double? parsedAmount;
    bool? isIncome;

    if (content != null) {
      final bankPackages = [
        'com.vcb',
        'com.tpb.mbanking',
        'vn.com.techcombank.bb.app',
        'com.mbmobile',
        'com.vnpay.vcb',
        'vn.com.momo',
        'com.zing.zalopay',
      ];

      bool isBankApp = bankPackages.any(
        (pkg) => packageName?.contains(pkg) ?? false,
      );

      bool containsBankKeywords = content.contains(
        RegExp(r'TK|số dư|biến động|GD|giao dịch', caseSensitive: false),
      );

      isBank = isBankApp || containsBankKeywords;
      debugPrint('[NotiService] isBank: $isBank (app: $isBankApp, keywords: $containsBankKeywords)');

      if (isBank) {
        final result = _parseBankAmount(content);
        parsedAmount = result.amount;
        isIncome = result.isIncome;
        debugPrint('[NotiService] Parsed amount: $parsedAmount, isIncome: $isIncome');
      }
    }

    unawaited(_saveAndNotify(title, content, packageName, isBank, parsedAmount, isIncome));
  }

  static Future<void> _saveAndNotify(
    String? title,
    String? content,
    String? packageName,
    bool isBank,
    double? parsedAmount,
    bool? isIncome,
  ) async {
    try {
      final log = NotificationLog()
        ..title = title
        ..text = content
        ..packageName = packageName
        ..receivedAt = DateTime.now()
        ..isBankRelated = isBank
        ..parsedAmount = parsedAmount
        ..isIncome = isIncome;
      await _isarService?.saveNotificationLog(log);

      if (isBank && (parsedAmount ?? 0) > 0) {
        await _showQuickAddNotification(parsedAmount!, isIncome ?? false, content ?? '');
      }
    } catch (e) {
      debugPrint('[NotiService] Error saving notification: $e');
    }
  }

  static ({double amount, bool isIncome}) _parseBankAmount(String content) {
    double amount = 0;
    bool isIncome = false;

    final incomeMatch = RegExp(r'\+\s*([0-9,.]+)').firstMatch(content);
    final expenseMatch = RegExp(r'-\s*([0-9,.]+)').firstMatch(content);

    if (incomeMatch != null) {
      isIncome = true;
      amount = _parseAmount(incomeMatch.group(1)!);
    } else if (expenseMatch != null) {
      isIncome = false;
      amount = _parseAmount(expenseMatch.group(1)!);
    } else {
      final amountMatch = RegExp(
        r'([0-9]{1,3}([,.][0-9]{3})+)',
      ).firstMatch(content);
      if (amountMatch != null) {
        amount = _parseAmount(amountMatch.group(0)!);
      }
    }

    return (amount: amount, isIncome: isIncome);
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
