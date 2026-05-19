import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:notecash/features/expense/domain/expense.dart';

class ReceiptItem {
  final String name;
  final double amount;
  final ExpenseCategory category;
  final double confidence;

  const ReceiptItem({
    required this.name,
    required this.amount,
    required this.category,
    required this.confidence,
  });
}

class ReceiptScanResult {
  final String rawText;
  final String merchant;
  final double total;
  final List<ReceiptItem> items;

  const ReceiptScanResult({
    required this.rawText,
    required this.merchant,
    required this.total,
    required this.items,
  });
}

class OcrService {
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  Future<Expense?> scanReceipt(File imageFile) async {
    final result = await scanReceiptDetailed(imageFile);
    if (result == null) return null;

    final amount = result.total;
    final note = result.merchant;
    final category = _detectCategory(result.rawText);

    return Expense()
      ..note = note
      ..amount = amount
      ..category = category
      ..isIncome = false
      ..paymentMethod = PaymentMethod.cash
      ..createdAt = DateTime.now();
  }

  Future<ReceiptScanResult?> scanReceiptDetailed(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final RecognizedText recognizedText =
        await _textRecognizer.processImage(inputImage);

    final fullText = recognizedText.text;
    if (fullText.trim().isEmpty) return null;

    final merchant = _extractMerchant(fullText);
    final lines = _normalizeLines(fullText);
    final items = _extractItems(lines);
    final total = _extractTotal(lines, items);

    return ReceiptScanResult(
      rawText: fullText,
      merchant: merchant,
      total: total,
      items: items,
    );
  }

