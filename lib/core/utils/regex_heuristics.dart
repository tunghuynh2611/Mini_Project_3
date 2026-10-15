import '../../features/expense/models/expense_category.dart';
import 'currency_formatter.dart';
import 'date_formatter.dart';

/// Extracted structured receipt data with heuristic confidence scoring.
class ExtractedReceiptData {
  final String merchantName;
  final double amount;
  final DateTime date;
  final ExpenseCategory category;
  final String rawText;
  final double confidenceScore; // 0.0 to 1.0
  final Map<String, dynamic> debugDetails;

  const ExtractedReceiptData({
    required this.merchantName,
    required this.amount,
    required this.date,
    required this.category,
    required this.rawText,
    required this.confidenceScore,
    this.debugDetails = const {},
  });

  ExtractedReceiptData copyWith({
    String? merchantName,
    double? amount,
    DateTime? date,
    ExpenseCategory? category,
    String? rawText,
    double? confidenceScore,
    Map<String, dynamic>? debugDetails,
  }) {
    return ExtractedReceiptData(
      merchantName: merchantName ?? this.merchantName,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      rawText: rawText ?? this.rawText,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      debugDetails: debugDetails ?? this.debugDetails,
    );
  }
}

/// Robust Heuristic Regex Engine for parsing raw OCR receipt text.
/// Extracts total amount, transaction date, merchant name, and suggests expense categories.
class RegexHeuristicsEngine {
  RegexHeuristicsEngine._();

  // Common noise lines to ignore when finding merchant names
  static final List<RegExp> _merchantNoisePatterns = [
    RegExp(r'h[oó][aá]\s*đ[oơ]n', caseSensitive: false), // Hóa đơn
    RegExp(r'phi[eế]u\s*(thanh\s*to[aá]n|t[ií]nh\s*ti[eề]n)', caseSensitive: false),
    RegExp(r'receipt|tax\s*invoice|bill|sales\s*receipt', caseSensitive: false),
    RegExp(r'gi[aá]\s*tr[iị]\s*gia\s*t[aă]ng|vat', caseSensitive: false),
    RegExp(r'^(ng[aà]y|date|time|gi[oờ]):', caseSensitive: false),
    RegExp(r'^(mst|stt|m[aã]\s*s[oố]|pos|quay|b[aà]n|table):', caseSensitive: false),
    RegExp(r'^(tel|s[dđ]t|hotline|phone|fax|email|website|wifi):', caseSensitive: false),
    RegExp(r'^[dđ][iị]a\s*ch[iỉ]|^add(ress)?:', caseSensitive: false),
    RegExp(r'^(thu\s*ng[aâ]n|cashier|nh[aâ]n\s*vi[eê]n):', caseSensitive: false),
    RegExp(r'^[\s\-_=.*#@!~]+$'), // pure symbols
  ];

  // Well-known popular merchant brand signatures for instant 100% recognition
  static final Map<String, ExpenseCategory> _knownBrands = {
    'winmart+': ExpenseCategory.food,
    'winmart': ExpenseCategory.food,
    'circle k': ExpenseCategory.food,
    'highlands coffee': ExpenseCategory.food,
    'highlands': ExpenseCategory.food,
    'starbucks': ExpenseCategory.food,
    'phúc long': ExpenseCategory.food,
    'phuc long': ExpenseCategory.food,
    'the coffee house': ExpenseCategory.food,
    'katinat': ExpenseCategory.food,
    'gs25': ExpenseCategory.food,
    'co.opmart': ExpenseCategory.food,
    'coopmart': ExpenseCategory.food,
    'co.op food': ExpenseCategory.food,
    'bách hóa xanh': ExpenseCategory.food,
    'bach hoa xanh': ExpenseCategory.food,
    'familymart': ExpenseCategory.food,
    '7-eleven': ExpenseCategory.food,
    '7 eleven': ExpenseCategory.food,
    'ministop': ExpenseCategory.food,
    'lotte mart': ExpenseCategory.food,
    'aeon mall': ExpenseCategory.food,
    'aeon': ExpenseCategory.food,
    'kfc': ExpenseCategory.food,
    'lotteria': ExpenseCategory.food,
    'jollibee': ExpenseCategory.food,
    'mcdonald': ExpenseCategory.food,
    'pizza 4p': ExpenseCategory.food,
    'pizza hut': ExpenseCategory.food,
    'domino': ExpenseCategory.food,
    'texas chicken': ExpenseCategory.food,
    'fahasa': ExpenseCategory.study,
    'nhà sách tiền phong': ExpenseCategory.study,
    'nhà sách phương nam': ExpenseCategory.study,
    'nhà sách': ExpenseCategory.study,
    'grab': ExpenseCategory.travel,
    'be': ExpenseCategory.travel,
    'gojek': ExpenseCategory.travel,
    'petrolimex': ExpenseCategory.travel,
    'mai linh': ExpenseCategory.travel,
    'shopee': ExpenseCategory.gear,
    'lazada': ExpenseCategory.gear,
    'tiki': ExpenseCategory.gear,
    'fpt shop': ExpenseCategory.gear,
    'thegioididong': ExpenseCategory.gear,
    'cellphones': ExpenseCategory.gear,
    'cgv': ExpenseCategory.entertainment,
    'lotte cinema': ExpenseCategory.entertainment,
    'galaxy cinema': ExpenseCategory.entertainment,
    'bhd star': ExpenseCategory.entertainment,
  };

