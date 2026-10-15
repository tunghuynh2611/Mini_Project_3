import 'package:sqflite/sqflite.dart';
import '../../app/constants/app_constants.dart';
import '../../features/expense/models/expense_category.dart';
import '../../features/expense/models/expense_item.dart';
import 'app_database.dart';

/// Data Access Object for SQLite CRUD operations on ExpenseItem.
class ExpenseDao {
  final AppDatabase _dbManager;

  ExpenseDao({AppDatabase? dbManager}) : _dbManager = dbManager ?? AppDatabase.instance;

  Future<Database> get _db => _dbManager.database;

  /// Inserts a new ExpenseItem and returns generated id
  Future<int> insertExpense(ExpenseItem expense) async {
    final db = await _db;
    return await db.insert(
      AppConstants.expenseTableName,
      expense.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Updates an existing ExpenseItem
  Future<int> updateExpense(ExpenseItem expense) async {
    if (expense.id == null) return 0;
    final db = await _db;
    return await db.update(
      AppConstants.expenseTableName,
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  /// Deletes an ExpenseItem by ID
  Future<int> deleteExpense(int id) async {
    final db = await _db;
    return await db.delete(
      AppConstants.expenseTableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Retrieves all expenses ordered by date descending
  Future<List<ExpenseItem>> getAllExpenses() async {
    final db = await _db;
    final maps = await db.query(
      AppConstants.expenseTableName,
      orderBy: 'date DESC, id DESC',
    );
    return maps.map((m) => ExpenseItem.fromMap(m)).toList();
  }

  /// Retrieves expenses within a specific date range
  Future<List<ExpenseItem>> getExpensesByDateRange(DateTime start, DateTime end) async {
    final db = await _db;
    final maps = await db.query(
      AppConstants.expenseTableName,
      where: 'date >= ? AND date <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date DESC',
    );
    return maps.map((m) => ExpenseItem.fromMap(m)).toList();
  }

  /// Retrieves expenses by Category
  Future<List<ExpenseItem>> getExpensesByCategory(ExpenseCategory category) async {
    final db = await _db;
    final maps = await db.query(
      AppConstants.expenseTableName,
      where: 'category = ?',
      whereArgs: [category.name],
      orderBy: 'date DESC',
    );
    return maps.map((m) => ExpenseItem.fromMap(m)).toList();
  }

  /// Searches expenses by merchant name or notes
  Future<List<ExpenseItem>> searchExpenses(String query) async {
    final db = await _db;
    final sanitized = '%${query.trim()}%';
    final maps = await db.query(
      AppConstants.expenseTableName,
      where: 'merchant_name LIKE ? OR notes LIKE ?',
      whereArgs: [sanitized, sanitized],
      orderBy: 'date DESC',
    );
    return maps.map((m) => ExpenseItem.fromMap(m)).toList();
  }

  /// Aggregates total spending for each category
  Future<Map<ExpenseCategory, double>> getCategoryBreakdown() async {
    final db = await _db;
    final result = await db.rawQuery('''
      SELECT category, SUM(amount) as total
      FROM ${AppConstants.expenseTableName}
      GROUP BY category
    ''');

    final Map<ExpenseCategory, double> breakdown = {};
    for (final cat in ExpenseCategory.values) {
      breakdown[cat] = 0.0;
    }

    for (final row in result) {
      final catStr = row['category'] as String?;
      final total = (row['total'] as num?)?.toDouble() ?? 0.0;
      if (catStr != null) {
        final cat = ExpenseCategory.fromString(catStr);
        breakdown[cat] = total;
      }
    }

    return breakdown;
  }

  /// Calculates weekly spending grouped by day of the week (1: Mon ... 7: Sun)
  Future<Map<int, double>> getWeeklySpending(DateTime startOfWeek, DateTime endOfWeek) async {
    final expenses = await getExpensesByDateRange(startOfWeek, endOfWeek);

    final Map<int, double> dayTotals = {
      1: 0.0, // Mon
      2: 0.0, // Tue
      3: 0.0, // Wed
      4: 0.0, // Thu
      5: 0.0, // Fri
      6: 0.0, // Sat
      7: 0.0, // Sun
    };

    for (final e in expenses) {
      final weekday = e.date.weekday;
      dayTotals[weekday] = (dayTotals[weekday] ?? 0.0) + e.amount;
    }

    return dayTotals;
  }
}

