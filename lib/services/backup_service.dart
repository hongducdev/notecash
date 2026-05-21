import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:notecash/core/models/user_settings.dart';
import 'package:notecash/features/expense/domain/expense.dart';
import 'package:notecash/services/isar_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:xml/xml.dart';

class BackupService {
  final IsarService _isarService;

  BackupService(this._isarService);

  Future<String> exportToXml() async {
    final settings = await _isarService.getUserSettings();
    final expenses = await _isarService.getAllExpenses();

    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element('backup', nest: () {
      builder.element('exportedAt', nest: DateTime.now().toIso8601String());

      builder.element('settings', nest: () {
        if (settings != null) {
          builder.element(
            'initialCashBalance',
            nest: settings.initialCashBalance.toString(),
          );
          builder.element(
            'initialBankBalance',
            nest: settings.initialBankBalance.toString(),
          );
          builder.element(
            'isSetupCompleted',
            nest: settings.isSetupCompleted.toString(),
          );
          builder.element(
            'trackedNotificationApps',
            nest: settings.trackedNotificationApps.join(','),
          );
          builder.element(
            'trackedNotificationPackages',
            nest: settings.trackedNotificationPackages.join(','),
          );
        }
      });

      builder.element('expenses', nest: () {
        for (final e in expenses) {
          builder.element('expense', nest: () {
            builder.element('note', nest: e.note);
            builder.element('amount', nest: e.amount.toStringAsFixed(0));
            builder.element('createdAt', nest: e.createdAt.toIso8601String());
            builder.element('category', nest: e.category.name);
            builder.element('isIncome', nest: e.isIncome.toString());
            builder.element('paymentMethod', nest: e.paymentMethod.name);
          });
        }
      });
    });
    return builder.buildDocument().toXmlString(pretty: true);
  }

  Future<void> exportToFile() async {
    final xml = await exportToXml();
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/notecash_backup_${DateTime.now().millisecondsSinceEpoch}.xml',
    );
    await file.writeAsString(xml);
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Notecash Backup',
    );
  }

  Future<int> importFromXml(String xmlString) async {
    final document = XmlDocument.parse(xmlString);
    final backup = document.findElements('backup').first;

    int importedCount = 0;

    final settingsElement = backup.findElements('settings').firstOrNull;
    if (settingsElement != null) {
      final settings = UserSettings()
        ..initialCashBalance = double.tryParse(
              settingsElement.findElements('initialCashBalance').firstOrNull?.innerText ?? '',
            ) ??
            0
        ..initialBankBalance = double.tryParse(
              settingsElement.findElements('initialBankBalance').firstOrNull?.innerText ?? '',
            ) ??
            0
        ..isSetupCompleted = bool.tryParse(
              settingsElement.findElements('isSetupCompleted').firstOrNull?.innerText ?? '',
            ) ??
            false
        ..trackedNotificationApps = settingsElement
                .findElements('trackedNotificationApps')
                .firstOrNull
                ?.innerText
                .split(',')
                .where((s) => s.isNotEmpty)
                .toList() ??
            []
        ..trackedNotificationPackages = settingsElement
                .findElements('trackedNotificationPackages')
                .firstOrNull
                ?.innerText
                .split(',')
                .where((s) => s.isNotEmpty)
                .toList() ??
            []
        ..updatedAt = DateTime.now();
      await _isarService.saveUserSettings(settings);
    }

    final expensesElement = backup.findElements('expenses').firstOrNull;
    if (expensesElement != null) {
      final expenses = <Expense>[];
      for (final elem in expensesElement.findElements('expense')) {
        final expense = Expense()
          ..note =
              elem.findElements('note').firstOrNull?.innerText ?? ''
          ..amount = double.tryParse(
                elem.findElements('amount').firstOrNull?.innerText ?? '',
              ) ??
              0
          ..createdAt = DateTime.tryParse(
                elem.findElements('createdAt').firstOrNull?.innerText ?? '',
              ) ??
              DateTime.now()
          ..category = ExpenseCategory.values.firstWhere(
            (c) =>
                c.name ==
                elem.findElements('category').firstOrNull?.innerText,
            orElse: () => ExpenseCategory.other,
          )
          ..isIncome = bool.tryParse(
                elem.findElements('isIncome').firstOrNull?.innerText ?? '',
              ) ??
              false
          ..paymentMethod = PaymentMethod.values.firstWhere(
            (p) =>
                p.name ==
                elem.findElements('paymentMethod').firstOrNull?.innerText,
            orElse: () => PaymentMethod.cash,
          );
        expenses.add(expense);
      }
      if (expenses.isNotEmpty) {
        await _isarService.saveExpenses(expenses);
        importedCount = expenses.length;
      }
    }

    return importedCount;
  }

  Future<int> importFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xml'],
    );
    if (result == null || result.files.isEmpty) return 0;
    final file = File(result.files.first.path!);
    final xmlString = await file.readAsString();
    return importFromXml(xmlString);
  }
}
