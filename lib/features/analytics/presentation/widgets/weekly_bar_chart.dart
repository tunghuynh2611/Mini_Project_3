import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';

/// Pure CustomPainter Weekly Spending Bar Chart with animated rise and interactive touch tooltips.
class WeeklyBarChart extends StatefulWidget {
  final Map<int, double> weeklyTotals;
  final VoidCallback? onPreviousWeek;
  final VoidCallback? onNextWeek;
  final VoidCallback? onCurrentWeek;
  final DateTime weekAnchor;

  const WeeklyBarChart({
    super.key,
    required this.weeklyTotals,
    required this.weekAnchor,
    this.onPreviousWeek,
    this.onNextWeek,
    this.onCurrentWeek,
  });

  @override
  State<WeeklyBarChart> createState() => _WeeklyBarChartState();
}

class _WeeklyBarChartState extends State<WeeklyBarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int? _selectedDayIndex; // 1 (Mon) to 7 (Sun)

  static const List<String> _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant WeeklyBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weeklyTotals != widget.weeklyTotals) {
      _controller.reset();
      _controller.forward();
      _selectedDayIndex = null;
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

    final totalWeek = widget.weeklyTotals.values.fold(0.0, (s, a) => s + a);
    final maxAmount = widget.weeklyTotals.values.isEmpty
        ? 100000.0
        : widget.weeklyTotals.values.reduce(math.max);
    final effectiveMax = maxAmount > 0 ? maxAmount * 1.2 : 100000.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Week Summary Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weekly Spending',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  CurrencyFormatter.format(totalWeek),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
              ],
            ),
            // Week navigation controls
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  tooltip: 'Previous week',
                  onPressed: widget.onPreviousWeek,
                  visualDensity: VisualDensity.compact,
                ),
                TextButton(
                  onPressed: widget.onCurrentWeek,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text('This Week', style: TextStyle(fontSize: 12)),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  tooltip: 'Next week',
                  onPressed: widget.onNextWeek,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Custom Painted Bar Chart Area
        SizedBox(
          height: 220,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onTapDown: (details) {
                  _detectBarTouch(details.localPosition, constraints.maxWidth, constraints.maxHeight);
                },
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return CustomPaint(
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                      painter: _WeeklyBarChartPainter(
                        weeklyTotals: widget.weeklyTotals,
                        dayLabels: _dayLabels,
                        maxAmount: effectiveMax,
                        progress: _animation.value,
                        selectedDay: _selectedDayIndex,
                        isDark: isDark,
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        // Quick tip or selected day detail
        Center(
          child: Text(
            _selectedDayIndex != null
                ? '${_dayLabels[_selectedDayIndex! - 1]}: ${CurrencyFormatter.format(widget.weeklyTotals[_selectedDayIndex] ?? 0.0)}'
                : 'Tap any bar to inspect daily breakdown',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _selectedDayIndex != null
                  ? AppColors.primaryLight
                  : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
            ),
          ),
        ),
      ],
    );
  }

  void _detectBarTouch(Offset localPos, double width, double height) {
    const leftMargin = 40.0;
    const rightMargin = 12.0;
    final chartWidth = width - leftMargin - rightMargin;
    final step = chartWidth / 7;

    final x = localPos.dx - leftMargin;
    if (x >= 0 && x <= chartWidth) {
      final tappedIndex = (x / step).floor() + 1;
      if (tappedIndex >= 1 && tappedIndex <= 7) {
        setState(() {
          if (_selectedDayIndex == tappedIndex) {
            _selectedDayIndex = null;
          } else {
            _selectedDayIndex = tappedIndex;
          }
        });
      }
    } else {
      setState(() => _selectedDayIndex = null);
    }
  }
}

/// CustomPainter rendering the weekly bars, dotted grid lines, and interactive tooltip
class _WeeklyBarChartPainter extends CustomPainter {
  final Map<int, double> weeklyTotals;
  final List<String> dayLabels;
  final double maxAmount;
  final double progress;
  final int? selectedDay;
  final bool isDark;

