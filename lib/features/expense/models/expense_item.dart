import 'expense_category.dart';

/// Data model representing an expense transaction item.
class ExpenseItem {
  final int? id;
  final String merchantName;
  final double amount;
  final DateTime date;
  final ExpenseCategory category;
  final String receiptImagePath;
  final String? notes;
  final DateTime createdAt;

  const ExpenseItem({
    this.id,
    required this.merchantName,
    required this.amount,
    required this.date,
    required this.category,
    required this.receiptImagePath,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? date;

  /// Creates a copy with optionally modified fields.
  ExpenseItem copyWith({
    int? id,
    String? merchantName,
    double? amount,
    DateTime? date,
    ExpenseCategory? category,
    String? receiptImagePath,
    String? notes,
    DateTime? createdAt,
  }) {
    return ExpenseItem(
      id: id ?? this.id,
      merchantName: merchantName ?? this.merchantName,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Converts the ExpenseItem into a Map for SQLite storage.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'merchant_name': merchantName,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category.name,
      'receipt_image_path': receiptImagePath,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Creates an ExpenseItem from SQLite database row map.
  factory ExpenseItem.fromMap(Map<String, dynamic> map) {
    return ExpenseItem(
      id: map['id'] as int?,
      merchantName: (map['merchant_name'] as String?) ?? 'Unknown Merchant',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
      category: ExpenseCategory.fromString(map['category'] as String?),
      receiptImagePath: (map['receipt_image_path'] as String?) ?? '',
      notes: map['notes'] as String?,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'ExpenseItem(id: $id, merchant: $merchantName, amount: $amount, date: $date, category: ${category.name})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExpenseItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

