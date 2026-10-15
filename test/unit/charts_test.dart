import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_ocr/features/analytics/presentation/widgets/category_donut_chart.dart';
import 'package:expense_ocr/features/analytics/presentation/widgets/weekly_bar_chart.dart';
import 'package:expense_ocr/features/expense/models/expense_category.dart';

void main() {
  group('CustomPainter Charts Widget Tests', () {
    testWidgets('CategoryDonutChart renders correctly with data', (WidgetTester tester) async {
      final categoryTotals = {
        ExpenseCategory.food: 350000.0,
        ExpenseCategory.study: 150000.0,
        ExpenseCategory.travel: 80000.0,
        ExpenseCategory.gear: 200000.0,
        ExpenseCategory.entertainment: 120000.0,
        ExpenseCategory.other: 0.0,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryDonutChart(
              categoryTotals: categoryTotals,
              totalSpending: 900000.0,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));

      expect(find.byType(CategoryDonutChart), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.text('Total Spent'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Study'), findsOneWidget);
    });

    testWidgets('WeeklyBarChart renders days and week navigation', (WidgetTester tester) async {
      final weeklyTotals = {
        1: 50000.0,
        2: 120000.0,
        3: 0.0,
        4: 250000.0,
        5: 80000.0,
        6: 300000.0,
        7: 150000.0,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeeklyBarChart(
              weeklyTotals: weeklyTotals,
              weekAnchor: DateTime(2026, 10, 15),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));

      expect(find.byType(WeeklyBarChart), findsOneWidget);
      expect(find.text('Weekly Spending'), findsOneWidget);
      expect(find.text('This Week'), findsOneWidget);
    });
  });
}

