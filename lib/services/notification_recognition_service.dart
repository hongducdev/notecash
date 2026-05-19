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

  static const List<String> _legacyDefaultTrackedAppKeys = [
    'techcombank',
    'vietinbank',
    'timo',
    'cake',
    'momo',
    'zalopay',
  ];

  static Set<String> _trackedAppKeys = {};
  static Set<String> _trackedPackageNames = {};

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
              ..paymentMethod = PaymentMethod.bank
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
    _trackedPackageNames = {};

    final service = _isarService;
    if (service == null) return;

    final settings = await service.getUserSettings() ?? UserSettings();
    settings.trackedNotificationApps = trackedAppKeys.toList();
    settings.trackedNotificationPackages = [];
    settings.updatedAt = DateTime.now();
    await service.saveUserSettings(settings);
  }

  static Future<void> updateTrackedPackages(
    Set<String> trackedPackageNames,
  ) async {
    _trackedPackageNames = trackedPackageNames;
    _trackedAppKeys = {};

    final service = _isarService;
    if (service == null) return;

    final settings = await service.getUserSettings() ?? UserSettings();
    settings.trackedNotificationPackages = trackedPackageNames.toList();
    settings.trackedNotificationApps = [];
    settings.updatedAt = DateTime.now();
    await service.saveUserSettings(settings);
  }

  static Future<void> loadTrackedAppsFromDb() async {
    final service = _isarService;
    if (service == null) return;
    final settings = await service.getUserSettings();
    if (settings == null) return;

    final savedPackages = settings.trackedNotificationPackages;
    if (savedPackages.isNotEmpty) {
      final legacyDefaultPackages = packagesForAppKeys(
        _legacyDefaultTrackedAppKeys.toSet(),
      ).toSet();
      final savedSet = savedPackages.toSet();
      final isLegacyDefaultSelection =
          savedSet.length == legacyDefaultPackages.length &&
          savedSet.containsAll(legacyDefaultPackages);

      if (isLegacyDefaultSelection) {
        settings.trackedNotificationApps = [];
        settings.trackedNotificationPackages = [];
        settings.updatedAt = DateTime.now();
        await service.saveUserSettings(settings);
        _trackedPackageNames = {};
        _trackedAppKeys = {};
        return;
      }

      _trackedPackageNames = savedPackages.toSet();
      _trackedAppKeys = {};
      return;
    }

    if (settings.trackedNotificationApps.isNotEmpty) {
      settings.trackedNotificationApps = [];
      settings.trackedNotificationPackages = [];
      settings.updatedAt = DateTime.now();
      await service.saveUserSettings(settings);
    }
    _trackedPackageNames = {};
    _trackedAppKeys = {};
  }

  static List<String> packagesForAppKeys(Set<String> trackedAppKeys) {
    return trackedAppKeys
        .expand((key) => _trackedAppPackages[key] ?? const <String>[])
        .toList();
  }

  static void _handleNotification(ServiceNotificationEvent event) {
    final String? content = event.content;
    final String? packageName = event.packageName;

    if (content == null) return;
    if (packageName == null) return;

    if (_trackedPackageNames.isNotEmpty) {
      if (!_trackedPackageNames.contains(packageName)) return;
    } else {
      if (_trackedAppKeys.isEmpty) return;
      final patterns = packagesForAppKeys(_trackedAppKeys);
      final isTrackedApp = patterns.any(packageName.contains);
      if (!isTrackedApp) return;
    }

    // Also check for keywords in title/content if package name is not specific
    final parsed = _parseBankNotification(content);
    if (parsed == null) return;
    _showQuickAddNotification(parsed.amount, parsed.isIncome, content);
  }

  static _ParsedBankNotification? _parseBankNotification(String content) {
    final lower = content.toLowerCase();

    final isDebit = RegExp(
      r'ghi\s*n[ợo]|trừ|thanh\s*toán|chi\s*tiêu|mua\s*hàng|rút\s*tiền',
      caseSensitive: false,
    ).hasMatch(content);

    final isCredit = RegExp(
      r'ghi\s*c[oó]|cộng|nhận|hoàn\s*tiền|chuyển\s*đến|tiền\s*vào',
      caseSensitive: false,
    ).hasMatch(content);

    bool? isIncome;
    if (isCredit && !isDebit) isIncome = true;
    if (isDebit && !isCredit) isIncome = false;

    final signed = RegExp(
      r'([+-])\s*([0-9][0-9., ]{0,20})',
    ).allMatches(content);
    for (final m in signed) {
      final sign = m.group(1);
      final raw = m.group(2);
      if (raw == null) continue;
      final amount = _parseAmount(raw);
      if (amount <= 0) continue;

      final idx = m.start;
      final aroundStart = (idx - 16).clamp(0, content.length);
      final aroundEnd = (idx + 32).clamp(0, content.length);
      final around = content.substring(aroundStart, aroundEnd).toLowerCase();
      if (RegExp(
        r'số\s*dư|so\s*du|balance|sd\s*[:#]?',
        caseSensitive: false,
      ).hasMatch(around)) {
        continue;
      }

      return _ParsedBankNotification(amount: amount, isIncome: sign == '+');
    }

    final withCurrency = RegExp(
      r'([0-9][0-9., ]{0,20})\s*(vnd|vnđ|đ)\b',
      caseSensitive: false,
    ).allMatches(content);

    for (final m in withCurrency) {
      final raw = m.group(1);
      if (raw == null) continue;
      final amount = _parseAmount(raw);
      if (amount <= 0) continue;

      final idx = m.start;
      final aroundStart = (idx - 24).clamp(0, content.length);
      final aroundEnd = (idx + 40).clamp(0, content.length);
      final around = content.substring(aroundStart, aroundEnd).toLowerCase();
      if (RegExp(
        r'số\s*dư|so\s*du|balance|sd\s*[:#]?',
        caseSensitive: false,
      ).hasMatch(around)) {
        continue;
      }
      if (RegExp(
        r'hạn\s*mức|han\s*muc|phí|fee',
        caseSensitive: false,
      ).hasMatch(around)) {
        continue;
      }

      final decidedIsIncome =
          isIncome ?? _inferIncomeFromContext(lower, around) ?? false;

      return _ParsedBankNotification(amount: amount, isIncome: decidedIsIncome);
    }

    return null;
  }

  static bool? _inferIncomeFromContext(String lower, String around) {
    if (around.contains('ghi có') || around.contains('ghi co')) return true;
    if (around.contains('ghi nợ') || around.contains('ghi no')) return false;
    if (lower.contains('ghi có') || lower.contains('ghi co')) return true;
    if (lower.contains('ghi nợ') || lower.contains('ghi no')) return false;
    return null;
  }

  static double _parseAmount(String str) {
    final normalized = str.replaceAll(RegExp(r'[^0-9]'), '');
    if (normalized.isEmpty) return 0;
    return double.tryParse(normalized) ?? 0;
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

class _ParsedBankNotification {
  final double amount;
  final bool isIncome;

  const _ParsedBankNotification({required this.amount, required this.isIncome});
}
