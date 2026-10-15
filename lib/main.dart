import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app/constants/app_constants.dart';
import 'app/routes/app_routes.dart';
import 'app/theme/app_theme.dart';
import 'core/database/app_database.dart';
import 'features/expense/providers/expense_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Pre-initialize SQLite local database
  try {
    await AppDatabase.instance.database;
  } catch (e) {
    debugPrint('Database initialization warning: $e');
  }

  runApp(const ExpenseOcrApp());
}

/// Root widget for ExpenseOCR application.
class ExpenseOcrApp extends StatelessWidget {
  const ExpenseOcrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ExpenseProvider(),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        initialRoute: AppRoutes.dashboard,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }
}
