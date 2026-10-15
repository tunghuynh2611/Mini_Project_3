import 'package:flutter/material.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../expense/models/expense_category.dart';

/// Horizontal scrollable category filter chips row.
class CategoryFilterChips extends StatelessWidget {
  final ExpenseCategory? selectedCategory;
  final ValueChanged<ExpenseCategory?> onCategorySelected;

  const CategoryFilterChips({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // "All" filter chip
          FilterChip(
            label: const Text('All'),
            selected: selectedCategory == null,
            onSelected: (_) => onCategorySelected(null),
            avatar: Icon(
              Icons.all_inclusive_rounded,
              size: 16,
              color: selectedCategory == null
                  ? AppColors.primary
                  : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
            ),
          ),
          const SizedBox(width: 8),

          // Individual Category chips
          ...ExpenseCategory.values.map((cat) {
            final isSelected = selectedCategory == cat;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(cat.displayName),
                selected: isSelected,
                avatar: Icon(
                  cat.icon,
                  size: 16,
                  color: isSelected
                      ? cat.color
                      : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                ),
                selectedColor: cat.color.withValues(alpha: 0.18),
                side: BorderSide(
                  color: isSelected
                      ? cat.color
                      : (isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
                onSelected: (_) => onCategorySelected(cat),
              ),
            );
          }),
        ],
      ),
    );
  }
}

