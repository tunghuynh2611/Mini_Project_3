import 'package:flutter/material.dart';
import '../../../app/constants/app_colors.dart';

/// Categories for expense classification.
enum ExpenseCategory {
  food,
  study,
  travel,
  gear,
  entertainment,
  other;

  String get displayName {
    switch (this) {
      case ExpenseCategory.food:
        return 'Food';
      case ExpenseCategory.study:
        return 'Study';
      case ExpenseCategory.travel:
        return 'Travel';
      case ExpenseCategory.gear:
        return 'Gear';
      case ExpenseCategory.entertainment:
        return 'Entertainment';
      case ExpenseCategory.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case ExpenseCategory.food:
        return Icons.restaurant_rounded;
      case ExpenseCategory.study:
        return Icons.school_rounded;
      case ExpenseCategory.travel:
        return Icons.directions_car_rounded;
      case ExpenseCategory.gear:
        return Icons.devices_rounded;
      case ExpenseCategory.entertainment:
        return Icons.sports_esports_rounded;
      case ExpenseCategory.other:
        return Icons.receipt_long_rounded;
    }
  }

  Color get color {
    switch (this) {
      case ExpenseCategory.food:
        return AppColors.catFood;
      case ExpenseCategory.study:
        return AppColors.catStudy;
      case ExpenseCategory.travel:
        return AppColors.catTravel;
      case ExpenseCategory.gear:
        return AppColors.catGear;
      case ExpenseCategory.entertainment:
        return AppColors.catEntertainment;
      case ExpenseCategory.other:
        return AppColors.catOther;
    }
  }

  static ExpenseCategory fromString(String? name) {
    if (name == null) return ExpenseCategory.other;
    return ExpenseCategory.values.firstWhere(
      (cat) => cat.name.toLowerCase() == name.trim().toLowerCase(),
      orElse: () => ExpenseCategory.other,
    );
  }
}

