import 'package:flutter/material.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/camera/presentation/camera_screen.dart';
import '../../features/review/presentation/review_screen.dart';
import '../../features/analytics/presentation/analytics_screen.dart';
import '../../core/utils/regex_heuristics.dart';

/// Route definition and navigator transitions for ExpenseOCR.
class AppRoutes {
  AppRoutes._();

  static const String dashboard = '/';
  static const String camera = '/camera';
  static const String review = '/review';
  static const String analytics = '/analytics';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case dashboard:
        return MaterialPageRoute(
          builder: (_) => const DashboardScreen(),
          settings: settings,
        );
      case camera:
        return MaterialPageRoute(
          builder: (_) => const CameraScreen(),
          settings: settings,
        );
      case review:
        final args = settings.arguments;
        if (args is ReviewScreenArguments) {
          return MaterialPageRoute(
            builder: (_) => ReviewScreen(arguments: args),
            settings: settings,
          );
        }
        return MaterialPageRoute(
          builder: (_) => const DashboardScreen(),
          settings: settings,
        );
      case analytics:
        return MaterialPageRoute(
          builder: (_) => const AnalyticsScreen(),
          settings: settings,
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const DashboardScreen(),
          settings: settings,
        );
    }
  }
}

/// Arguments passed to ReviewScreen upon receipt scan/upload
class ReviewScreenArguments {
  final ExtractedReceiptData extractedData;
  final String imagePath;
  final bool isSample;

  const ReviewScreenArguments({
    required this.extractedData,
    required this.imagePath,
    this.isSample = false,
  });
}

