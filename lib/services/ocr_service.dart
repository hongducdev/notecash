import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:notecash/features/expense/domain/expense.dart';

class _OcrLine {
  final String text;
  final double centerY;

  const _OcrLine({required this.text, required this.centerY});
}

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
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

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
    final RecognizedText recognizedText = await _textRecognizer.processImage(
      inputImage,
    );

    final fullText = recognizedText.text;
    if (fullText.trim().isEmpty) return null;

    final merchant = _extractMerchant(fullText);
    final ocrLines = _collectOcrLines(recognizedText);
    final lines = _normalizeLinesFromOcr(ocrLines, fallbackText: fullText);
    final items = _extractItems(lines);
    final total = _extractTotal(lines, items, ocrLines);

    return ReceiptScanResult(
      rawText: fullText,
      merchant: merchant,
      total: total,
      items: items,
    );
  }

  List<_OcrLine> _collectOcrLines(RecognizedText recognizedText) {
    final lines = <_OcrLine>[];
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final text = line.text.trim();
        if (text.isEmpty) continue;
        final rect = line.boundingBox;
        lines.add(_OcrLine(text: text, centerY: rect.center.dy));
      }
    }

    lines.sort((a, b) => a.centerY.compareTo(b.centerY));
    return lines;
  }

  List<String> _normalizeLinesFromOcr(
    List<_OcrLine> ocrLines, {
    required String fallbackText,
  }) {
    if (ocrLines.isNotEmpty) {
      return ocrLines
          .map((l) => l.text.replaceAll(RegExp(r'\s+'), ' ').trim())
          .where((l) => l.isNotEmpty)
          .toList(growable: false);
    }

    return _normalizeLines(fallbackText);
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
    r'(.+?)\s+([0-9][0-9., ]{0,20})\s*(?:₫|\b(vnd|vnđ|dong)\b|\bđ\b)?\s*([kKmM]|tr)?\s*$',
  );

  static final RegExp _dotsAmountRegex = RegExp(
    r'(.+?)[\.\s]{2,}([0-9][0-9., ]{0,20})\s*(?:₫|\b(vnd|vnđ|dong)\b|\bđ\b)?\s*([kKmM]|tr)?\s*$',
  );

  static final RegExp _amountAtStartRegex = RegExp(
    r'^([0-9][0-9., ]{0,20})\s*(?:₫|\b(vnd|vnđ|dong)\b|\bđ\b)?\s*([kKmM]|tr)?\s+(.+?)\s*$',
  );

  static final RegExp _totalHintRegex = RegExp(
    r'\b(total|tổng|tong|subtotal|thanh\s*toán|thanh\s*toan|cộng|cong)\b',
    caseSensitive: false,
  );

  static final RegExp _strongTotalHintRegex = RegExp(
    r'(?:\btotal\b|'
    r'\btổng\s*cộng\b|'
    r'\btong\s*cong\b|'
    r'\btongcong\b|'
    r'\bthanh\s*toán\b|'
    r'\bthanh\s*toan\b|'
    r'\bgrand\s*total\b|'
    r'\bamount\s*due\b|'
    r'\bpayable\b)',
    caseSensitive: false,
  );

  static final RegExp _currencyHintRegex = RegExp(
    r'(₫|\b(vnd|vnđ|dong)\b|\bđ\b)',
    caseSensitive: false,
  );

  static final RegExp _currencyBeforeAmountRegex = RegExp(
    r'(?:₫|\b(?:vnd|vnđ|dong)\b|\bđ\b)\s*([0-9][0-9., ]{0,20})\s*([kKmM]|tr)?',
    caseSensitive: false,
  );

  static final RegExp _amountBeforeCurrencyRegex = RegExp(
    r'([0-9][0-9., ]{0,20})\s*([kKmM]|tr)?\s*(?:₫|\b(?:vnd|vnđ|dong)\b|\bđ\b)',
    caseSensitive: false,
  );

  static final RegExp _totalAmountAtEndRegex = RegExp(
    r'([0-9][0-9., ]{0,20})\s*([kKmM]|tr)?(?:\s*(?:₫|\b(?:vnd|vnđ|dong)\b|\bđ\b))?\s*$',
    caseSensitive: false,
  );

  static final RegExp _ignoreLineRegex = RegExp(
    r'\b('
    r'vat|tax|mã\s*hóa\s*đơn|ma\s*hoa\s*don|hóa\s*đơn|hoa\s*don|cashier|quầy|pos|terminal|'
    r'mst|mã\s*số\s*thuế|ma\s*so\s*thue|tax\s*code|tin|'
    r'sđt|sdt|đt|dt|điện\s*thoại|dien\s*thoai|phone|tel|hotline|liên\s*hệ|lien\s*he|contact|'
    r'stk|số\s*tài\s*khoản|so\s*tai\s*khoan|tài\s*khoản|tai\s*khoan|account|iban|swift|'
    r'invoice|so\s*hd|số\s*hd|serial|ký\s*hiệu|ky\s*hieu|'
    r'số\s*lượng|so\s*luong|qty|items?'
    r')\b',
    caseSensitive: false,
  );

  List<ReceiptItem> _extractItems(List<String> lines) {
    final items = <ReceiptItem>[];

    for (final line in lines) {
      final lower = line.toLowerCase();
      if (_ignoreLineRegex.hasMatch(lower)) continue;
      if (_totalHintRegex.hasMatch(lower)) continue;
      if (_looksLikeNoise(line)) continue;

      String rawName = '';
      String rawAmount = '';
      String unit = '';

      final endMatch =
          _dotsAmountRegex.firstMatch(line) ??
          _amountAtEndRegex.firstMatch(line);
      final startMatch = endMatch == null
          ? _amountAtStartRegex.firstMatch(line)
          : null;

      if (endMatch != null) {
        rawName = (endMatch.group(1) ?? '').trim();
        rawAmount = (endMatch.group(2) ?? '').trim();
        unit = (endMatch.group(4) ?? '').trim().toLowerCase();
      } else if (startMatch != null) {
        rawAmount = (startMatch.group(1) ?? '').trim();
        unit = (startMatch.group(3) ?? '').trim().toLowerCase();
        rawName = (startMatch.group(4) ?? '').trim();
      } else {
        continue;
      }

      final name = _cleanupItemName(rawName);
      if (name.isEmpty) continue;
      if (!_containsLetters(name)) continue;

      final amount = _parseAmount(rawAmount, unit);
      if (amount <= 0) continue;
      if (!_isPlausibleMoneyAmount(amount)) continue;
      if (_looksLikePhoneOrTaxId(
        rawAmount: rawAmount,
        unit: unit,
        lineLower: lower,
      )) {
        continue;
      }
      if (!_hasMoneySignal(line: line, rawAmount: rawAmount, unit: unit)) {
        continue;
      }

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

  bool _containsLetters(String text) {
    return RegExp(r'[A-Za-zÀ-ỹà-ỹ]').hasMatch(text);
  }

  bool _isPlausibleMoneyAmount(double amount) {
    if (amount < 500) return false;
    if (amount > 200000000) return false;
    return true;
  }

  bool _hasMoneySignal({
    required String line,
    required String rawAmount,
    required String unit,
  }) {
    if (unit.isNotEmpty) return true;
    if (_currencyHintRegex.hasMatch(line)) return true;
    if (rawAmount.contains('.') || rawAmount.contains(',')) return true;
    final digitsOnly = rawAmount.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length >= 5) return true;
    return false;
  }

  bool _looksLikePhoneOrTaxId({
    required String rawAmount,
    required String unit,
    required String lineLower,
  }) {
    if (unit.isNotEmpty) return false;

    final digits = rawAmount.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return false;

    final hasSeparators =
        rawAmount.contains('.') ||
        rawAmount.contains(',') ||
        rawAmount.contains(' ');

    final isLikelyPhone =
        !hasSeparators &&
        (digits.length == 10 || digits.length == 11) &&
        (digits.startsWith('0') || lineLower.contains('+84'));

    if (isLikelyPhone) return true;

    final hasTaxKeyword =
        lineLower.contains('mst') ||
        lineLower.contains('mã số thuế') ||
        lineLower.contains('ma so thue') ||
        lineLower.contains('tax code') ||
        RegExp(r'\btin\b').hasMatch(lineLower);

    if (hasTaxKeyword &&
        (digits.length == 10 || digits.length == 13 || digits.length == 14)) {
      return true;
    }

    final hasPhoneKeyword =
        lineLower.contains('sdt') ||
        lineLower.contains('sđt') ||
        RegExp(r'\bđt\b|\bdt\b').hasMatch(lineLower) ||
        lineLower.contains('điện thoại') ||
        lineLower.contains('dien thoai') ||
        lineLower.contains('phone') ||
        lineLower.contains('tel') ||
        lineLower.contains('hotline');

    if (hasPhoneKeyword && (digits.length >= 9 && digits.length <= 12)) {
      return true;
    }

    final hasInvoiceKeyword =
        lineLower.contains('invoice') ||
        RegExp(r'\bso\s*hd\b|\bsố\s*hd\b').hasMatch(lineLower) ||
        lineLower.contains('serial') ||
        lineLower.contains('ký hiệu') ||
        lineLower.contains('ky hieu');

    if (hasInvoiceKeyword && digits.length >= 6) {
      return true;
    }

    return false;
  }

  double _extractTotal(
    List<String> lines,
    List<ReceiptItem> items,
    List<_OcrLine> ocrLines,
  ) {
    final candidates = <_TotalCandidate>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();
      if (_ignoreLineRegex.hasMatch(lower)) continue;

      final isStrong = _strongTotalHintRegex.hasMatch(lower);
      if (!isStrong) continue;

      final scoreBase = _scoreLinePosition(i, lines.length, ocrLines);
      const hintScore = 6.0;

      for (final amt in _extractAmountTokens(line)) {
        final amount = _parseAmount(amt.raw, amt.unit);
        if (!_isPlausibleMoneyAmount(amount)) continue;
        if (_looksLikePhoneOrTaxId(
          rawAmount: amt.raw,
          unit: amt.unit,
          lineLower: lower,
        )) {
          continue;
        }

        final score =
            hintScore +
            scoreBase +
            (amt.hasSeparators ? 1.0 : 0.0) +
            (amt.isAtEnd ? 1.0 : 0.0);

        candidates.add(
          _TotalCandidate(
            amount: amount,
            score: score,
            lineIndex: i,
            line: line,
          ),
        );
      }
    }

    candidates.sort((a, b) {
      final s = b.score.compareTo(a.score);
      if (s != 0) return s;
      return b.amount.compareTo(a.amount);
    });

    if (candidates.isNotEmpty) {
      return candidates.first.amount;
    }

    if (items.isNotEmpty) {
      final sum = items.fold<double>(0, (acc, e) => acc + e.amount);
      if (sum > 0) return sum;
    }

    final bottomTotal = _extractLargestFromBottom(lines, ocrLines);
    if (bottomTotal > 0) return bottomTotal;

    return _largestNumber(lines);
  }

  double _scoreLinePosition(
    int index,
    int totalLines,
    List<_OcrLine> ocrLines,
  ) {
    if (totalLines <= 1) return 0;

    final byIndex = index / (totalLines - 1);
    var score = 0.0;
    if (byIndex >= 0.75) score += 2.5;
    if (byIndex >= 0.85) score += 1.5;

    if (ocrLines.isNotEmpty && index < ocrLines.length) {
      final y = ocrLines[index].centerY;
      final minY = ocrLines.first.centerY;
      final maxY = ocrLines.last.centerY;
      final range = (maxY - minY).abs();
      if (range > 0) {
        final byY = (y - minY) / range;
        if (byY >= 0.75) score += 2.5;
        if (byY >= 0.85) score += 1.5;
      }
    }

    return score;
  }

  double _extractLargestFromBottom(
    List<String> lines,
    List<_OcrLine> ocrLines,
  ) {
    final takeCount = lines.length < 18 ? lines.length : 18;
    final start = (lines.length - takeCount).clamp(0, lines.length);

    double best = 0;
    for (var i = start; i < lines.length; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();
      if (_ignoreLineRegex.hasMatch(lower)) continue;
      if (_looksLikeNoise(line)) continue;

      for (final amt in _extractAmountTokens(line)) {
        final amount = _parseAmount(amt.raw, amt.unit);
        if (!_isPlausibleMoneyAmount(amount)) continue;
        if (_looksLikePhoneOrTaxId(
          rawAmount: amt.raw,
          unit: amt.unit,
          lineLower: lower,
        )) {
          continue;
        }
        if (amount > best) best = amount;
      }
    }
    return best;
  }

  List<_AmountToken> _extractAmountTokens(String line) {
    final tokens = <_AmountToken>[];
    final normalizedLine = line.replaceAll(RegExp(r'\s+'), ' ').trim();

    for (final m in _currencyBeforeAmountRegex.allMatches(normalizedLine)) {
      final raw = (m.group(1) ?? '').trim();
      final unit = (m.group(2) ?? '').trim().toLowerCase();
      tokens.add(
        _AmountToken(
          raw: raw,
          unit: unit,
          isAtEnd: false,
          hasSeparators:
              raw.contains('.') || raw.contains(',') || raw.contains(' '),
        ),
      );
    }

    for (final m in _amountBeforeCurrencyRegex.allMatches(normalizedLine)) {
      final raw = (m.group(1) ?? '').trim();
      final unit = (m.group(2) ?? '').trim().toLowerCase();
      tokens.add(
        _AmountToken(
          raw: raw,
          unit: unit,
          isAtEnd: normalizedLine.endsWith(m.group(0) ?? ''),
          hasSeparators:
              raw.contains('.') || raw.contains(',') || raw.contains(' '),
        ),
      );
    }

    final endMatch = _totalAmountAtEndRegex.firstMatch(normalizedLine);
    if (endMatch != null) {
      final raw = (endMatch.group(1) ?? '').trim();
      final unit = (endMatch.group(2) ?? '').trim().toLowerCase();
      tokens.add(
        _AmountToken(
          raw: raw,
          unit: unit,
          isAtEnd: true,
          hasSeparators:
              raw.contains('.') || raw.contains(',') || raw.contains(' '),
        ),
      );
    }

    final numberRegex = RegExp(r'([0-9][0-9., ]{0,20})\s*([kKmM]|tr)?\b');
    for (final m in numberRegex.allMatches(normalizedLine)) {
      final raw = (m.group(1) ?? '').trim();
      final unit = (m.group(2) ?? '').trim().toLowerCase();
      final whole = m.group(0) ?? '';
      tokens.add(
        _AmountToken(
          raw: raw,
          unit: unit,
          isAtEnd: normalizedLine.endsWith(whole),
          hasSeparators:
              raw.contains('.') || raw.contains(',') || raw.contains(' '),
        ),
      );
    }

    return tokens;
  }

  double _largestNumber(List<String> lines) {
    double best = 0;
    final regex = RegExp(r'([0-9][0-9., ]{0,20})\s*([kKmM]|tr)?\b');
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (_ignoreLineRegex.hasMatch(lower)) continue;
      for (final m in regex.allMatches(line)) {
        final raw = (m.group(1) ?? '').trim();
        final unit = (m.group(2) ?? '').trim().toLowerCase();
        final amount = _parseAmount(raw, unit);
        if (!_isPlausibleMoneyAmount(amount)) continue;
        if (_looksLikePhoneOrTaxId(
          rawAmount: raw,
          unit: unit,
          lineLower: lower,
        )) {
          continue;
        }
        if (!_hasMoneySignal(line: line, rawAmount: raw, unit: unit)) continue;
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

class _AmountToken {
  final String raw;
  final String unit;
  final bool isAtEnd;
  final bool hasSeparators;

  const _AmountToken({
    required this.raw,
    required this.unit,
    required this.isAtEnd,
    required this.hasSeparators,
  });
}

class _TotalCandidate {
  final double amount;
  final double score;
  final int lineIndex;
  final String line;

  const _TotalCandidate({
    required this.amount,
    required this.score,
    required this.lineIndex,
    required this.line,
  });
}
