import 'package:flutter_test/flutter_test.dart';
import 'package:expense_ocr/core/utils/currency_formatter.dart';

void main() {
  group('CurrencyFormatter Tests', () {
    test('Formats currency with VND symbol', () {
      final formatted = CurrencyFormatter.format(150000);
      expect(formatted, contains('150.000'));
      expect(formatted, contains('₫'));
    });

    test('Formats compact figures correctly', () {
      expect(CurrencyFormatter.formatCompact(500), equals('500 ₫'));
      expect(CurrencyFormatter.formatCompact(150000), equals('150K ₫'));
      expect(CurrencyFormatter.formatCompact(1500000), equals('1.5M ₫'));
      expect(CurrencyFormatter.formatCompact(2000000000), equals('2.0B ₫'));
    });

    test('Parses various currency formats into clean double', () {
      // Vietnamese format dot as thousand
      expect(CurrencyFormatter.parseAmount('150.000'), equals(150000.0));
      expect(CurrencyFormatter.parseAmount('150.000 đ'), equals(150000.0));
      expect(CurrencyFormatter.parseAmount('150.000 VND'), equals(150000.0));
      expect(CurrencyFormatter.parseAmount('1.250.000'), equals(1250000.0));

      // US format comma as thousand
      expect(CurrencyFormatter.parseAmount('150,000'), equals(150000.0));
      expect(CurrencyFormatter.parseAmount('\$45.50'), equals(45.50));
      expect(CurrencyFormatter.parseAmount('1,500.50'), equals(1500.50));

      // Invalid returns null
      expect(CurrencyFormatter.parseAmount(''), isNull);
      expect(CurrencyFormatter.parseAmount('abc'), isNull);
    });
  });
}