  // Grand total keywords (highest priority)
  static final List<RegExp> _grandTotalKeywords = [
    RegExp(r't[oổ]ng\s*c[oộ]ng', caseSensitive: false), // Tổng cộng
    RegExp(r't[oổ]ng\s*ti[eề]n', caseSensitive: false), // Tổng tiền
    RegExp(r'ti[eề]n\s*ph[aả]i\s*tr[aả]', caseSensitive: false),
    RegExp(r'kh[aá]ch\s*ph[aả]i\s*tr[aả]', caseSensitive: false),
    RegExp(r'grand\s*total', caseSensitive: false),
    RegExp(r'total\s*due', caseSensitive: false),
    RegExp(r'amount\s*due', caseSensitive: false),
    RegExp(r'balance\s*due', caseSensitive: false),
    RegExp(r'final\s*total', caseSensitive: false),
  ];

  // Standard total keywords (medium priority)
  static final List<RegExp> _standardTotalKeywords = [
    RegExp(r'thanh\s*to[aá]n', caseSensitive: false), // Thanh toán
    RegExp(r'\btotal\b', caseSensitive: false),
    RegExp(r't[oổ]ng', caseSensitive: false),
  ];

  // Subtotal keywords (lower priority, used if grand total is missing)
  static final List<RegExp> _subtotalKeywords = [
    RegExp(r'c[oộ]ng\s*ti[eề]n\s*h[aà]ng', caseSensitive: false),
    RegExp(r'c[oộ]ng\s*ti[eề]n', caseSensitive: false),
    RegExp(r'subtotal', caseSensitive: false),
    RegExp(r'ti[eề]n\s*h[aà]ng', caseSensitive: false),
  ];

  // Disqualifying keywords that represent header titles rather than total rows
  static final RegExp _headerTitlePattern = RegExp(
    r'phi[eế]u\s*(thanh\s*to[aá]n|t[ií]nh\s*ti[eề]n|thu)|h[oó][aá]\s*đ[oơ]n|receipt|tax\s*invoice|sales\s*receipt|bi[eê]n\s*nh[aâ]n',
    caseSensitive: false,
  );

  // Disqualifying keywords that represent tender or change rather than total bill
  static final List<RegExp> _nonTotalKeywords = [
    RegExp(r'ti[eề]n\s*kh[aá]ch\s*[dđ][uư]a', caseSensitive: false), // Tiền khách đưa
    RegExp(r'ti[eề]n\s*th[oố]i', caseSensitive: false), // Tiền thối
    RegExp(r'ti[eề]n\s*tr[aả]\s*l[aạ]i', caseSensitive: false),
    RegExp(r'cash\s*tendered', caseSensitive: false),
    RegExp(r'change\s*due', caseSensitive: false),
    RegExp(r'\bchange\b', caseSensitive: false),
    RegExp(r'\bvoucher\b', caseSensitive: false),
    RegExp(r'gi[aả]m\s*gi[aá]', caseSensitive: false), // Giảm giá / discount
    RegExp(r'discount', caseSensitive: false),
    RegExp(r'points?', caseSensitive: false),
  ];

