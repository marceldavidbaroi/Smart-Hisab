import 'package:flutter/material.dart';

/// Senior UI/UX App color palette for Smart-Hisab Mobile App.
/// Tailored for high legibility, professional financial trust, and canteen POS ergonomics.
abstract class AppColors {
  // Brand Colors - Emerald Teal & Sky Accent
  static const Color primary = Color(0xFF059669); // Emerald 600
  static const Color primaryDark = Color(0xFF047857); // Emerald 700
  static const Color primaryLight = Color(0xFFECFDF5); // Emerald 50
  static const Color primaryContainerLight = Color(0xFFD1FAE5); // Emerald 100
  static const Color accent = Color(0xFF0284C7); // Sky 600
  static const Color accentLight = Color(0xFFE0F2FE); // Sky 100

  // Background & Surfaces (Dark Theme)
  static const Color bgDark = Color(0xFF0F172A); // Slate 900
  static const Color cardDark = Color(0xFF1E293B); // Slate 800
  static const Color cardBorderDark = Color(0xFF334155); // Slate 700

  // Background & Surfaces (Light Theme - White Default)
  static const Color bgLight = Color(0xFFF8FAFC); // Slate 50 clean surface
  static const Color cardLight = Color(0xFFFFFFFF); // Pure White
  static const Color cardBorderLight = Color(0xFFE2E8F0); // Slate 200

  // Text Colors
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textPrimaryLight = Color(0xFF0F172A); // Slate 900 rich charcoal
  static const Color textSecondaryLight = Color(0xFF64748B); // Slate 500

  // Status & Financial Ledger Indicators
  static const Color success = Color(0xFF10B981); // Positive balances / paid / cash surplus
  static const Color warning = Color(0xFFF59E0B); // Pending sync / shift warnings
  static const Color danger = Color(0xFFEF4444); // Baki / due balances / deficits
  static const Color info = Color(0xFF3B82F6); // Shift info / ledger notes

  // Skeleton Loader Palette
  static const Color shimmerBaseDark = Color(0xFF1E293B);
  static const Color shimmerHighlightDark = Color(0xFF334155);
  static const Color shimmerBaseLight = Color(0xFFE2E8F0);
  static const Color shimmerHighlightLight = Color(0xFFF1F5F9);

  // Deprecated / Backwards-compatibility aliases
  static const Color shimmerBase = shimmerBaseDark;
  static const Color shimmerHighlight = shimmerHighlightDark;
  static const Color backgroundDark = bgDark;
  static const Color surfaceDark = cardDark;
  static const Color surfaceLight = cardBorderDark;
  static const Color textSecondary = textSecondaryDark;
  static const Color textPrimary = textPrimaryDark;
}

