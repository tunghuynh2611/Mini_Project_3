import 'package:flutter_test/flutter_test.dart';
import 'package:expense_ocr/core/utils/date_formatter.dart';

void main() {
  group('DateFormatter Tests', () {
    test('Formats date correctly', () {
      final date = DateTime(2026, 10, 15);
      expect(DateFormatter.format(date), equals('15/10/2026'));
    });

    test('Parses DD/MM/YYYY format', () {
      final parsed = DateFormatter.parse('15/10/2026');
      expect(parsed, isNotNull);
      expect(parsed!.day, equals(15));
      expect(parsed.month, equals(10));
      expect(parsed.year, equals(2026));
    });

    test('Parses DD-MM-YYYY and DD.MM.YYYY formats', () {
      final parsed1 = DateFormatter.parse('15-10-2026');
      final parsed2 = DateFormatter.parse('15.10.2026');
      expect(parsed1, isNotNull);
      expect(parsed2, isNotNull);
      expect(parsed1!.day, equals(15));
      expect(parsed2!.day, equals(15));
    });

    test('Parses Vietnamese text date format', () {
      final parsed = DateFormatter.parse('Ngày 15 tháng 10 năm 2026');
      expect(parsed, isNotNull);
      expect(parsed!.day, equals(15));
      expect(parsed.month, equals(10));
      expect(parsed.year, equals(2026));
    });

    test('Calculates start and end of week accurately', () {
      final date = DateTime(2026, 10, 15); // Thursday
      final start = DateFormatter.getStartOfWeek(date);
      final end = DateFormatter.getEndOfWeek(date);

      expect(start.weekday, equals(DateTime.monday));
      expect(end.weekday, equals(DateTime.sunday));
    });
  });
}

