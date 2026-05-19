import 'package:isar/isar.dart';

part 'notification_log.g.dart';

@collection
class NotificationLog {
  Id id = Isar.autoIncrement;

  String? title;

  String? text;

  String? packageName;

  late DateTime receivedAt;

  late bool isBankRelated;

  double? parsedAmount;

  bool? isIncome;

  bool isRead = false;
}
