/// Application-wide constants.
class AppConstants {
  AppConstants._();

  static const String appName = 'ExpenseOCR';
  static const String appTagline = 'Smart On-Device Receipt Scanner';

  // Currency & Locale
  static const String defaultCurrencySymbol = '₫';
  static const String defaultCurrencyCode = 'VND';
  static const String defaultLocale = 'vi_VN';

  // OCR confidence / heuristics thresholds
  static const int minMerchantLength = 2;
  static const int maxMerchantLength = 60;
  static const double minExpenseAmount = 100.0;
  static const double maxExpenseAmount = 1000000000.0; // 1 Billion VND max safety

  // DB Constants
  static const String dbName = 'expense_ocr.db';
  static const int dbVersion = 1;
  static const String expenseTableName = 'expenses';
}

