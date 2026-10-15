import 'package:flutter_test/flutter_test.dart';
import 'package:expense_ocr/core/services/ocr_service.dart';
import 'package:expense_ocr/core/utils/regex_heuristics.dart';
import 'package:expense_ocr/features/expense/models/expense_category.dart';

void main() {
  group('RegexHeuristicsEngine Tests', () {
    test('Correctly extracts WinMart supermarket receipt', () {
      final data = RegexHeuristicsEngine.parse(SampleReceipts.winmart);

      expect(data.merchantName.toLowerCase(), contains('winmart'));
      // Total is 194.400 đ
      expect(data.amount, equals(194400.0));
      // Date is 15/10/2026
      expect(data.date.day, equals(15));
      expect(data.date.month, equals(10));
      expect(data.date.year, equals(2026));
      expect(data.category, equals(ExpenseCategory.food));
      expect(data.confidenceScore, greaterThan(0.7));
    });

    test('Correctly extracts Highlands Coffee receipt', () {
      final data = RegexHeuristicsEngine.parse(SampleReceipts.highlandsCoffee);

      expect(data.merchantName.toLowerCase(), contains('highlands'));
      // Total is 194.000 VND
      expect(data.amount, equals(194000.0));
      // Date is 14/10/2026
      expect(data.date.day, equals(14));
      expect(data.date.month, equals(10));
      expect(data.date.year, equals(2026));
      expect(data.category, equals(ExpenseCategory.food));
    });

    test('Correctly extracts Fahasa Bookstore receipt', () {
      final data = RegexHeuristicsEngine.parse(SampleReceipts.fahasaBookstore);

      expect(data.merchantName.toLowerCase(), contains('fahasa'));
      // Total is 233.000 đ
      expect(data.amount, equals(233000.0));
      // Date is 12/10/2026
      expect(data.date.day, equals(12));
      expect(data.date.month, equals(10));
      expect(data.date.year, equals(2026));
      expect(data.category, equals(ExpenseCategory.study));
    });

    test('Correctly extracts Circle K convenience store receipt', () {
      final data = RegexHeuristicsEngine.parse(SampleReceipts.circleK);

      expect(data.merchantName.toLowerCase(), contains('circle k'));
      // Total is 64.800 VND
      expect(data.amount, equals(64800.0));
      // Date is 10/10/2026
      expect(data.date.day, equals(10));
      expect(data.date.month, equals(10));
      expect(data.date.year, equals(2026));
      expect(data.category, equals(ExpenseCategory.food));
    });

    test('Correctly extracts Grab Ride receipt', () {
      final data = RegexHeuristicsEngine.parse(SampleReceipts.grabRide);

      expect(data.merchantName.toLowerCase(), contains('grab'));
      // Total is 70.000 đ
      expect(data.amount, equals(70000.0));
      expect(data.category, equals(ExpenseCategory.travel));
    });

    test('Does not confuse cash tendered or change with total amount', () {
      const sampleWithChange = '''
TỔNG CỘNG: 150.000 đ
TIỀN KHÁCH ĐƯA: 500.000 đ
TIỀN THỐI: 350.000 đ
''';
      final data = RegexHeuristicsEngine.parse(sampleWithChange);
      expect(data.amount, equals(150000.0));
    });

    test('Handles fallback for empty string without throwing', () {
      final data = RegexHeuristicsEngine.parse('');
      expect(data.amount, equals(0.0));
      expect(data.confidenceScore, equals(0.0));
    });
  });
}

