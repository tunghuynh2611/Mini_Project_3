import 'package:flutter/material.dart';

/// Centralized color palette for ExpenseOCR.
/// Features a modern emerald / teal palette tailored for financial clarity.
class AppColors {
  AppColors._();

  // Primary brand colors
  static const Color primary = Color(0xFF0F766E); // Deep Teal
  static const Color primaryLight = Color(0xFF14B8A6); // Teal Accent
  static const Color primaryDark = Color(0xFF042F2E);
  static const Color secondary = Color(0xFF0284C7); // Sky Blue
  static const Color accent = Color(0xFF10B981); // Emerald Green

  // Surface & Background (Light)
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textMutedLight = Color(0xFF94A3B8);

  // Surface & Background (Dark)
  static const Color backgroundDark = Color(0xFF090D16);
  static const Color surfaceDark = Color(0xFF111827);
  static const Color cardDark = Color(0xFF1E293B);
  static const Color borderDark = Color(0xFF334155);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textMutedDark = Color(0xFF64748B);

  // Status & Semantic Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Category Colors
  static const Color catFood = Color(0xFFF97316); // Orange
  static const Color catStudy = Color(0xFF3B82F6); // Blue
  static const Color catTravel = Color(0xFF06B6D4); // Cyan
  static const Color catGear = Color(0xFF8B5CF6); // Purple
  static const Color catEntertainment = Color(0xFFEC4899); // Pink
  static const Color catOther = Color(0xFF6B7280); // Gray

  // Chart Gradient Accents
  static const List<Color> primaryGradient = [
    Color(0xFF0F766E),
    Color(0xFF14B8A6),
  ];

  static const List<Color> emeraldGradient = [
    Color(0xFF059669),
    Color(0xFF34D399),
  ];
}

