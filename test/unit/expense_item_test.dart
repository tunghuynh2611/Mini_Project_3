import 'package:flutter_test/flutter_test.dart';
import 'package:expense_ocr/features/expense/models/expense_category.dart';
import 'package:expense_ocr/features/expense/models/expense_item.dart';

void main() {
  group('ExpenseItem Model Tests', () {
    test('Serializes to and from Map accurately for SQLite storage', () {
      final now = DateTime(2026, 10, 15, 12, 30);
      final item = ExpenseItem(
        id: 1,
        merchantName: 'WinMart+',
        amount: 194400.0,
        date: now,
        category: ExpenseCategory.food,
        receiptImagePath: '/path/to/receipt.jpg',
        notes: 'Grocery items',
        createdAt: now,
      );

      final map = item.toMap();
      expect(map['id'], equals(1));
      expect(map['merchant_name'], equals('WinMart+'));
      expect(map['amount'], equals(194400.0));
      expect(map['category'], equals('food'));
      expect(map['receipt_image_path'], equals('/path/to/receipt.jpg'));
      expect(map['notes'], equals('Grocery items'));

      final reconstructed = ExpenseItem.fromMap(map);
      expect(reconstructed.id, equals(item.id));
      expect(reconstructed.merchantName, equals(item.merchantName));
      expect(reconstructed.amount, equals(item.amount));
      expect(reconstructed.category, equals(item.category));
      expect(reconstructed.receiptImagePath, equals(item.receiptImagePath));
      expect(reconstructed.notes, equals(item.notes));
    });

    test('copyWith updates properties properly', () {
      final item = ExpenseItem(
        id: 1,
        merchantName: 'Original Merchant',
        amount: 100.0,
        date: DateTime(2026, 1, 1),
        category: ExpenseCategory.other,
        receiptImagePath: '',
      );

      final updated = item.copyWith(
        merchantName: 'Updated Merchant',
        amount: 250.0,
        category: ExpenseCategory.gear,
      );

      expect(updated.id, equals(1));
      expect(updated.merchantName, equals('Updated Merchant'));
      expect(updated.amount, equals(250.0));
      expect(updated.category, equals(ExpenseCategory.gear));
    });

    test('ExpenseCategory parses correctly from string', () {
      expect(ExpenseCategory.fromString('food'), equals(ExpenseCategory.food));
      expect(ExpenseCategory.fromString('STUDY'), equals(ExpenseCategory.study));
      expect(ExpenseCategory.fromString('unknown_val'), equals(ExpenseCategory.other));
      expect(ExpenseCategory.fromString(null), equals(ExpenseCategory.other));
    });
  });
}

