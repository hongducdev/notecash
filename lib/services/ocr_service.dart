import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:notecash/features/expense/domain/expense.dart';

class OcrService {
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<Expense?> scanReceipt(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

    String fullText = recognizedText.text;
    if (fullText.isEmpty) return null;

    double amount = _extractAmount(fullText);
    String note = _extractNote(fullText);
    
    // Phân loại cơ bản dựa trên văn bản nhận diện được
    ExpenseCategory category = _detectCategory(fullText);

    return Expense()
      ..note = note
      ..amount = amount
      ..category = category
      ..isIncome = false
      ..createdAt = DateTime.now();
  }

  double _extractAmount(String text) {
    // Tìm các con số có vẻ là tổng tiền (thường là số lớn nhất hoặc sau các từ khóa)
    // Regex tìm các số có định dạng tiền tệ phổ biến
    final RegExp amountRegex = RegExp(r'(\d{1,3}([,.]\d{3})*([,.]\d+)?)|(\d+)');
    final matches = amountRegex.allMatches(text);
    
    List<double> candidates = [];
    for (final match in matches) {
      String cleanStr = match.group(0)!.replaceAll(',', '').replaceAll('.', '');
      double? val = double.tryParse(cleanStr);
      if (val != null && val > 1000) { // Giả định số tiền thường > 1000đ
        candidates.add(val);
      }
    }

    if (candidates.isEmpty) return 0;
    
    // Thường tổng tiền là số lớn nhất trong hóa đơn
    candidates.sort();
    return candidates.last;
  }

  String _extractNote(String text) {
    // Lấy dòng đầu tiên hoặc tên cửa hàng nếu có thể (tạm thời lấy dòng đầu)
    final lines = text.split('\n');
    for (var line in lines) {
      if (line.trim().length > 3) {
        return line.trim();
      }
    }
    return "Hóa đơn mới";
  }

  ExpenseCategory _detectCategory(String text) {
    final lowerText = text.toLowerCase();
    if (lowerText.contains('food') || lowerText.contains('cafe') || lowerText.contains('restaurant') || lowerText.contains('ăn')) {
      return ExpenseCategory.foodAndDrink;
    }
    if (lowerText.contains('grab') || lowerText.contains('xe') || lowerText.contains('xăng') || lowerText.contains('taxi')) {
      return ExpenseCategory.transport;
    }
    if (lowerText.contains('siêu thị') || lowerText.contains('market') || lowerText.contains('shopee') || lowerText.contains('lazada')) {
      return ExpenseCategory.shopping;
    }
    return ExpenseCategory.other;
  }

  void dispose() {
    _textRecognizer.close();
  }
}
