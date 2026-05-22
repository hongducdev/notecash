import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:notecash/features/expense/domain/expense.dart';

// ─── Internal Data Types ──────────────────────────────────────────────────────

/// A single word/token from ML Kit, with its spatial position on the page.
class _OcrElement {
  final String text;
  final double centerX;
  final double centerY;
  final double height;

  const _OcrElement({
    required this.text,
    required this.centerX,
    required this.centerY,
    required this.height,
  });
}

/// A reconstructed visual row: elements from (potentially multiple) OCR blocks
/// that share the same Y coordinate, sorted left-to-right.
class _OcrLine {
  final String text;
  final double centerY;

  /// Original word elements, sorted by X (left → right).
  final List<_OcrElement> elements;

  const _OcrLine({
    required this.text,
    required this.centerY,
    this.elements = const [],
  });
}

// ─── Public API Types ─────────────────────────────────────────────────────────

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

// ─── Service ──────────────────────────────────────────────────────────────────

class OcrService {
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  Future<Expense?> scanReceipt(File imageFile) async {
    final result = await scanReceiptDetailed(imageFile);
    if (result == null) return null;

    return Expense()
      ..note = result.merchant
      ..amount = result.total
      ..category = _detectCategory(result.rawText)
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
    // Use element-level row reconstruction for accurate spatial layout
    final ocrLines = _collectOcrLines(recognizedText);
    final lines = ocrLines.map((l) => l.text).toList(growable: false);
    final items = _extractItems(lines, ocrLines);
    final total = _extractTotal(lines, items, ocrLines);

    return ReceiptScanResult(
      rawText: fullText,
      merchant: merchant,
      total: total,
      items: items,
    );
  }

  // ─── OCR Line Collection (Spatial Row Merging) ──────────────────────────

