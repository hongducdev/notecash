import 'package:notecash/features/expense/domain/expense.dart';

class ExpenseParserService {
  Expense parse(String input) {
    final parts = input.trim().split(' ');

    double amount = 0;
    String note = '';
    ExpenseCategory category = ExpenseCategory.other;
    bool isIncome = false;

    // Basic logic: find the part that looks like a number
    for (var part in parts) {
      final cleanPart = part.toLowerCase().replaceAll(',', '');

      if (cleanPart.contains(RegExp(r'\d'))) {
        // Try to parse amount
        String amountStr = cleanPart.replaceAll(RegExp(r'[^0-9.]'), '');
        double? val = double.tryParse(amountStr);

        if (val != null) {
          if (cleanPart.endsWith('k')) {
            amount = val * 1000;
          } else if (cleanPart.endsWith('m')) {
            amount = val * 1000000;
          } else {
            amount = val;
          }
          continue; // Found amount, move to next part
        }
      }

      // If not amount, it's note or category keyword
      if (note.isEmpty) {
        note = part;
      } else {
        note += ' $part';
      }
    }

    // Smart categorization (very basic for now)
    final lowerNote = note.toLowerCase();
    if (lowerNote.contains('grab') ||
        lowerNote.contains('xe') ||
        lowerNote.contains('xăng')) {
      category = ExpenseCategory.transport;
    } else if (lowerNote.contains('cf') ||
        lowerNote.contains('cafe') ||
        lowerNote.contains('ăn') ||
        lowerNote.contains('uống')) {
      category = ExpenseCategory.foodAndDrink;
    } else if (lowerNote.contains('mua') || lowerNote.contains('shopee')) {
      category = ExpenseCategory.shopping;
    } else if (lowerNote.contains('điện') ||
        lowerNote.contains('nước') ||
        lowerNote.contains('bill')) {
      category = ExpenseCategory.bills;
    } else if (lowerNote.contains('lương') ||
        lowerNote.contains('thưởng') ||
        lowerNote.contains('tặng') ||
        lowerNote.contains('cho') ||
        lowerNote.contains('quà')) {
      category = ExpenseCategory.income;
      isIncome = true;
    }

    return Expense()
      ..note = note
      ..amount = amount
      ..category = category
      ..isIncome = isIncome
      ..createdAt = DateTime.now();
  }
}
