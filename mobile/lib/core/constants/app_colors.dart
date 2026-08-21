import 'package:flutter/material.dart';

/// The Modern Khata Design System Color Palette for Smart-Hisab Mobile App.
/// Merges warm Saffron/Amber canteen heritage with Jade Cash trust and Obsidian night ergonomics.
abstract class AppColors {
  // Brand Colors - Spice Saffron & Warm Amber
  static const Color primary = Color(0xFFEA580C); // Saffron 600
  static const Color primaryDark = Color(0xFFC2410C); // Saffron 700
  static const Color primaryLight = Color(0xFFFFF7ED); // Saffron 50
  static const Color primaryContainerLight = Color(0xFFFFEDD5); // Saffron 100
  static const Color primaryContainerDark = Color(0xFF431407); // Saffron 950

  // Accent & Cash Inflow - Jade Mint
  static const Color accent = Color(0xFF059669); // Emerald / Jade 600
  static const Color accentDark = Color(0xFF047857); // Jade 700
  static const Color accentLight = Color(0xFFECFDF5); // Jade 50
  static const Color accentContainerLight = Color(0xFFD1FAE5); // Jade 100

  // Background & Surfaces (Dark Theme - Deep Obsidian & Chalkboard Slate)
  static const Color bgDark = Color(0xFF0A0E17); // Obsidian 950
  static const Color cardDark = Color(0xFF161F30); // Tactical Slate 900
  static const Color cardBorderDark = Color(0xFF243048); // Slate 800

  // Background & Surfaces (Light Theme - Sand Ivory & Crisp White)
  static const Color bgLight = Color(0xFFF8FAFC); // Clean Canvas
  static const Color cardLight = Color(0xFFFFFFFF); // Pure White Surface
  static const Color cardBorderLight = Color(0xFFE2E8F0); // Slate 200

  // Text Colors
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textPrimaryLight = Color(0xFF0F172A); // Slate 900 Charcoal
  static const Color textSecondaryLight = Color(0xFF64748B); // Slate 500

  // Status & Financial Ledger Indicators
  static const Color success = Color(0xFF10B981); // Cash paid / surplus / settled
  static const Color warning = Color(0xFFF59E0B); // Shift variance / pending sync
  static const Color danger = Color(0xFFE11D48); // Baki (debt) / deficits / voided
  static const Color dangerLight = Color(0xFFFFF1F2);
  static const Color info = Color(0xFF0284C7); // Shift timeline info / system notes
  static const Color payableOchre = Color(0xFFD97706); // Bazar raw goods / vendor dues

  // Skeleton Loader Palette
  static const Color shimmerBaseDark = Color(0xFF161F30);
  static const Color shimmerHighlightDark = Color(0xFF243048);
  static const Color shimmerBaseLight = Color(0xFFE2E8F0);
  static const Color shimmerHighlightLight = Color(0xFFF1F5F9);

  // Backward-compatibility aliases
  static const Color shimmerBase = shimmerBaseDark;
  static const Color shimmerHighlight = shimmerHighlightDark;
  static const Color backgroundDark = bgDark;
  static const Color surfaceDark = cardDark;
  static const Color surfaceLight = cardBorderDark;
  static const Color textSecondary = textSecondaryDark;
  static const Color textPrimary = textPrimaryDark;
}