  /// Collects all word-level elements from ML Kit, then groups them into
  /// visual rows by Y coordinate.
  ///
  /// This solves a core problem: ML Kit may split a single visual line
  /// (e.g. "Product Name    30.000") across multiple blocks. By working at
  /// the element level and merging by Y proximity, we reconstruct the true
  /// left-to-right layout of each row.
  List<_OcrLine> _collectOcrLines(RecognizedText recognizedText) {
    // ── Step 1: Flatten to word-level elements ──────────────────────────────
    final elems = <_OcrElement>[];
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        for (final el in line.elements) {
          final text = el.text.trim();
          if (text.isEmpty) continue;
          final box = el.boundingBox;
          elems.add(
            _OcrElement(
              text: text,
              centerX: box.center.dx,
              centerY: box.center.dy,
              height: box.height.toDouble(),
            ),
          );
        }
      }
    }

    if (elems.isEmpty) return [];

    // ── Step 2: Adaptive row-threshold ─────────────────────────────────────
    // Use 55% of the median element height.  Clamped to [4, 18] px so it
    // works across different receipt DPI / zoom levels.
    final heights = elems.map((e) => e.height).toList()..sort();
    final medianH = heights[heights.length ~/ 2];
    final rowThreshold = (medianH * 0.55).clamp(4.0, 18.0);

    // ── Step 3: Sort by Y and cluster into rows ─────────────────────────────
    elems.sort((a, b) => a.centerY.compareTo(b.centerY));
    final rows = <List<_OcrElement>>[];

    for (final el in elems) {
      bool placed = false;
      // Check rows in reverse: last added row is closest in Y
      for (var i = rows.length - 1; i >= 0; i--) {
        final row = rows[i];
        final rowAvgY =
            row.fold<double>(0, (s, e) => s + e.centerY) / row.length;
        if ((el.centerY - rowAvgY).abs() <= rowThreshold) {
          row.add(el);
          placed = true;
          break;
        }
        // Since elements are sorted by Y, rows much higher up can be skipped
        if (rowAvgY < el.centerY - rowThreshold * 3) break;
      }
      if (!placed) rows.add([el]);
    }

    // ── Step 4: Build _OcrLine per row ──────────────────────────────────────
    final result = <_OcrLine>[];
    for (final row in rows) {
      // Sort left-to-right
      row.sort((a, b) => a.centerX.compareTo(b.centerX));
      final avgY = row.fold<double>(0, (s, e) => s + e.centerY) / row.length;
      final text = row.map((e) => e.text).join(' ').trim();
      if (text.isNotEmpty) {
        result.add(_OcrLine(text: text, centerY: avgY, elements: row));
      }
    }

    result.sort((a, b) => a.centerY.compareTo(b.centerY));
    return result;
  }

  // ─── Merchant Extraction ─────────────────────────────────────────────────

  String _extractMerchant(String text) {
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.length >= 3)
        .toList();

    // Priority 1: ALL-CAPS line in first 5 lines (brand / store name)
    for (final line in lines.take(5)) {
      if (_looksLikeNoise(line)) continue;
      if (_looksLikeAddress(line)) continue;
      if (line == line.toUpperCase() && _containsLetters(line)) return line;
    }

    // Priority 2: First meaningful, non-address line
    for (final line in lines.take(8)) {
      if (_looksLikeNoise(line)) continue;
      if (_looksLikeAddress(line)) continue;
      return line;
    }

    return 'Hóa đơn';
  }

  bool _looksLikeAddress(String line) {
    return RegExp(
          r'\b(đường|phường|quận|huyện|tỉnh|tp\.|p\.|q\.|street|ward|district)\b',
          caseSensitive: false,
        ).hasMatch(line) ||
        RegExp(r'^\d+[,\s]').hasMatch(line.toLowerCase());
  }

  // ─── Category Detection ───────────────────────────────────────────────────

  ExpenseCategory _detectCategory(String text) {
    final lower = text.toLowerCase();
    if (RegExp(
      r'\b(food|cafe|coffee|restaurant|ăn|banh|bánh|phở|bún|cơm|trà|nước\s*ngọt|sữa|bia|thịt|cá|rau)\b',
      caseSensitive: false,
    ).hasMatch(lower)) {
      return ExpenseCategory.foodAndDrink;
    }
    if (RegExp(
      r'\b(grab|xe|xăng|taxi|ship|delivery|vận\s*chuyển)\b',
      caseSensitive: false,
    ).hasMatch(lower)) {
      return ExpenseCategory.transport;
    }
    if (RegExp(
      r'\b(siêu\s*thị|market|shopee|lazada|winmart|coopmart|bách\s*hóa|big\s*c|lotte|mall|store|shop)\b',
      caseSensitive: false,
    ).hasMatch(lower)) {
      return ExpenseCategory.shopping;
    }
    return ExpenseCategory.other;
  }

  // ─── Utility Helpers ─────────────────────────────────────────────────────

  bool _looksLikeNoise(String line) {
    if (RegExp(r'^[-_=*#~]{3,}$').hasMatch(line)) return true;
    if (RegExp(r'^[0-9\s\-/.:,]+$').hasMatch(line)) return true;
    return false;
  }

  bool _containsLetters(String text) =>
      RegExp(r'[A-Za-zÀ-ỹà-ỹ]').hasMatch(text);

  /// Returns true if a line is mostly numbers (a "price row").
  ///
  /// e.g. "15.000 x 2 30.000" → true
  /// Accepts two conditions (OR):
  ///   A) ≥ 55% of stripped characters are digits
  ///   B) Line contains ≥ 2 distinct plausible money amounts
  bool _isPriceRowLine(String line) {
    if (!RegExp(r'[0-9]').hasMatch(line)) return false;

    // Condition B: count plausible money amounts (faster reject for name lines)
    final moneyMatches = RegExp(r'[0-9][0-9.,]*').allMatches(line);
    int moneyCount = 0;
    for (final m in moneyMatches) {
      final raw = m.group(0) ?? '';
      if (_isLikelyCode(raw)) continue;
      final amount = _parseAmount(raw, '');
      if (_isPlausibleMoneyAmount(amount)) moneyCount++;
      if (moneyCount >= 2) return true; // 2+ plausible amounts = price row
    }

    // Condition A: digit character ratio
    final stripped = line
        .replaceAll(RegExp(r'[xX×]'), ' ')
        .replaceAll(RegExp(r'[.,]'), '')
        .replaceAll(RegExp(r'[₫đ]', caseSensitive: false), '')
        .replaceAll(RegExp(r'\b(vnd|vnđ|dong)\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), '');
    if (stripped.isEmpty) return false;
    final digitCount = stripped.replaceAll(RegExp(r'[^0-9]'), '').length;
    return digitCount / stripped.length >= 0.55;
  }

  /// Returns true if [raw] looks like an invoice number / serial code
  /// (no thousand-separators + ≥ 6 digits).
  bool _isLikelyCode(String raw) {
    if (raw.contains('.') || raw.contains(',')) return false;
    return raw.replaceAll(RegExp(r'[^0-9]'), '').length >= 6;
  }

  /// From a price row, extract the LAST plausible money amount (the subtotal).
  ///
  /// Uses element-level X positions when available: the rightmost number
  /// token is the "total" column on a supermarket receipt.
  double? _extractSubtotalFromPriceRow(
    String line, {
    List<_OcrElement>? elements,
  }) {
    // If we have element positions, use the rightmost number token
    if (elements != null && elements.isNotEmpty) {
      // Collect number tokens from right to left
      for (final el in elements.reversed) {
        final raw = el.text.trim();
        if (!RegExp(r'^[0-9][0-9.,]*$').hasMatch(raw)) continue;
        if (_isLikelyCode(raw)) continue;
        final amount = _parseAmount(raw, '');
        if (_isPlausibleMoneyAmount(amount)) return amount;
      }
    }

    // Fallback: scan left-to-right, take the last plausible amount
    final amounts = <double>[];
    final regex = RegExp(r'([0-9][0-9.,]*)');
    for (final m in regex.allMatches(line)) {
      final raw = (m.group(1) ?? '').trim();
      if (_isLikelyCode(raw)) continue;
      final amount = _parseAmount(raw, '');
      if (_isPlausibleMoneyAmount(amount)) amounts.add(amount);
    }
    return amounts.isEmpty ? null : amounts.last;
  }

  // ─── Amount Parsing ───────────────────────────────────────────────────────

  /// Parse a Vietnamese-format money string.
  ///
  /// * "25.000"   → 25 000
  /// * "1.500.000" → 1 500 000
  /// * "25,000"   → 25 000
  /// * "25k"      → 25 000
  double _parseAmount(String rawAmount, String unit) {
    var s = rawAmount.trim().replaceAll(' ', '');
    if (s.isEmpty) return 0;

    if (RegExp(r'^\d{1,3}(\.\d{3})+$').hasMatch(s)) {
      s = s.replaceAll('.', '');
    } else if (RegExp(r'^\d{1,3}(,\d{3})+$').hasMatch(s)) {
      s = s.replaceAll(',', '');
    } else {
      s = s.replaceAll(RegExp(r'[^0-9]'), '');
    }

    if (s.isEmpty) return 0;
    final base = double.tryParse(s) ?? 0;
    if (base <= 0) return 0;

    if (unit == 'k') return base * 1000;
    if (unit == 'm' || unit == 'tr') return base * 1000000;
    return base;
  }

  bool _isPlausibleMoneyAmount(double amount) {
    if (amount < 1000) return false;
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
    // Plain digit strings: accept only ≤ 5 digits (max 99 999 đ without sep.)
    final digitsOnly = rawAmount.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length <= 5) return true;
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

    final hasSeps =
        rawAmount.contains('.') ||
        rawAmount.contains(',') ||
        rawAmount.contains(' ');

    // Phone heuristic
    if (!hasSeps &&
        (digits.length == 10 || digits.length == 11) &&
        (digits.startsWith('0') || lineLower.contains('+84'))) {
      return true;
    }

    // Tax ID
    if ((lineLower.contains('mst') ||
            lineLower.contains('mã số thuế') ||
            lineLower.contains('tax code') ||
            RegExp(r'\btin\b').hasMatch(lineLower)) &&
        (digits.length == 10 || digits.length == 13 || digits.length == 14)) {
      return true;
    }

    // Phone keywords
    if ((lineLower.contains('sdt') ||
            lineLower.contains('sđt') ||
            RegExp(r'\bđt\b|\bdt\b').hasMatch(lineLower) ||
            lineLower.contains('điện thoại') ||
            lineLower.contains('phone') ||
            lineLower.contains('tel') ||
            lineLower.contains('hotline')) &&
        digits.length >= 9 &&
        digits.length <= 12) {
      return true;
    }

    // Invoice / serial keywords
    if ((lineLower.contains('invoice') ||
            RegExp(r'\bso\s*hd\b|\bsố\s*hd\b').hasMatch(lineLower) ||
            lineLower.contains('serial') ||
            lineLower.contains('ký hiệu') ||
            RegExp(r'\bmã\b|\bma\b').hasMatch(lineLower) ||
            lineLower.contains('số:') ||
            lineLower.contains('so:')) &&
        digits.length >= 6) {
      return true;
    }

    // Catch-all: bare 6+ digit string without separators = code
    if (!hasSeps && digits.length >= 6) return true;

    return false;
  }

  /// Clean a raw product name extracted by regex.
  ///
  /// Removes:
  /// * Leading row numbers ("1 Sữa" → "Sữa")
  /// * Quantity indicators (x2, 2x, ×3)
  /// * Price-like numbers embedded in the name (15.000, 1.500)
  /// * Trailing standalone small numbers (likely quantity)
  String _cleanupItemName(String raw) {
    var s = raw.trim();
    // Remove leading row index numbers (e.g. "1 Sữa Milo" → "Sữa Milo")
    s = s.replaceAll(RegExp(r'^\d{1,3}\s+'), '');
    // Remove qty indicators
    s = s.replaceAll(RegExp(r'\b[xX×]\s*\d+\b'), '');
    s = s.replaceAll(RegExp(r'\b\d+\s*[xX×]\b'), '');
    // Remove price-like numbers with thousand separators
    s = s.replaceAll(RegExp(r'\b\d{1,3}(?:[.,]\d{3})+\b'), '');
    // Remove trailing standalone integers (quantity)
    s = s.replaceAll(RegExp(r'\s+\d{1,3}\s*$'), '');
    // Collapse whitespace
    s = s.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
    if (s.length < 2) return '';
    return s;
  }

  double _estimateConfidence(String nameRaw, String amountRaw) {
    double score = 0.6;
    if (nameRaw.trim().length >= 3) score += 0.1;
    if (RegExp(r'[0-9]').hasMatch(amountRaw)) score += 0.15;
    if (RegExp(r'[A-Za-zÀ-ỹà-ỹ]').hasMatch(nameRaw)) score += 0.1;
    return score.clamp(0.0, 0.95);
  }

  // ─── Regex Constants ──────────────────────────────────────────────────────

  static final RegExp _amountAtEndRegex = RegExp(
    r'(.+?)\s+([0-9][0-9., ]{0,20})\s*(?:₫|\b(vnd|vnđ|dong)\b|\bđ\b)?\s*([kKmM]|tr)?\s*$',
  );

  static final RegExp _dotsAmountRegex = RegExp(
    r'(.+?)[.\s]{2,}([0-9][0-9., ]{0,20})\s*(?:₫|\b(vnd|vnđ|dong)\b|\bđ\b)?\s*([kKmM]|tr)?\s*$',
  );

  static final RegExp _amountAtStartRegex = RegExp(
    r'^([0-9][0-9., ]{0,20})\s*(?:₫|\b(vnd|vnđ|dong)\b|\bđ\b)?\s*([kKmM]|tr)?\s+(.+?)\s*$',
  );

  static final RegExp _totalHintRegex = RegExp(
    r'\b(total|tổng|tong|subtotal|thanh\s*toán|thanh\s*toan|cộng|cong|'
    r'thành\s*tiền|thanh\s*tien|'
    r'khách\s*trả|khach\s*tra|'
    r'khách\s*phải\s*trả|khach\s*phai\s*tra|'
    r'phải\s*trả|phai\s*tra'
    r')\b',
    caseSensitive: false,
  );

  static final RegExp _strongTotalHintRegex = RegExp(
    r'(?:'
    r'\btotal\b|'
    r'\bgrand\s*total\b|'
    r'\bamount\s*due\b|'
    r'\bpayable\b|'
    r'\btổng\s*cộng\b|'
    r'\btong\s*cong\b|'
    r'\btongcong\b|'
    r'\btổng\s*tiền\b|'
    r'\btong\s*tien\b|'
    r'\btổng\s*thanh\s*toán\b|'
    r'\btong\s*thanh\s*toan\b|'
    r'\btổng\s*số\s*tiền\b|'
    r'\btong\s*so\s*tien\b|'
    r'\bthanh\s*toán\b|'
    r'\bthanh\s*toan\b|'
    r'\bthành\s*tiền\b|'
    r'\bthanh\s*tien\b|'
    r'\bkhách\s*trả\b|'
    r'\bkhach\s*tra\b|'
    r'\bkhách\s*phải\s*trả\b|'
    r'\bkhach\s*phai\s*tra\b|'
    r'\btiền\s*khách\b|'
    r'\btien\s*khach\b|'
    r'\btiền\s*khách\s*trả\b|'
    r'\btien\s*khach\s*tra\b|'
    r'\bsố\s*tiền\s*thanh\s*toán\b|'
    r'\bso\s*tien\s*thanh\s*toan\b|'
    r'\bcần\s*thanh\s*toán\b|'
    r'\bcan\s*thanh\s*toan\b|'
    r'\btổng\b(?=\s*[:]?\s*[0-9])|'
    r'\btong\b(?=\s*[:]?\s*[0-9])'
    r')',
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

  // ─── Item Extraction ──────────────────────────────────────────────────────

  List<ReceiptItem> _extractItems(List<String> lines, List<_OcrLine> ocrLines) {
    final usedIndices = <int>{};

    // Pass 1 — supermarket multi-line: name row + price row
    final multiLine = _extractItemsMultiLine(lines, ocrLines, usedIndices);

    // Pass 2 — single-line items for unused rows
    final singleLine = _extractItemsSingleLine(lines, ocrLines, usedIndices);

    return _deduplicateItems([...multiLine, ...singleLine]);
  }

  // ── Pass 1: Multi-line (name line → price row below) ────────────────────

  List<ReceiptItem> _extractItemsMultiLine(
    List<String> lines,
    List<_OcrLine> ocrLines,
    Set<int> usedIndices,
  ) {
    final items = <ReceiptItem>[];

    for (var i = 0; i < lines.length - 1; i++) {
      final nameLine = lines[i];
      final nameLower = nameLine.toLowerCase();

      if (_looksLikeNoise(nameLine)) continue;
      if (!_containsLetters(nameLine)) continue;
      if (_totalHintRegex.hasMatch(nameLower)) continue;
      if (_notTotalLineRegex.hasMatch(nameLower)) continue;
      if (_ignoreLineRegex.hasMatch(nameLower)) continue;
      // Reject lines that are themselves price rows (no letter-dominant content)
      if (_isPriceRowLine(nameLine) && !_containsLetters(nameLine)) continue;

      // ── Look ahead 1 or 2 lines for the price row ─────────────────────────
      // Some receipts insert a sub-description / weight line between the
      // product name and the price line, so we check i+1 and i+2.
      int? priceRowIdx;
      for (var ahead = 1; ahead <= 2; ahead++) {
        final idx = i + ahead;
        if (idx >= lines.length) break;

        final candidate = lines[idx];
        final candidateLower = candidate.toLowerCase();

        // If the intermediate line (ahead==2 only) looks like another product
        // name, stop looking — we'd be pairing the wrong lines.
        if (ahead == 2) {
          final midLine = lines[i + 1];
          final midLower = midLine.toLowerCase();
          // Intermediate line is another name → stop
          if (_containsLetters(midLine) &&
              !_isPriceRowLine(midLine) &&
              !_totalHintRegex.hasMatch(midLower) &&
              !_ignoreLineRegex.hasMatch(midLower)) {
            break;
          }
        }

        if (!_isPriceRowLine(candidate)) continue;
        if (_totalHintRegex.hasMatch(candidateLower)) continue;
        if (_notTotalLineRegex.hasMatch(candidateLower)) continue;
        if (_ignoreLineRegex.hasMatch(candidateLower)) continue;

        priceRowIdx = idx;
        break;
      }

      if (priceRowIdx == null) continue;

      final priceLine = lines[priceRowIdx];
      final priceElements = priceRowIdx < ocrLines.length
          ? ocrLines[priceRowIdx].elements
          : null;
      final subtotal = _extractSubtotalFromPriceRow(
        priceLine,
        elements: priceElements,
      );
      if (subtotal == null) continue;
      if (!_isPlausibleMoneyAmount(subtotal)) continue;

      final name = _cleanupItemName(nameLine);
      if (name.isEmpty) continue;

      items.add(
        ReceiptItem(
          name: name,
          amount: subtotal,
          category: _detectCategory(name),
          confidence: _estimateConfidence(name, priceLine).clamp(0.0, 0.95),
        ),
      );

      // Mark all consumed lines
      for (var j = i; j <= priceRowIdx; j++) {
        usedIndices.add(j);
      }
      i = priceRowIdx; // skip to after the price row
    }

    return items;
  }

  // ── Pass 2: Single-line items ────────────────────────────────────────────

  List<ReceiptItem> _extractItemsSingleLine(
    List<String> lines,
    List<_OcrLine> ocrLines,
    Set<int> usedIndices,
  ) {
    final items = <ReceiptItem>[];

    for (var i = 0; i < lines.length; i++) {
      if (usedIndices.contains(i)) continue;

      final line = lines[i];
      final lower = line.toLowerCase();

      if (_ignoreLineRegex.hasMatch(lower)) continue;
      if (_totalHintRegex.hasMatch(lower)) continue;
      if (_notTotalLineRegex.hasMatch(lower)) continue;
      if (_looksLikeNoise(line)) continue;
      // Pure price rows with no letters → skip (handled by multi-line pass)
      if (_isPriceRowLine(line) && !_containsLetters(line)) continue;

      // ── Use spatial rightmost-number heuristic when possible ─────────────
      // For rows that mix name + multiple numbers, the rightmost token with a
      // thousand-separator is most likely the item total/price.
      final rowElements = i < ocrLines.length
          ? ocrLines[i].elements
          : <_OcrElement>[];
      if (rowElements.length >= 2) {
        final spatialItem = _extractItemFromRow(rowElements, line, lower);
        if (spatialItem != null) {
          items.add(spatialItem);
          continue;
        }
      }

      // ── Fallback: classic regex matching ──────────────────────────────────
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
      if (name.isEmpty || !_containsLetters(name)) continue;

      final amount = _parseAmount(rawAmount, unit);
      if (amount <= 0 || !_isPlausibleMoneyAmount(amount)) continue;
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

      items.add(
        ReceiptItem(
          name: name,
          amount: amount,
          category: _detectCategory(name),
          confidence: _estimateConfidence(rawName, rawAmount),
        ),
      );
    }

    return items;
  }

  /// Spatial extraction for a single row with element positions.
  ///
  /// Strategy:
  /// 1. Walk elements right-to-left; the first plausible money token is the
  ///    item price (rightmost = total column on the receipt).
  /// 2. Adjacent small number tokens (OCR split of "5 500") are combined.
  /// 3. Everything to the left of the price token(s) is the product name.
  ReceiptItem? _extractItemFromRow(
    List<_OcrElement> elements,
    String fullLine,
    String lineLower,
  ) {
    if (_totalHintRegex.hasMatch(lineLower)) return null;
    if (_notTotalLineRegex.hasMatch(lineLower)) return null;
    if (_ignoreLineRegex.hasMatch(lineLower)) return null;

    // Find the rightmost plausible price token (right-to-left scan).
    // Also handles OCR-split amounts like ["5", "500"] → 5500.
    int priceIdx = -1;
    double amount = 0;
    String rawAmount = '';

    for (var i = elements.length - 1; i >= 0; i--) {
      // Strip trailing currency symbols so "5.500đ" is treated as "5.500"
      final cleanToken = elements[i].text
          .trim()
          .replaceAll(
            RegExp(r'[₫đ]$|\bvnd\b|\bvnđ\b|\bdong\b', caseSensitive: false),
            '',
          )
          .trim();

      if (!RegExp(r'^[0-9][0-9.,]*$').hasMatch(cleanToken)) continue;
      if (_isLikelyCode(cleanToken)) continue;

      var parsed = _parseAmount(cleanToken, '');

      // If this token alone isn't plausible, try combining with the token to
      // its LEFT (OCR sometimes splits "5 500" into two elements).
      if (!_isPlausibleMoneyAmount(parsed) && i > 0) {
        final leftToken = elements[i - 1].text.trim();
        final combined = '$leftToken $cleanToken';
        final combinedParsed = _tryParseSpaceSeparated(combined);
        if (combinedParsed != null && _isPlausibleMoneyAmount(combinedParsed)) {
          parsed = combinedParsed;
          // Treat the left token as part of the amount, shift priceIdx left
          priceIdx = i - 1;
          amount = parsed;
          rawAmount = combined;
          break;
        }
      }

      if (!_isPlausibleMoneyAmount(parsed)) continue;
      if (!_hasMoneySignal(line: fullLine, rawAmount: cleanToken, unit: '')) {
        continue;
      }
      priceIdx = i;
      amount = parsed;
      rawAmount = cleanToken;
      break;
    }

    if (priceIdx < 0) return null;
    if (_looksLikePhoneOrTaxId(
      rawAmount: rawAmount,
      unit: '',
      lineLower: lineLower,
    )) {
      return null;
    }

    // Name = all text tokens BEFORE the price cluster, keeping only those
    // that contain at least one letter or a unit suffix (ml, g, kg, l, oz).
    final nameParts = <String>[];
    for (var i = 0; i < priceIdx; i++) {
      final tok = elements[i].text.trim();
      // A pure number token (no letters, no unit suffix) is likely qty/price
      final cleanTok = tok
          .replaceAll(
            RegExp(r'[₫đ]$|\bvnd\b|\bvnđ\b', caseSensitive: false),
            '',
          )
          .trim();
      if (RegExp(r'^[0-9][0-9.,]*$').hasMatch(cleanTok) &&
          !RegExp(
            r'(ml|g|kg|l|oz|pack|gói|hộp|chai|lon|cái|túi)$',
            caseSensitive: false,
          ).hasMatch(tok)) {
        continue; // skip pure-number tokens (qty / unit price columns)
      }
      nameParts.add(tok);
    }

    final rawName = nameParts.join(' ');
    final name = _cleanupItemName(rawName);
    if (name.isEmpty || !_containsLetters(name)) return null;

    return ReceiptItem(
      name: name,
      amount: amount,
      category: _detectCategory(name),
      confidence: _estimateConfidence(rawName, rawAmount),
    );
  }

  /// Try to parse a space-separated thousands number, e.g. "5 500" → 5500.
  double? _tryParseSpaceSeparated(String s) {
    final parts = s.trim().split(RegExp(r'\s+'));
    if (parts.length != 2) return null;
    final left = parts[0].replaceAll(RegExp(r'[^0-9]'), '');
    final right = parts[1].replaceAll(RegExp(r'[^0-9]'), '');
    if (left.isEmpty || right.isEmpty) return null;
    // Only valid if right part is exactly 3 digits (standard thousands group)
    if (right.length != 3) return null;
    return double.tryParse('$left$right');
  }

  List<ReceiptItem> _deduplicateItems(List<ReceiptItem> items) {
    final seen = <String>{};
    return items
        .where((item) {
          final key =
              '${item.name.toLowerCase().trim()}|${item.amount.toStringAsFixed(0)}';
          return seen.add(key);
        })
        .toList(growable: false);
  }

  // ─── Total Extraction ─────────────────────────────────────────────────────

  // ── Regex to identify lines that are NOT the real total ──────────────────
  // These are "customer paid" / "change" / "discount" / "loyalty" lines.
  // They appear near the total but should NOT be selected as the total.
  static final RegExp _notTotalLineRegex = RegExp(
    r'(?:'
    r'\btiền\s*thừa\b|'
    r'\btien\s*thua\b|'
    r'\btiền\s*trả\s*lại\b|'
    r'\btien\s*tra\s*lai\b|'
    r'\btiền\s*mặt\b|'
    r'\btien\s*mat\b|'
    r'\btiền\s*khách\s*đưa\b|'
    r'\btien\s*khach\s*dua\b|'
    r'\bkhách\s*đưa\b|'
    r'\bkhach\s*dua\b|'
    r'\bchiết\s*khấu\b|'
    r'\bchiet\s*khau\b|'
    r'\bgiảm\s*giá\b|'
    r'\bgiam\s*gia\b|'
    r'\bdiscount\b|'
    r'\bchange\b|'
    r'\bcash\s*received\b|'
    r'\bcash\s*tendered\b|'
    r'\bđiểm\s*tích\s*lũy\b|'
    r'\bdiem\s*tich\s*luy\b|'
    r'\bđiểm\s*thưởng\b|'
    r'\bdiem\s*thuong\b|'
    r'\bsaving\b|'
    r'\bvat\b|'
    r'\bthuế\b|'
    r'\bthue\b|'
    r'\btax\b'
    r')',
    caseSensitive: false,
  );

  // ── Regex for the "best" total keywords — highest confidence ────────────
  // "Tổng cộng", "Tổng tiền", "Tổng thanh toán", "Thành tiền" are the
  // canonical total labels on Vietnamese invoices.
  static final RegExp _primaryTotalRegex = RegExp(
    r'(?:'
    r'\btổng\s*cộng\b|'
    r'\btong\s*cong\b|'
    r'\btongcong\b|'
    r'\btổng\s*tiền\b|'
    r'\btong\s*tien\b|'
    r'\btổng\s*thanh\s*toán\b|'
    r'\btong\s*thanh\s*toan\b|'
    r'\btổng\s*số\s*tiền\b|'
    r'\btong\s*so\s*tien\b|'
    r'\bthành\s*tiền\b|'
    r'\bthanh\s*tien\b|'
    r'\bgrand\s*total\b|'
    r'\btotal\s*amount\b|'
    r'\bamount\s*due\b|'
    r'\bcần\s*thanh\s*toán\b|'
    r'\bcan\s*thanh\s*toan\b'
    r')',
    caseSensitive: false,
  );

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

      if (!_strongTotalHintRegex.hasMatch(lower)) continue;

      // ── Skip lines that are NOT the real total ─────────────────────────
      // "Tiền mặt", "Tiền thừa", "Chiết khấu", etc. should never win.
      if (_notTotalLineRegex.hasMatch(lower)) continue;

      final scoreBase = _scoreLinePosition(i, lines.length, ocrLines);

      // ── Tiered hint scoring ────────────────────────────────────────────
      // Primary keywords ("Tổng cộng") get a big bonus over secondary
      // keywords ("Thanh toán", "Khách trả") so the real total wins even
      // when the customer-payment line appears lower on the receipt.
      final double hintScore;
      if (_primaryTotalRegex.hasMatch(lower)) {
        hintScore = 12.0; // strong signal — this IS the total line
      } else {
        hintScore = 6.0; // secondary signal
      }

      // Use rightmost element in the row as the total candidate
      final rowElements = i < ocrLines.length
          ? ocrLines[i].elements
          : <_OcrElement>[];
      _AmountToken? bestToken;

      if (rowElements.isNotEmpty) {
        // Walk right-to-left to find the rightmost plausible amount
        for (final el in rowElements.reversed) {
          final raw = el.text.trim();
          if (!RegExp(r'^[0-9][0-9.,]*$').hasMatch(raw)) continue;
          if (_isLikelyCode(raw)) continue;
          final amount = _parseAmount(raw, '');
          if (!_isPlausibleMoneyAmount(amount)) continue;
          if (_looksLikePhoneOrTaxId(
            rawAmount: raw,
            unit: '',
            lineLower: lower,
          )) {
            continue;
          }
          bestToken = _AmountToken(
            raw: raw,
            unit: '',
            isAtEnd: true,
            hasSeparators: raw.contains('.') || raw.contains(','),
          );
          break;
        }
      }

      // Fallback: use classical regex token extraction
      bestToken ??= _pickBestAmountToken(_extractAmountTokens(line), lower);

      // If still nothing on this line, look at the next line (amount on
      // a separate row directly below the label)
      if (bestToken == null && i + 1 < lines.length) {
        final nextLine = lines[i + 1];
        final nextLower = nextLine.toLowerCase();
        if (!_ignoreLineRegex.hasMatch(nextLower) &&
            !_totalHintRegex.hasMatch(nextLower)) {
          bestToken = _pickBestAmountToken(
            _extractAmountTokens(nextLine),
            nextLower,
          );
        }
      }

      if (bestToken != null) {
        final amount = _parseAmount(bestToken.raw, bestToken.unit);
        final score =
            hintScore +
            scoreBase +
            (bestToken.hasSeparators ? 1.0 : 0.0) +
            (bestToken.isAtEnd ? 2.0 : 0.0);
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

    // ── Sort: highest score wins; on tie, prefer the LARGEST amount ──────
    candidates.sort((a, b) {
      final s = b.score.compareTo(a.score);
      if (s != 0) return s;
      return b.amount.compareTo(a.amount);
    });

    if (candidates.isNotEmpty) return candidates.first.amount;

    // Fallback 1: sum of items
    if (items.isNotEmpty) {
      final sum = items.fold<double>(0, (acc, e) => acc + e.amount);
      if (sum > 0) return sum;
    }

    // Fallback 2: largest amount in bottom 40% of receipt
    final bottom = _extractLargestFromBottom(lines, ocrLines);
    if (bottom > 0) return bottom;

    return _largestNumber(lines);
  }

  _AmountToken? _pickBestAmountToken(
    List<_AmountToken> tokens,
    String lineLower,
  ) {
    _AmountToken? best;
    for (final amt in tokens) {
      final amount = _parseAmount(amt.raw, amt.unit);
      if (!_isPlausibleMoneyAmount(amount)) continue;
      if (_looksLikePhoneOrTaxId(
        rawAmount: amt.raw,
        unit: amt.unit,
        lineLower: lineLower,
      )) {
        continue;
      }
      if (best == null) {
        best = amt;
      } else {
        final bestAmt = _parseAmount(best.raw, best.unit);
        if (amt.isAtEnd && !best.isAtEnd) {
          best = amt;
        } else if (!best.isAtEnd && !amt.isAtEnd && amount > bestAmt) {
          best = amt;
        } else if (best.isAtEnd && amt.isAtEnd && amount > bestAmt) {
          best = amt;
        }
      }
    }
    return best;
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
    final takeCount = (lines.length * 0.4).ceil().clamp(5, lines.length);
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
    final norm = line.replaceAll(RegExp(r'\s+'), ' ').trim();

    for (final m in _currencyBeforeAmountRegex.allMatches(norm)) {
      final raw = (m.group(1) ?? '').trim();
      final unit = (m.group(2) ?? '').trim().toLowerCase();
      tokens.add(
        _AmountToken(
          raw: raw,
          unit: unit,
          isAtEnd: false,
          hasSeparators: raw.contains('.') || raw.contains(','),
        ),
      );
    }

    for (final m in _amountBeforeCurrencyRegex.allMatches(norm)) {
      final raw = (m.group(1) ?? '').trim();
      final unit = (m.group(2) ?? '').trim().toLowerCase();
      tokens.add(
        _AmountToken(
          raw: raw,
          unit: unit,
          isAtEnd: norm.endsWith(m.group(0) ?? ''),
          hasSeparators: raw.contains('.') || raw.contains(','),
        ),
      );
    }

    final endMatch = _totalAmountAtEndRegex.firstMatch(norm);
    if (endMatch != null) {
      final raw = (endMatch.group(1) ?? '').trim();
      final unit = (endMatch.group(2) ?? '').trim().toLowerCase();
      tokens.add(
        _AmountToken(
          raw: raw,
          unit: unit,
          isAtEnd: true,
          hasSeparators: raw.contains('.') || raw.contains(','),
        ),
      );
    }

    final numRegex = RegExp(r'([0-9][0-9., ]{0,20})\s*([kKmM]|tr)?\b');
    for (final m in numRegex.allMatches(norm)) {
      final raw = (m.group(1) ?? '').trim();
      final unit = (m.group(2) ?? '').trim().toLowerCase();
      final whole = m.group(0) ?? '';
      tokens.add(
        _AmountToken(
          raw: raw,
          unit: unit,
          isAtEnd: norm.endsWith(whole),
          hasSeparators: raw.contains('.') || raw.contains(','),
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

  void dispose() {
    _textRecognizer.close();
  }
}

// ─── Private Data Classes ─────────────────────────────────────────────────────

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