  /// Core parsing entrypoint: analyzes raw text string from ML Kit OCR
  static ExtractedReceiptData parse(String rawOcrText) {
    if (rawOcrText.trim().isEmpty) {
      return ExtractedReceiptData(
        merchantName: 'Unknown Merchant',
        amount: 0.0,
        date: DateTime.now(),
        category: ExpenseCategory.other,
        rawText: '',
        confidenceScore: 0.0,
      );
    }

    final lines = rawOcrText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    // 1. Extract Merchant Name
    final merchantResult = _extractMerchant(lines);

    // 2. Extract Date
    final dateResult = _extractDate(lines);

    // 3. Extract Total Amount
    final amountResult = _extractTotalAmount(lines);

    // 4. Infer Category
    final categoryResult = _inferCategory(merchantResult.item, lines);

    // Calculate aggregate heuristic confidence
    double confidence = (merchantResult.confidence * 0.3) +
        (dateResult.confidence * 0.3) +
        (amountResult.confidence * 0.4);

    return ExtractedReceiptData(
      merchantName: merchantResult.item,
      amount: amountResult.item,
      date: dateResult.item,
      category: categoryResult,
      rawText: rawOcrText,
      confidenceScore: confidence.clamp(0.1, 1.0),
      debugDetails: {
        'merchantConfidence': merchantResult.confidence,
        'dateConfidence': dateResult.confidence,
        'amountConfidence': amountResult.confidence,
        'matchedLine': amountResult.debugInfo,
      },
    );
  }

  /// Heuristic to extract store/merchant name
  static _ExtractionResult<String> _extractMerchant(List<String> lines) {
    // Check known brands first throughout top 5 lines
    final inspectCount = lines.length < 6 ? lines.length : 6;
    for (int i = 0; i < inspectCount; i++) {
      final lineLower = lines[i].toLowerCase();
      for (final entry in _knownBrands.entries) {
        if (lineLower.contains(entry.key)) {
          // Format brand nicely
          return _ExtractionResult(
            item: _titleCase(entry.key),
            confidence: 0.98,
          );
        }
      }
    }

    // Heuristic: examine first 4 lines, discard noise lines, pick best candidate
    for (int i = 0; i < inspectCount; i++) {
      final line = lines[i];

      // Must have letters
      if (!RegExp(r'[a-zA-Z\p{L}]', unicode: true).hasMatch(line)) continue;

      // Discard noise lines
      bool isNoise = false;
      for (final pattern in _merchantNoisePatterns) {
        if (pattern.hasMatch(line)) {
          isNoise = true;
          break;
        }
      }
      if (isNoise) continue;

      // Check length constraints
      if (line.length >= 3 && line.length <= 60) {
        // Clean line
        final cleaned = line
            .replaceAll(RegExp(r'[*#@!=_]'), '')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        return _ExtractionResult(item: cleaned, confidence: 0.85);
      }
    }

    return _ExtractionResult(
      item: lines.isNotEmpty ? lines.first : 'Receipt Merchant',
      confidence: 0.4,
    );
  }

  /// Heuristic to extract transaction date
  static _ExtractionResult<DateTime> _extractDate(List<String> lines) {
    // 1. Scan for lines containing date keywords first (higher priority)
    for (final line in lines) {
      if (RegExp(r'ng[aà]y|date|th[oờ]i\s*gian|time', caseSensitive: false).hasMatch(line)) {
        final parsed = DateFormatter.parse(line);
        if (parsed != null) {
          return _ExtractionResult(item: parsed, confidence: 0.95);
        }
      }
    }

    // 2. Scan every line for general date pattern
    for (final line in lines) {
      final parsed = DateFormatter.parse(line);
      if (parsed != null) {
        return _ExtractionResult(item: parsed, confidence: 0.85);
      }
    }

    // Fallback to today
    return _ExtractionResult(item: DateTime.now(), confidence: 0.3);
  }

