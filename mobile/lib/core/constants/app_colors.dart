import 'package:flutter/material.dart';

/// App color palette for Smart-Hisab Android App.
/// Tailored for fast readability in canteen/POS environments.
abstract class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF059669); // Emerald 600
  static const Color primaryDark = Color(0xFF047857); // Emerald 700
  static const Color primaryLight = Color(0xFFD1FAE5); // Emerald 100
  static const Color accent = Color(0xFF0284C7); // Sky 600

  // Background & Surfaces (Dark Theme Default)
  static const Color bgDark = Color(0xFF0F172A); // Slate 900
  static const Color cardDark = Color(0xFF1E293B); // Slate 800
  static const Color cardBorderDark = Color(0xFF334155); // Slate 700

  // Light Theme Surfaces
  static const Color bgLight = Color(0xFFF8FAFC); // Slate 50
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardBorderLight = Color(0xFFE2E8F0); // Slate 200

  // Text Colors
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);

  // Status & Financial Indicators
  static const Color success = Color(0xFF10B981); // Positive balances / paid
  static const Color warning = Color(0xFFF59E0B); // Pending outbox sync / warnings
  static const Color danger = Color(0xFFEF4444); // Baki / negative balances
  static const Color info = Color(0xFF3B82F6); // Shift info / notes

  // Skeleton Loader
  static const Color shimmerBase = Color(0xFF334155);
  static const Color shimmerHighlight = Color(0xFF475569);
}
