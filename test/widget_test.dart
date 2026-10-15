import 'package:flutter_test/flutter_test.dart';
import 'package:expense_ocr/main.dart';
import 'package:expense_ocr/app/constants/app_constants.dart';

void main() {
  testWidgets('ExpenseOCR App loads dashboard smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ExpenseOcrApp());
    // Pump frames to allow async provider and initial animation to settle
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));

    expect(find.text(AppConstants.appName), findsOneWidget);
    expect(find.text('Scan Receipt'), findsOneWidget);
  });
}