  /// Heuristic to extract monetary total
  static _ExtractionResult<double> _extractTotalAmount(List<String> lines) {
    // Pass 1: Scan for Grand Total keywords (highest priority, scanning bottom-up)
    for (int i = lines.length - 1; i >= 0; i--) {
      final line = lines[i];
      if (_isLineDisqualified(line)) continue;

      for (final keyword in _grandTotalKeywords) {
        if (keyword.hasMatch(line)) {
          final amount = _findAmountsInLine(line);
          if (amount != null && amount > 0) {
            return _ExtractionResult(
              item: amount,
              confidence: 0.98,
              debugInfo: 'Matched Grand Total: $line',
            );
          }
          // Check immediate next line if keyword line has no number
          if (i + 1 < lines.length && !_isHeaderLine(lines[i + 1])) {
            final nextAmount = _findAmountsInLine(lines[i + 1]);
            if (nextAmount != null && nextAmount > 0) {
              return _ExtractionResult(
                item: nextAmount,
                confidence: 0.95,
                debugInfo: 'Matched Grand Total next line: ${lines[i + 1]}',
              );
            }
          }
        }
      }
    }

    // Pass 2: Scan for Standard Total keywords (excluding header titles, scanning bottom-up)
    for (int i = lines.length - 1; i >= 0; i--) {
      final line = lines[i];
      if (_isLineDisqualified(line) || _isHeaderLine(line)) continue;

      for (final keyword in _standardTotalKeywords) {
        if (keyword.hasMatch(line)) {
          final amount = _findAmountsInLine(line);
          if (amount != null && amount > 0) {
            return _ExtractionResult(
              item: amount,
              confidence: 0.92,
              debugInfo: 'Matched Standard Total: $line',
            );
          }
          if (i + 1 < lines.length && !_isHeaderLine(lines[i + 1])) {
            final nextAmount = _findAmountsInLine(lines[i + 1]);
            if (nextAmount != null && nextAmount > 0) {
              return _ExtractionResult(
                item: nextAmount,
                confidence: 0.88,
                debugInfo: 'Matched Standard Total next line: ${lines[i + 1]}',
              );
            }
          }
        }
      }
    }

    // Pass 3: Scan for Subtotal keywords (if grand total is not found, e.g. "Cộng tiền", "Subtotal")
    for (int i = lines.length - 1; i >= 0; i--) {
      final line = lines[i];
      if (_isLineDisqualified(line)) continue;

      for (final keyword in _subtotalKeywords) {
        if (keyword.hasMatch(line)) {
          final amount = _findAmountsInLine(line);
          if (amount != null && amount > 0) {
            return _ExtractionResult(
              item: amount,
              confidence: 0.85,
              debugInfo: 'Matched Subtotal: $line',
            );
          }
        }
      }
    }

    // Pass 4: Search for amounts with explicit currency symbol (đ, VND, $, etc.)
    double maxCurrencyAmount = 0.0;
    String matchedLine = '';
    for (final line in lines) {
      if (_isLineDisqualified(line)) continue;

      if (RegExp(r'[₫đ]|vnd|vnđ|\$', caseSensitive: false).hasMatch(line)) {
        final amount = _findAmountsInLine(line);
        if (amount != null && amount > maxCurrencyAmount) {
          maxCurrencyAmount = amount;
          matchedLine = line;
        }
      }
    }

    if (maxCurrencyAmount > 0) {
      return _ExtractionResult(
        item: maxCurrencyAmount,
        confidence: 0.80,
        debugInfo: 'Extracted highest currency line: $matchedLine',
      );
    }

    // Pass 5: Fallback - pick highest plausible number among all lines (excluding phone numbers, dates, IDs)
    double maxPlausibleAmount = 0.0;
    for (final line in lines) {
      if (RegExp(r'mst|tel|phone|s[dđ]t|date|ng[aà]y|\b0\d{9}\b', caseSensitive: false).hasMatch(line)) {
        continue;
      }

      final amount = _findAmountsInLine(line);
      if (amount != null && amount >= 500 && amount <= 500000000) {
        if (amount > maxPlausibleAmount) {
          maxPlausibleAmount = amount;
          matchedLine = line;
        }
      }
    }

    if (maxPlausibleAmount > 0) {
      return _ExtractionResult(
        item: maxPlausibleAmount,
        confidence: 0.60,
        debugInfo: 'Fallback plausible amount: $matchedLine',
      );
    }

    return _ExtractionResult(item: 0.0, confidence: 0.1, debugInfo: 'No amount detected');
  }

  static bool _isLineDisqualified(String line) {
    for (final nonTotal in _nonTotalKeywords) {
      if (nonTotal.hasMatch(line)) return true;
    }
    return false;
  }

  static bool _isHeaderLine(String line) {
    return _headerTitlePattern.hasMatch(line);
  }

