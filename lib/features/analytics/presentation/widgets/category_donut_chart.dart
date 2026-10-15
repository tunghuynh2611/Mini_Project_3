import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../expense/models/expense_category.dart';

/// Interactive Animated Donut / Pie Chart rendered using pure CustomPainter.
class CategoryDonutChart extends StatefulWidget {
  final Map<ExpenseCategory, double> categoryTotals;
  final double totalSpending;

  const CategoryDonutChart({
    super.key,
    required this.categoryTotals,
    required this.totalSpending,
  });

  @override
  State<CategoryDonutChart> createState() => _CategoryDonutChartState();
}

class _CategoryDonutChartState extends State<CategoryDonutChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  ExpenseCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant CategoryDonutChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.totalSpending != widget.totalSpending) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Filter active categories with spending > 0
    final activeEntries = widget.categoryTotals.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final total = widget.totalSpending;

    return Column(
      children: [
        // Donut Chart Canvas Area
        SizedBox(
          height: 240,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.biggest;
              final chartSize = math.min(size.width, size.height) - 16;
              final center = Offset(size.width / 2, size.height / 2);
              final outerRadius = chartSize / 2;

              return GestureDetector(
                onTapUp: (details) {
                  _handleTap(details.localPosition, center, outerRadius, activeEntries, total);
                },
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return CustomPaint(
                      size: size,
                      painter: _DonutChartPainter(
                        entries: activeEntries,
                        total: total,
                        progress: _animation.value,
                        selectedCategory: _selectedCategory,
                        isDark: isDark,
                      ),
                      child: Center(
                        child: _buildCenterBadge(isDark),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        // Interactive Legend Items
        if (activeEntries.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: activeEntries.map((entry) {
              final isSelected = _selectedCategory == entry.key;
              final percentage = total > 0 ? (entry.value / total * 100) : 0.0;

              return InkWell(
                onTap: () {
                  setState(() {
                    if (_selectedCategory == entry.key) {
                      _selectedCategory = null;
                    } else {
                      _selectedCategory = entry.key;
                    }
                  });
                },
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? entry.key.color.withValues(alpha: 0.18)
                        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? entry.key.color : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: entry.key.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        entry.key.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? entry.key.color
                              : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          )
        else
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'No expense data to display.',
              style: TextStyle(
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCenterBadge(bool isDark) {
    if (widget.totalSpending == 0) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.pie_chart_outline_rounded,
            size: 32,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
          const SizedBox(height: 4),
          Text(
            'No Data',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
          ),
        ],
      );
    }

    if (_selectedCategory != null) {
      final selectedAmount = widget.categoryTotals[_selectedCategory] ?? 0.0;
      final pct = widget.totalSpending > 0
          ? (selectedAmount / widget.totalSpending * 100)
          : 0.0;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _selectedCategory!.icon,
            size: 24,
            color: _selectedCategory!.color,
          ),
          const SizedBox(height: 2),
          Text(
            _selectedCategory!.displayName,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _selectedCategory!.color,
            ),
          ),
          Text(
            CurrencyFormatter.formatCompact(selectedAmount),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          Text(
            '${pct.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Total Spent',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          CurrencyFormatter.formatCompact(widget.totalSpending),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        Text(
          'Tap slice for info',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
        ),
      ],
    );
  }

  void _handleTap(
    Offset tapPos,
    Offset center,
    double outerRadius,
    List<MapEntry<ExpenseCategory, double>> entries,
    double total,
  ) {
    if (total <= 0 || entries.isEmpty) return;

    final dx = tapPos.dx - center.dx;
    final dy = tapPos.dy - center.dy;
    final distance = math.sqrt(dx * dx + dy * dy);

    final innerRadius = outerRadius * 0.62;
    // Check if tap falls within donut ring
    if (distance < innerRadius * 0.8 || distance > outerRadius * 1.15) {
      setState(() => _selectedCategory = null);
      return;
    }

    // Calculate angle in radians starting from -pi/2 (top)
    double angle = math.atan2(dy, dx);
    angle += math.pi / 2;
    if (angle < 0) {
      angle += 2 * math.pi;
    }

    double currentSweep = 0.0;
    for (final entry in entries) {
      final sliceSweep = (entry.value / total) * 2 * math.pi;
      if (angle >= currentSweep && angle <= currentSweep + sliceSweep) {
        setState(() {
          if (_selectedCategory == entry.key) {
            _selectedCategory = null;
          } else {
            _selectedCategory = entry.key;
          }
        });
        return;
      }
      currentSweep += sliceSweep;
    }
  }
}

/// CustomPainter for Donut slices with animated sweep and interactive highlighting
class _DonutChartPainter extends CustomPainter {
  final List<MapEntry<ExpenseCategory, double>> entries;
  final double total;
  final double progress;
  final ExpenseCategory? selectedCategory;
  final bool isDark;

  _DonutChartPainter({
    required this.entries,
    required this.total,
    required this.progress,
    required this.selectedCategory,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final chartRadius = (math.min(size.width, size.height) - 24) / 2;
    const strokeWidth = 28.0;

    // 1. Draw subtle background track ring
    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    canvas.drawCircle(center, chartRadius, bgPaint);

    if (total <= 0 || entries.isEmpty) return;

    // 2. Draw animated category slices
    double startAngle = -math.pi / 2; // Start at 12 o'clock

    for (final entry in entries) {
      final isSelected = selectedCategory == entry.key;
      final sweepAngle = (entry.value / total) * (2 * math.pi) * progress;

      final sliceRadius = isSelected ? chartRadius + 4 : chartRadius;
      final currentStroke = isSelected ? strokeWidth + 6 : strokeWidth;

      final slicePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = currentStroke
        ..strokeCap = StrokeCap.butt
        ..color = isSelected ? entry.key.color : entry.key.color.withValues(alpha: 0.92);

      final rect = Rect.fromCircle(center: center, radius: sliceRadius);

      // Add slight gap between slices if multiple categories
      const gap = 0.03;
      final effectiveSweep = sweepAngle > gap * 2 ? sweepAngle - gap : sweepAngle;
      final effectiveStart = startAngle + (gap / 2);

      canvas.drawArc(
        rect,
        effectiveStart,
        effectiveSweep,
        false,
        slicePaint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.selectedCategory != selectedCategory ||
        oldDelegate.total != total ||
        oldDelegate.entries != entries ||
        oldDelegate.isDark != isDark;
  }
}

