import 'package:isar/isar.dart';

part 'user_settings.g.dart';

@collection
class UserSettings {
  Id id = 0; // Always use id 0 for the single settings object

  double initialCashBalance = 0;
  double initialBankBalance = 0;

  bool isSetupCompleted = false;

  DateTime? updatedAt;
}