  /// Extracts numeric amount from a single line string
  static double? _findAmountsInLine(String rawLine) {
    // 1. Remove time formats like 15:20 or 15:20:30
    String line = rawLine.replaceAll(RegExp(r'\b\d{1,2}:\d{2}(?::\d{2})?\b'), ' ');
    // 2. Remove date formats like 14/10/2026, 14-10-2026, 14.10.2026
    line = line.replaceAll(RegExp(r'\b\d{1,2}[/\-.]\d{1,2}[/\-.]\d{2,4}\b'), ' ');
    // 3. Remove percentage expressions like (8%) or 10%
    line = line.replaceAll(RegExp(r'\b\d+%\b'), ' ');
    // 4. Remove order/table/pos markers like Bàn: 12, Table: 5, Số HĐ: 009214
    line = line.replaceAll(RegExp(r'(b[aà]n|table|s[oố]\s*h[dđ]|quay|pos):\s*\d+', caseSensitive: false), ' ');

    // Match potential numbers with separators: 150,000 | 150.000 | 1,500.00 | 45.50
    final matches = RegExp(r'(\d{1,3}(?:[.,]\d{3})+(?:[.,]\d{1,2})?|\d+(?:[.,]\d{1,2})?)')
        .allMatches(line);

    double? bestAmount;
    for (final match in matches) {
      final token = match.group(0);
      if (token == null) continue;

      // Avoid matching years like 2024, 2025, 2026 if token is just that 4-digit number
      if (token.length == 4 && (token.startsWith('20') || token.startsWith('19'))) {
        continue;
      }

      final parsed = CurrencyFormatter.parseAmount(token);
      if (parsed != null && parsed > 0) {
        if (bestAmount == null || parsed > bestAmount) {
          bestAmount = parsed;
        }
      }
    }

    return bestAmount;
  }

  /// Infers category from merchant name and OCR context lines
  static ExpenseCategory _inferCategory(String merchant, List<String> lines) {
    final lowerMerchant = merchant.toLowerCase();
    for (final entry in _knownBrands.entries) {
      if (lowerMerchant.contains(entry.key)) {
        return entry.value;
      }
    }

    final fullText = lines.join(' ').toLowerCase();

    // Food & Drink keywords
    if (RegExp(r'coffee|cafe|cà phê|trà sữa|food|ăn|uống|quán|cơm|phở|bún|bánh|pizza|burger|nước|bò|gà|mì|chè|restaurant|quán ăn|siêu thị|mart|market|grocery|thịt|cá|rau|trái cây')
        .hasMatch(fullText)) {
      return ExpenseCategory.food;
    }

    // Study & Education keywords
    if (RegExp(r'sách|bút|vở|giấy|nhà sách|bookstore|photo|in ấn|học phí|khóa học|stationery|library|tài liệu|giáo trình|pen|pencil|notebook')
        .hasMatch(fullText)) {
      return ExpenseCategory.study;
    }

    // Travel & Transport keywords
    if (RegExp(r'grab|be|gojek|taxi|xăng|petrol|xe bus|vé xe|vé tàu|vé máy bay|flight|transit|parking|gửi xe|rửa xe|vé cầu đường|bảo dưỡng xe')
        .hasMatch(fullText)) {
      return ExpenseCategory.travel;
    }

    // Gear & Hardware / Electronics keywords
    if (RegExp(r'phone|laptop|chuột|bàn phím|máy tính|tai nghe|headphone|sạc|cáp|adapter|linh kiện|điện thoại|phụ kiện|case|gear|shop|store|electronics')
        .hasMatch(fullText)) {
      return ExpenseCategory.gear;
    }

    // Entertainment & Leisure keywords
    if (RegExp(r'phim|cinema|cgv|lotte|galaxy|vé xem phim|game|steam|playstation|karaoke|billiards|bowling|ticket|du lịch|resort|bar|club|concert')
        .hasMatch(fullText)) {
      return ExpenseCategory.entertainment;
    }

    return ExpenseCategory.food; // Most common receipt type
  }

  static String _titleCase(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}

class _ExtractionResult<T> {
  final T item;
  final double confidence;
  final String? debugInfo;

  _ExtractionResult({
    required this.item,
    required this.confidence,
    this.debugInfo,
  });
}

