import 'package:flutter/foundation.dart';
import '../models/expense_category.dart';
import '../models/expense_item.dart';
import '../repository/expense_repository.dart';

/// Central state manager for expense management and dashboard queries.
class ExpenseProvider extends ChangeNotifier {
  final ExpenseRepository _repository;

  ExpenseProvider({ExpenseRepository? repository})
      : _repository = repository ?? ExpenseRepository() {
    loadExpenses();
  }

  List<ExpenseItem> _allExpenses = [];
  List<ExpenseItem> _filteredExpenses = [];
  Map<ExpenseCategory, double> _categoryTotals = {};
  Map<int, double> _weeklyTotals = {};

  bool _isLoading = false;
  String? _errorMessage;
  ExpenseCategory? _selectedCategory;
  String _searchQuery = '';
  DateTime _currentWeekAnchor = DateTime.now();

  // Getters
  List<ExpenseItem> get expenses => _filteredExpenses;
  List<ExpenseItem> get allExpenses => _allExpenses;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ExpenseCategory? get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  Map<ExpenseCategory, double> get categoryTotals => _categoryTotals;
  Map<int, double> get weeklyTotals => _weeklyTotals;
  DateTime get currentWeekAnchor => _currentWeekAnchor;

  double get totalSpending =>
      _allExpenses.fold(0.0, (sum, item) => sum + item.amount);

  double get currentMonthSpending {
    final now = DateTime.now();
    return _allExpenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  /// Initial load or refresh of expense data from SQLite
  Future<void> loadExpenses() async {
    _setLoading(true);
    try {
      _allExpenses = await _repository.getAllExpenses();

      // Seed starter transactions if completely empty on fresh install
      if (_allExpenses.isEmpty) {
        await _seedInitialTransactions();
        _allExpenses = await _repository.getAllExpenses();
      }

      await _refreshAnalytics();
      _applyFilters();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load expenses: $e';
      debugPrint(_errorMessage);
    } finally {
      _setLoading(false);
    }
  }

  /// Adds a newly scanned or manually created expense
  Future<bool> addExpense(ExpenseItem item) async {
    _setLoading(true);
    try {
      await _repository.addExpense(item);
      _allExpenses = await _repository.getAllExpenses();
      await _refreshAnalytics();
      _applyFilters();
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to save expense: $e';
      debugPrint(_errorMessage);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Updates an existing expense
  Future<bool> updateExpense(ExpenseItem item) async {
    _setLoading(true);
    try {
      await _repository.updateExpense(item);
      _allExpenses = await _repository.getAllExpenses();
      await _refreshAnalytics();
      _applyFilters();
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update expense: $e';
      debugPrint(_errorMessage);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Deletes an expense item
  Future<bool> deleteExpense(ExpenseItem item) async {
    _setLoading(true);
    try {
      await _repository.deleteExpense(item);
      _allExpenses = await _repository.getAllExpenses();
      await _refreshAnalytics();
      _applyFilters();
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete expense: $e';
      debugPrint(_errorMessage);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Filter expenses by category
  void filterByCategory(ExpenseCategory? category) {
    if (_selectedCategory == category) {
      _selectedCategory = null; // Toggle off
    } else {
      _selectedCategory = category;
    }
    _applyFilters();
  }

  /// Search expenses by merchant name or keyword
  void search(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  /// Shift weekly analytics anchor
  void changeWeek(int weekDelta) {
    _currentWeekAnchor = _currentWeekAnchor.add(Duration(days: 7 * weekDelta));
    _refreshAnalytics();
  }

  void resetToCurrentWeek() {
    _currentWeekAnchor = DateTime.now();
    _refreshAnalytics();
  }

  void _applyFilters() {
    List<ExpenseItem> results = List.from(_allExpenses);

    if (_selectedCategory != null) {
      results = results.where((e) => e.category == _selectedCategory).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final queryLower = _searchQuery.trim().toLowerCase();
      results = results.where((e) {
        final matchMerchant = e.merchantName.toLowerCase().contains(queryLower);
        final matchNotes = (e.notes ?? '').toLowerCase().contains(queryLower);
        return matchMerchant || matchNotes;
      }).toList();
    }

    _filteredExpenses = results;
    notifyListeners();
  }

  Future<void> _refreshAnalytics() async {
    _categoryTotals = await _repository.getCategoryBreakdown();
    _weeklyTotals = await _repository.getWeeklySpending(_currentWeekAnchor);
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Seeds realistic initial data so the charts and list look rich immediately
  Future<void> _seedInitialTransactions() async {
    final now = DateTime.now();
    final seeds = [
      ExpenseItem(
        merchantName: 'Siêu thị WinMart+',
        amount: 194400,
        date: now.subtract(const Duration(hours: 3)),
        category: ExpenseCategory.food,
        receiptImagePath: '',
        notes: 'Groceries: milk, bread, eggs',
      ),
      ExpenseItem(
        merchantName: 'Highlands Coffee',
        amount: 120000,
        date: now.subtract(const Duration(days: 1)),
        category: ExpenseCategory.food,
        receiptImagePath: '',
        notes: 'Study session coffee',
      ),
      ExpenseItem(
        merchantName: 'Nhà sách Fahasa',
        amount: 233000,
        date: now.subtract(const Duration(days: 2)),
        category: ExpenseCategory.study,
        receiptImagePath: '',
        notes: 'Dart & Flutter programming book',
      ),
      ExpenseItem(
        merchantName: 'GrabCar Campus',
        amount: 70000,
        date: now.subtract(const Duration(days: 3)),
        category: ExpenseCategory.travel,
        receiptImagePath: '',
        notes: 'Commute to campus',
      ),
      ExpenseItem(
        merchantName: 'CGV Cinema',
        amount: 210000,
        date: now.subtract(const Duration(days: 4)),
        category: ExpenseCategory.entertainment,
        receiptImagePath: '',
        notes: 'Movie ticket with friends',
      ),
      ExpenseItem(
        merchantName: 'Anker Official Store',
        amount: 350000,
        date: now.subtract(const Duration(days: 5)),
        category: ExpenseCategory.gear,
        receiptImagePath: '',
        notes: '65W Fast Charger cable & adapter',
      ),
    ];

    for (final item in seeds) {
      await _repository.addExpense(item);
    }
  }
}
