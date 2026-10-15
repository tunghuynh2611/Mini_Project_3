import 'package:intl/intl.dart';
import '../../app/constants/app_constants.dart';

/// Formatter and parser for multi-currency values with special emphasis on VND.
class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _numberFormat = NumberFormat('#,###', 'vi_VN');

  /// Formats amount into VND currency string (e.g. "150.000 ₫")
  static String format(double amount, {String? symbol}) {
    final sym = symbol ?? AppConstants.defaultCurrencySymbol;
    return '${_numberFormat.format(amount)} $sym';
  }

  /// Compact format for chart axis or small badges (e.g. "150K", "2.5M")
  static String formatCompact(double amount) {
    if (amount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1)}B ₫';
    } else if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M ₫';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K ₫';
    } else {
      return '${amount.toInt()} ₫';
    }
  }

  /// Cleans arbitrary string containing price/amount and extracts numeric double
  /// Handles "150.000", "150,000", "150.000đ", "$45.50", "45,50 €", etc.
  static double? parseAmount(String raw) {
    if (raw.trim().isEmpty) return null;

    // Strip currency symbols and text keywords
    String cleaned = raw
        .replaceAll(RegExp(r'[^\d.,]'), '')
        .trim();

    if (cleaned.isEmpty) return null;

    // Handle both dot and comma decimal/thousand separators
    // Vietnamese & European: 150.000 or 150.000,50
    // US / UK: 150,000 or 150,000.50
    final lastDot = cleaned.lastIndexOf('.');
    final lastComma = cleaned.lastIndexOf(',');

    if (lastDot != -1 && lastComma != -1) {
      if (lastDot > lastComma) {
        // e.g. 150,000.50 -> remove commas, dot is decimal
        cleaned = cleaned.replaceAll(',', '');
      } else {
        // e.g. 150.000,50 -> remove dots, comma becomes dot decimal
        cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
      }
    } else if (lastDot != -1) {
      // Check if dot is thousands separator (e.g. 150.000 or 1.500.000)
      final parts = cleaned.split('.');
      if (parts.length > 2) {
        // Definitely thousands separator: 1.500.000
        cleaned = cleaned.replaceAll('.', '');
      } else if (parts.length == 2) {
        // If 3 digits after dot (e.g. 150.000), in VND it's thousands!
        if (parts[1].length == 3) {
          cleaned = cleaned.replaceAll('.', '');
        }
      }
    } else if (lastComma != -1) {
      // Check if comma is thousands separator (e.g. 150,000 or 1,500,000)
      final parts = cleaned.split(',');
      if (parts.length > 2) {
        cleaned = cleaned.replaceAll(',', '');
      } else if (parts.length == 2) {
        if (parts[1].length == 3) {
          cleaned = cleaned.replaceAll(',', '');
        } else {
          // e.g. 45,50 -> decimal comma
          cleaned = cleaned.replaceAll(',', '.');
        }
      }
    }

    return double.tryParse(cleaned);
  }
}
