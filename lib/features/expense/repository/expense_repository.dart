import '../../../core/database/expense_dao.dart';
import '../../../core/services/receipt_storage_service.dart';
import '../../../core/utils/date_formatter.dart';
import '../models/expense_category.dart';
import '../models/expense_item.dart';

/// Repository abstracting persistence and analytics queries.
class ExpenseRepository {
  final ExpenseDao _dao;
  final ReceiptStorageService _storageService;

  ExpenseRepository({
    ExpenseDao? dao,
    ReceiptStorageService? storageService,
  })  : _dao = dao ?? ExpenseDao(),
        _storageService = storageService ?? ReceiptStorageService.instance;

  Future<List<ExpenseItem>> getAllExpenses() => _dao.getAllExpenses();

  Future<int> addExpense(ExpenseItem expense) async {
    return await _dao.insertExpense(expense);
  }

  Future<int> updateExpense(ExpenseItem expense) async {
    return await _dao.updateExpense(expense);
  }

  Future<int> deleteExpense(ExpenseItem expense) async {
    if (expense.id == null) return 0;
    // Delete local receipt image file if present
    if (expense.receiptImagePath.isNotEmpty) {
      await _storageService.deleteReceiptImage(expense.receiptImagePath);
    }
    return await _dao.deleteExpense(expense.id!);
  }

  Future<List<ExpenseItem>> searchExpenses(String query) {
    if (query.trim().isEmpty) return _dao.getAllExpenses();
    return _dao.searchExpenses(query);
  }

  Future<List<ExpenseItem>> getExpensesByCategory(ExpenseCategory category) {
    return _dao.getExpensesByCategory(category);
  }

  Future<Map<ExpenseCategory, double>> getCategoryBreakdown() {
    return _dao.getCategoryBreakdown();
  }

  Future<Map<int, double>> getWeeklySpending(DateTime date) {
    final start = DateFormatter.getStartOfWeek(date);
    final end = DateFormatter.getEndOfWeek(date);
    return _dao.getWeeklySpending(start, end);
  }
}

