import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:isar/isar.dart';
import 'package:notecash/core/models/user_settings.dart';
import 'package:notecash/core/router.dart';
import 'package:notecash/features/expense/domain/expense.dart';
import 'package:notecash/services/isar_service.dart';
import 'package:notification_listener_service/notification_event.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:path_provider/path_provider.dart';

@pragma('vm:entry-point')
class NotificationRecognitionService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _quickAddActionId = 'quick_add_amount_input';
  static const String _quickAddFallbackActionId = 'quick_add_open_app';

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

  static bool get isListening => _subscription != null;

  static final Map<String, DateTime> _recentFallbackByPackage =
      <String, DateTime>{};

  static final RegExp _debitRegex = RegExp(
    r'ghi\s*n[ợo]|trừ|thanh\s*toán|chi\s*tiêu|mua\s*hàng|rút\s*tiền|giảm|giam',
    caseSensitive: false,
  );
  static final RegExp _creditRegex = RegExp(
    r'ghi\s*c[oó]|cộng|nhận|hoàn\s*tiền|chuyển\s*đến|tiền\s*vào|tăng|tang',
    caseSensitive: false,
  );
  static final RegExp _signedAmountRegex = RegExp(
    r'([+-])\s*([0-9][0-9., ]{0,20})',
  );
  static final RegExp _signedCurrencyBeforeAmountRegex = RegExp(
    r'([+-])\s*(vnd|vnđ|đ)\s*([0-9][0-9., ]{0,20})',
    caseSensitive: false,
  );
  static final RegExp _amountWithCurrencyRegex = RegExp(
    r'([0-9][0-9., ]{0,20})\s*(vnd|vnđ|đ)\b',
    caseSensitive: false,
  );
  static final RegExp _currencyBeforeAmountRegex = RegExp(
    r'\b(vnd|vnđ|đ)\s*([0-9][0-9., ]{0,20})',
    caseSensitive: false,
  );
  static final RegExp _increaseDecreaseAmountRegex = RegExp(
    r'\b(tăng|tang|giảm|giam)\b(?:\s*/\s*(tăng|tang|giảm|giam))?\s*[:\-]?\s*([0-9][0-9., ]{0,20})',
    caseSensitive: false,
  );
  static final RegExp _balanceRegex = RegExp(
    r'số\s*dư|so\s*du|balance|sd\s*[:#]?',
    caseSensitive: false,
  );
  static final RegExp _feeRegex = RegExp(
    r'hạn\s*mức|han\s*muc|phí|fee',
    caseSensitive: false,
  );

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
  static List<String> _trackedPackagePatterns = const <String>[];

  static void setDatabaseService(IsarService service) {
    _isarService = service;
  }

  static void _rebuildTrackedPatterns() {
    if (_trackedAppKeys.isEmpty) {
      _trackedPackagePatterns = const <String>[];
      return;
    }
    _trackedPackagePatterns = packagesForAppKeys(_trackedAppKeys);
  }

  static Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.actionId == _quickAddActionId) {
          final input = (response.input ?? '').trim();
          final payload = (response.payload ?? '').trim();
          unawaited(
            _saveExpenseFromInlineInput(input: input, payload: payload),
          );
          return;
        }

        if (response.actionId == _quickAddFallbackActionId) {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) {
            final expense = Expense()
              ..amount = 0
              ..isIncome = false
              ..note = payload
              ..category = ExpenseCategory.other
              ..paymentMethod = PaymentMethod.bank
              ..createdAt = DateTime.now();

            router.push('/add-expense', extra: expense);
          }
          return;
        }

        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
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
          } else {
            final expense = Expense()
              ..amount = 0
              ..isIncome = false
              ..note = payload
              ..category = ExpenseCategory.other
              ..paymentMethod = PaymentMethod.bank
              ..createdAt = DateTime.now();

            router.push('/add-expense', extra: expense);
          }
        }
      },
      onDidReceiveBackgroundNotificationResponse:
          notificationTapBackgroundHandler,
    );
  }

  static Future<void> startListening() async {
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
    _subscription = NotificationListenerService.notificationsStream.listen(
      (event) {
        _eventController.add(event);
        _handleNotification(event);
      },
      onError: (Object error, StackTrace stackTrace) {
        _subscription = null;
      },
      onDone: () {
        _subscription = null;
      },
    );
  }

  static Future<void> _ensureQuickAddNotificationPermission() async {
    final android = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return;

    final enabled = await android.areNotificationsEnabled();
    if (enabled == true) return;

    await android.requestNotificationsPermission();
  }

  static Future<bool> areQuickAddNotificationsEnabled() async {
    final android = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return true;
    return await android.areNotificationsEnabled() ?? true;
  }

  static Future<void> requestQuickAddNotificationPermission() async {
    await _ensureQuickAddNotificationPermission();
  }

  static Future<void> _openNotificationListenerSettings() async {
    try {
      await _permissionChannel.invokeMethod('openNotificationListenerSettings');
    } catch (_) {}
  }

  static Future<void> updateTrackedApps(Set<String> trackedAppKeys) async {
    _trackedAppKeys = trackedAppKeys;
    _trackedPackageNames = {};
    _rebuildTrackedPatterns();

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
    _trackedPackagePatterns = const <String>[];

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
        _trackedPackagePatterns = const <String>[];
        return;
      }

      _trackedPackageNames = savedPackages.toSet();
      _trackedAppKeys = {};
      _trackedPackagePatterns = const <String>[];
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
    _trackedPackagePatterns = const <String>[];
  }

  static List<String> packagesForAppKeys(Set<String> trackedAppKeys) {
    return trackedAppKeys
        .expand((key) => _trackedAppPackages[key] ?? const <String>[])
        .toList();
  }

  static void _handleNotification(ServiceNotificationEvent event) {
    final String? title = event.title;
    final String? content = event.content;
    final String? packageName = event.packageName;

    if (packageName == null) return;
    if (packageName == 'com.hongducdev.notecash') return;

    final String merged = _mergeNotificationText(title, content);
    if (merged.isEmpty) return;

    if (_trackedPackageNames.isNotEmpty) {
      if (!_trackedPackageNames.contains(packageName)) return;
    } else {
      if (_trackedPackagePatterns.isEmpty) return;
      final isTrackedApp = _trackedPackagePatterns.any(packageName.contains);
      if (!isTrackedApp) return;
    }

    final parsed = _parseBankNotification(merged);
    if (parsed == null) {
      final now = DateTime.now();
      final last = _recentFallbackByPackage[packageName];
      if (last == null || now.difference(last) > const Duration(seconds: 20)) {
        _recentFallbackByPackage[packageName] = now;
        final lower = merged.toLowerCase();
        final inferred =
            _inferIncomeFromContext(lower, lower) ??
            _inferIncomeFromContext(lower, packageName.toLowerCase());
        _showManualEntryNotification(merged, isIncome: inferred ?? false);
      }
      return;
    }
    _showQuickAddNotification(parsed.amount, parsed.isIncome, merged);
  }

  static String _mergeNotificationText(String? title, String? content) {
    final t = (title ?? '').trim();
    final c = (content ?? '').trim();
    if (t.isEmpty) return c;
    if (c.isEmpty) return t;
    return '$t\n$c';
  }

  static _ParsedBankNotification? _parseBankNotification(String content) {
    final lower = content.toLowerCase();

    final isDebit = _debitRegex.hasMatch(content);
    final isCredit = _creditRegex.hasMatch(content);

    bool? isIncome;
    if (isCredit && !isDebit) isIncome = true;
    if (isDebit && !isCredit) isIncome = false;

    final signedCurrencyFirst = _signedCurrencyBeforeAmountRegex.allMatches(
      content,
    );
    for (final m in signedCurrencyFirst) {
      final sign = m.group(1);
      final raw = m.group(3);
      if (raw == null) continue;
      final amount = _parseAmount(raw);
      if (amount <= 0) continue;

      final idx = m.start;
      final aroundStart = (idx - 16).clamp(0, content.length);
      final aroundEnd = (idx + 32).clamp(0, content.length);
      final around = content.substring(aroundStart, aroundEnd).toLowerCase();
      if (_balanceRegex.hasMatch(around) || _feeRegex.hasMatch(around)) {
        continue;
      }

      return _ParsedBankNotification(amount: amount, isIncome: sign == '+');
    }

    final signed = _signedAmountRegex.allMatches(content);
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
      if (_balanceRegex.hasMatch(around)) {
        continue;
      }

      return _ParsedBankNotification(amount: amount, isIncome: sign == '+');
    }

    final incDec = _increaseDecreaseAmountRegex.allMatches(content);
    for (final m in incDec) {
      final keyword1 = m.group(1);
      final keyword2 = m.group(2);
      final raw = m.group(3);
      if (keyword1 == null || raw == null) continue;
      final amount = _parseAmount(raw);
      if (amount <= 0) continue;

      final idx = m.start;
      final aroundStart = (idx - 24).clamp(0, content.length);
      final aroundEnd = (idx + 40).clamp(0, content.length);
      final around = content.substring(aroundStart, aroundEnd).toLowerCase();
      if (_feeRegex.hasMatch(around)) {
        continue;
      }

      final k1 = keyword1.toLowerCase();
      final k2 = keyword2?.toLowerCase();
      final decidedIsIncome = (k2 != null && k2 != k1)
          ? (isIncome ?? _inferIncomeFromContext(lower, around) ?? false)
          : (k1 == 'tăng' || k1 == 'tang');
      return _ParsedBankNotification(amount: amount, isIncome: decidedIsIncome);
    }

    final currencyFirst = _currencyBeforeAmountRegex.allMatches(content);
    for (final m in currencyFirst) {
      final raw = m.group(2);
      if (raw == null) continue;
      final amount = _parseAmount(raw);
      if (amount <= 0) continue;

      final idx = m.start;
      final aroundStart = (idx - 24).clamp(0, content.length);
      final aroundEnd = (idx + 40).clamp(0, content.length);
      final around = content.substring(aroundStart, aroundEnd).toLowerCase();
      if (_balanceRegex.hasMatch(around) || _feeRegex.hasMatch(around)) {
        continue;
      }

      final decidedIsIncome =
          isIncome ?? _inferIncomeFromContext(lower, around) ?? false;
      return _ParsedBankNotification(amount: amount, isIncome: decidedIsIncome);
    }

    final withCurrency = _amountWithCurrencyRegex.allMatches(content);

    for (final m in withCurrency) {
      final raw = m.group(1);
      if (raw == null) continue;
      final amount = _parseAmount(raw);
      if (amount <= 0) continue;

      final idx = m.start;
      final aroundStart = (idx - 24).clamp(0, content.length);
      final aroundEnd = (idx + 40).clamp(0, content.length);
      final around = content.substring(aroundStart, aroundEnd).toLowerCase();
      if (_balanceRegex.hasMatch(around)) {
        continue;
      }
      if (_feeRegex.hasMatch(around)) {
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
    if (around.contains('tăng') || around.contains('tang')) return true;
    if (around.contains('giảm') || around.contains('giam')) return false;
    if (lower.contains('ghi có') || lower.contains('ghi co')) return true;
    if (lower.contains('ghi nợ') || lower.contains('ghi no')) return false;
    if (lower.contains('tăng') || lower.contains('tang')) return true;
    if (lower.contains('giảm') || lower.contains('giam')) return false;
    return null;
  }

  static double _parseAmount(String str) {
    final lower = str.toLowerCase().trim();
    double multiplier = 1;
    if (lower.endsWith('k')) {
      multiplier = 1000;
    } else if (lower.endsWith('m') || lower.endsWith('tr')) {
      multiplier = 1000000;
    }

    final normalized = lower.replaceAll(RegExp(r'[^0-9]'), '');
    if (normalized.isEmpty) return 0;
    final base = double.tryParse(normalized) ?? 0;
    return base * multiplier;
  }

  static Future<void> _saveExpenseFromInlineInput({
    required String input,
    required String payload,
  }) async {
    if (input.isEmpty || payload.isEmpty) return;

    final amount = _parseAmount(input);
    if (amount <= 0) return;

    final lower = payload.toLowerCase();
    final isIncome = _inferIncomeFromContext(lower, lower) ?? false;

    final expense = Expense()
      ..amount = amount
      ..isIncome = isIncome
      ..note = payload
      ..category = isIncome ? ExpenseCategory.income : ExpenseCategory.other
      ..paymentMethod = PaymentMethod.bank
      ..createdAt = DateTime.now();

    final service = _isarService;
    if (service != null) {
      await service.saveExpense(expense);
      return;
    }

    WidgetsFlutterBinding.ensureInitialized();
    final dir = await getApplicationDocumentsDirectory();
    final isar = await Isar.open([
      ExpenseSchema,
      UserSettingsSchema,
    ], directory: dir.path);
    await isar.writeTxn(() async {
      await isar.expenses.put(expense);
    });
    await isar.close();
  }

  static Future<void> _showQuickAddNotification(
    double amount,
    bool isIncome,
    String originalContent,
  ) async {
    await _ensureQuickAddNotificationPermission();

    final android = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      final enabled = await android.areNotificationsEnabled();
      if (enabled != true) return;
    }

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
          actions: [
            AndroidNotificationAction(
              _quickAddActionId,
              'Nhập số tiền',
              showsUserInterface: false,
              inputs: [
                AndroidNotificationActionInput(label: 'Số tiền (vd: 35k)'),
              ],
            ),
            AndroidNotificationAction(
              _quickAddFallbackActionId,
              'Mở NoteCash',
              showsUserInterface: true,
            ),
          ],
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

  static Future<void> _showManualEntryNotification(
    String originalContent, {
    required bool isIncome,
  }) async {
    await _ensureQuickAddNotificationPermission();

    final android = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      final enabled = await android.areNotificationsEnabled();
      if (enabled != true) return;
    }

    final String typeStr = isIncome ? 'Thu nhập' : 'Chi tiêu';

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'bank_recognition',
          'Nhận diện ngân hàng',
          channelDescription: 'Thông báo khi phát hiện giao dịch ngân hàng',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
          actions: [
            AndroidNotificationAction(
              _quickAddActionId,
              'Nhập số tiền',
              showsUserInterface: false,
              inputs: [
                AndroidNotificationActionInput(label: 'Số tiền (vd: 35k)'),
              ],
            ),
            AndroidNotificationAction(
              _quickAddFallbackActionId,
              'Mở NoteCash',
              showsUserInterface: true,
            ),
          ],
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _notificationsPlugin.show(
      originalContent.hashCode ^ 0x5a5a5a,
      'Nhập $typeStr thủ công',
      'Không đọc được số tiền. Nhập nhanh ngay trên thông báo.',
      platformChannelSpecifics,
      payload: originalContent,
    );
  }
}

class _ParsedBankNotification {
  final double amount;
  final bool isIncome;

  const _ParsedBankNotification({required this.amount, required this.isIncome});
}

@pragma('vm:entry-point')
Future<void> notificationTapBackgroundHandler(
  NotificationResponse response,
) async {
  if (response.actionId != NotificationRecognitionService._quickAddActionId) {
    return;
  }
  final input = (response.input ?? '').trim();
  final payload = (response.payload ?? '').trim();
  await NotificationRecognitionService._saveExpenseFromInlineInput(
    input: input,
    payload: payload,
  );
}