  String _extractMerchant(String text) {
    final lines = text.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.length < 3) continue;
      if (_looksLikeNoise(trimmed)) continue;
      return trimmed;
    }
    return 'Hóa đơn';
  }

  ExpenseCategory _detectCategory(String text) {
    final lowerText = text.toLowerCase();
    if (lowerText.contains('food') ||
        lowerText.contains('cafe') ||
        lowerText.contains('coffee') ||
        lowerText.contains('restaurant') ||
        lowerText.contains('ăn') ||
        lowerText.contains('banh') ||
        lowerText.contains('bánh')) {
      return ExpenseCategory.foodAndDrink;
    }
    if (lowerText.contains('grab') ||
        lowerText.contains('xe') ||
        lowerText.contains('xăng') ||
        lowerText.contains('taxi') ||
        lowerText.contains('ship') ||
        lowerText.contains('delivery')) {
      return ExpenseCategory.transport;
    }
    if (lowerText.contains('siêu thị') ||
        lowerText.contains('market') ||
        lowerText.contains('shopee') ||
        lowerText.contains('lazada')) {
      return ExpenseCategory.shopping;
    }
    return ExpenseCategory.other;
  }

  List<String> _normalizeLines(String text) {
    return text
        .split('\n')
        .map((l) => l.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((l) => l.isNotEmpty)
        .toList(growable: false);
  }

  bool _looksLikeNoise(String line) {
    if (RegExp(r'^[-_=]{3,}$').hasMatch(line)) return true;
    if (RegExp(r'^[0-9\s\-/.:]+$').hasMatch(line)) return true;
    return false;
  }

  static final RegExp _amountAtEndRegex = RegExp(
    r'(.+?)\s+([0-9][0-9., ]{0,20})\s*([kKmM]|tr)?\s*$',
  );

  static final RegExp _dotsAmountRegex = RegExp(
    r'(.+?)[\.\s]{2,}([0-9][0-9., ]{0,20})\s*([kKmM]|tr)?\s*$',
  );

  static final RegExp _totalHintRegex = RegExp(
    r'\b(total|tổng|tong|subtotal|thanh\s*toán|thanh\s*toan|cộng|cong)\b',
    caseSensitive: false,
  );

  static final RegExp _ignoreLineRegex = RegExp(
    r'\b(vat|tax|mã\s*hóa\s*đơn|ma\s*hoa\s*don|hóa\s*đơn|hoa\s*don|cashier|quầy|pos|terminal)\b',
    caseSensitive: false,
  );

  List<ReceiptItem> _extractItems(List<String> lines) {
    final items = <ReceiptItem>[];

    for (final line in lines) {
      final lower = line.toLowerCase();
      if (_ignoreLineRegex.hasMatch(lower)) continue;
      if (_totalHintRegex.hasMatch(lower)) continue;
      if (_looksLikeNoise(line)) continue;

      final match = _dotsAmountRegex.firstMatch(line) ??
          _amountAtEndRegex.firstMatch(line);
      if (match == null) continue;

      final rawName = (match.group(1) ?? '').trim();
      final rawAmount = (match.group(2) ?? '').trim();
      final unit = (match.group(3) ?? '').trim().toLowerCase();

      final name = _cleanupItemName(rawName);
      if (name.isEmpty) continue;

      final amount = _parseAmount(rawAmount, unit);
      if (amount <= 0) continue;

      final category = _detectCategory(name);
      final confidence = _estimateConfidence(rawName, rawAmount);

      items.add(
        ReceiptItem(
          name: name,
          amount: amount,
          category: category,
          confidence: confidence,
        ),
      );
    }

    return items;
  }

  String _cleanupItemName(String raw) {
    var s = raw.trim();
    s = s.replaceAll(RegExp(r'\b(x|X)\s*\d+\b'), '');
    s = s.replaceAll(RegExp(r'\b\d+\s*(x|X)\b'), '');
    s = s.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
    if (s.length < 2) return '';
    return s;
  }

  double _parseAmount(String rawAmount, String unit) {
    final normalized = rawAmount.replaceAll(RegExp(r'[^0-9]'), '');
    if (normalized.isEmpty) return 0;
    final base = double.tryParse(normalized) ?? 0;
    if (base <= 0) return 0;

    if (unit == 'k') return base * 1000;
    if (unit == 'm') return base * 1000000;
    if (unit == 'tr') return base * 1000000;
    return base;
  }

  double _extractTotal(List<String> lines, List<ReceiptItem> items) {
    double best = 0;

    for (final line in lines) {
      final lower = line.toLowerCase();
      if (!_totalHintRegex.hasMatch(lower)) continue;

      final m = RegExp(r'([0-9][0-9., ]{0,20})\s*([kKmM]|tr)?\s*$')
          .firstMatch(line);
      if (m == null) continue;
      final raw = (m.group(1) ?? '').trim();
      final unit = (m.group(2) ?? '').trim().toLowerCase();
      final amount = _parseAmount(raw, unit);
      if (amount > best) best = amount;
    }

    if (best > 0) return best;

    if (items.isNotEmpty) {
      final sum = items.fold<double>(0, (acc, e) => acc + e.amount);
      if (sum > 0) return sum;
    }

    final fallback = _largestNumber(lines);
    return fallback;
  }

  double _largestNumber(List<String> lines) {
    double best = 0;
    final regex = RegExp(r'([0-9][0-9., ]{0,20})\s*([kKmM]|tr)?\b');
    for (final line in lines) {
      for (final m in regex.allMatches(line)) {
        final raw = (m.group(1) ?? '').trim();
        final unit = (m.group(2) ?? '').trim().toLowerCase();
        final amount = _parseAmount(raw, unit);
        if (amount > best) best = amount;
      }
    }
    return best;
  }

  double _estimateConfidence(String nameRaw, String amountRaw) {
    double score = 0.6;
    if (nameRaw.trim().length >= 3) score += 0.1;
    if (RegExp(r'[0-9]').hasMatch(amountRaw)) score += 0.15;
    if (RegExp(r'[A-Za-zÀ-ỹà-ỹ]').hasMatch(nameRaw)) score += 0.1;
    return score.clamp(0.0, 0.95);
  }

  void dispose() {
    _textRecognizer.close();
  }
}
