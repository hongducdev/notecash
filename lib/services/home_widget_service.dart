import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

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
}
