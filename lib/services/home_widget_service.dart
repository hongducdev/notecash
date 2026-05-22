import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:notecash/features/bills/domain/recurring_bill.dart';

class HomeWidgetService {
  static const String _groupId = 'group.notecash';
  static const String _androidWidgetName = 'NotecashWidgetProvider';

  static Future<void> init() async {
    await HomeWidget.setAppGroupId(_groupId);
  }

  static Future<void> updateBalance(double balance) async {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final balanceStr = currencyFormat.format(balance);
    await HomeWidget.saveWidgetData<String>('balance', balanceStr);
    await HomeWidget.updateWidget(
      name: _androidWidgetName,
      androidName: _androidWidgetName,
    );
  }

  static Future<void> updateBills(List<RecurringBill> bills) async {
    if (bills.isEmpty) {
      await HomeWidget.saveWidgetData<String>('upcoming_bill', '');
      await HomeWidget.updateWidget(
        name: _androidWidgetName,
        androidName: _androidWidgetName,
      );
      return;
    }

    final next = bills.first;
    final days = next.daysUntilDue;
    final dueStr = days == 0
        ? 'hôm nay'
        : days == 1
        ? 'ngày mai'
        : 'trong $days ngày';
    final amountStr = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '',
      decimalDigits: 0,
    ).format(next.amount);
    final display = '${next.name}: $amountStrđ $dueStr';
    await HomeWidget.saveWidgetData<String>('upcoming_bill', display);
    await HomeWidget.updateWidget(
      name: _androidWidgetName,
      androidName: _androidWidgetName,
    );
  }
}