  _WeeklyBarChartPainter({
    required this.weeklyTotals,
    required this.dayLabels,
    required this.maxAmount,
    required this.progress,
    required this.selectedDay,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftMargin = 44.0;
    const bottomMargin = 28.0;
    const topMargin = 30.0; // Space for floating tooltip
    final chartWidth = size.width - leftMargin - 12.0;
    final chartHeight = size.height - bottomMargin - topMargin;

    // 1. Draw horizontal grid lines and Y-axis labels
    const gridDivisions = 3;
    final gridPaint = Paint()
      ..color = isDark ? const Color(0xFF243046) : const Color(0xFFE2E8F0)
      ..strokeWidth = 1.0;

    for (int i = 0; i <= gridDivisions; i++) {
      final y = topMargin + chartHeight - (chartHeight / gridDivisions * i);
      final value = (maxAmount / gridDivisions) * i;

      // Draw horizontal line
      canvas.drawLine(
        Offset(leftMargin, y),
        Offset(leftMargin + chartWidth, y),
        gridPaint,
      );

      // Y-axis label text
      final textSpan = TextSpan(
        text: CurrencyFormatter.formatCompact(value),
        style: TextStyle(
          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(leftMargin - textPainter.width - 6, y - (textPainter.height / 2)),
      );
    }

    // 2. Draw vertical bars
    final barStep = chartWidth / 7;
    final barWidth = barStep * 0.55;

    Offset? selectedBarTop;
    double? selectedAmount;
    String? selectedDayName;

    for (int i = 1; i <= 7; i++) {
      final amount = weeklyTotals[i] ?? 0.0;
      final normalizedHeight = (amount / maxAmount) * chartHeight * progress;
      final xCenter = leftMargin + (barStep * (i - 1)) + (barStep / 2);
      final xLeft = xCenter - (barWidth / 2);
      final yTop = topMargin + chartHeight - normalizedHeight;
      final isSelected = selectedDay == i;

      final barRect = Rect.fromLTWH(xLeft, yTop, barWidth, normalizedHeight);
      final rrect = RRect.fromRectAndCorners(
        barRect,
        topLeft: const Radius.circular(6),
        topRight: const Radius.circular(6),
      );

      // Paint bar with gradient
      final barPaint = Paint();
      if (isSelected) {
        barPaint.shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primaryLight,
            AppColors.accent,
          ],
        ).createShader(barRect);
      } else {
        barPaint.shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  AppColors.primary.withValues(alpha: 0.8),
                  AppColors.primaryDark.withValues(alpha: 0.9),
                ]
              : [
                  AppColors.primaryLight,
                  AppColors.primary,
                ],
        ).createShader(barRect);
      }

      // Draw bar if amount > 0 or subtle placeholder baseline
      if (normalizedHeight > 2) {
        canvas.drawRRect(rrect, barPaint);

        // Highlight stroke on selected bar
        if (isSelected) {
          final strokePaint = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = Colors.white.withValues(alpha: 0.8);
          canvas.drawRRect(rrect, strokePaint);
        }
      } else {
        // Draw subtle 2px marker for 0 spending
        final zeroRect = Rect.fromLTWH(xLeft, topMargin + chartHeight - 3, barWidth, 3);
        final zeroPaint = Paint()
          ..color = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            zeroRect,
            topLeft: const Radius.circular(2),
            topRight: const Radius.circular(2),
          ),
          zeroPaint,
        );
      }

      // 3. Draw day labels (Mon, Tue, etc.)
      final dayLabelSpan = TextSpan(
        text: dayLabels[i - 1],
        style: TextStyle(
          color: isSelected
              ? (isDark ? AppColors.primaryLight : AppColors.primary)
              : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
      );
      final dayPainter = TextPainter(
        text: dayLabelSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      dayPainter.paint(
        canvas,
        Offset(xCenter - (dayPainter.width / 2), size.height - bottomMargin + 6),
      );

      if (isSelected) {
        selectedBarTop = Offset(xCenter, yTop);
        selectedAmount = amount;
        selectedDayName = dayLabels[i - 1];
      }
    }

    // 4. Render floating tooltip above selected bar
    if (selectedBarTop != null && selectedAmount != null) {
      _drawTooltip(
        canvas,
        selectedBarTop,
        '$selectedDayName: ${CurrencyFormatter.format(selectedAmount)}',
        size.width,
      );
    }
  }

  void _drawTooltip(Canvas canvas, Offset barTop, String text, double totalWidth) {
    final textSpan = TextSpan(
      text: text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    const paddingH = 8.0;
    const paddingV = 4.0;
    final bubbleWidth = textPainter.width + (paddingH * 2);
    final bubbleHeight = textPainter.height + (paddingV * 2);

    // Keep bubble within canvas horizontal bounds
    double bubbleX = barTop.dx - (bubbleWidth / 2);
    bubbleX = bubbleX.clamp(8.0, totalWidth - bubbleWidth - 8.0);
    final bubbleY = math.max(4.0, barTop.dy - bubbleHeight - 8.0);

    final bubbleRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(bubbleX, bubbleY, bubbleWidth, bubbleHeight),
      const Radius.circular(6),
    );

    // Shadow
    canvas.drawRRect(
      bubbleRect.shift(const Offset(0, 2)),
      Paint()..color = Colors.black.withValues(alpha: 0.25),
    );

    // Bubble Background
    canvas.drawRRect(
      bubbleRect,
      Paint()..color = const Color(0xFF0F172A),
    );

    // Text inside bubble
    textPainter.paint(canvas, Offset(bubbleX + paddingH, bubbleY + paddingV));
  }

  @override
  bool shouldRepaint(covariant _WeeklyBarChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.selectedDay != selectedDay ||
        oldDelegate.weeklyTotals != weeklyTotals ||
        oldDelegate.maxAmount != maxAmount ||
        oldDelegate.isDark != isDark;
  }
}

