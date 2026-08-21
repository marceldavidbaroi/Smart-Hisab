import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Represents distinct time bands of the day for dynamic ambient theming & animations.
enum TimePhase {
  dawn, // 05:00 - 07:59
  morning, // 08:00 - 11:29
  midday, // 11:30 - 15:29
  afternoon, // 15:30 - 19:29
  dinner, // 19:30 - 22:59
  night, // 23:00 - 04:59
}

/// Helper utility for resolving time phases, colors, gradients, and contextual copy.
abstract class TimePhaseHelper {
  /// Resolves the current [TimePhase] based on [dateTime] (defaults to DateTime.now()).
  static TimePhase getPhase([DateTime? dateTime]) {
    final now = dateTime ?? DateTime.now();
    final hour = now.hour;
    final minute = now.minute;
    final totalMinutes = hour * 60 + minute;

    // 05:00 to 07:59 -> Dawn (300 to 479 mins)
    if (totalMinutes >= 300 && totalMinutes < 480) {
      return TimePhase.dawn;
    }
    // 08:00 to 11:29 -> Morning (480 to 689 mins)
    if (totalMinutes >= 480 && totalMinutes < 690) {
      return TimePhase.morning;
    }
    // 11:30 to 15:29 -> Midday (690 to 929 mins)
    if (totalMinutes >= 690 && totalMinutes < 930) {
      return TimePhase.midday;
    }
    // 15:30 to 19:29 -> Afternoon (930 to 1169 mins)
    if (totalMinutes >= 930 && totalMinutes < 1170) {
      return TimePhase.afternoon;
    }
    // 19:30 to 22:59 -> Dinner (1170 to 1379 mins)
    if (totalMinutes >= 1170 && totalMinutes < 1380) {
      return TimePhase.dinner;
    }
    // 23:00 to 04:59 -> Night
    return TimePhase.night;
  }

  /// Whether the phase features solar elements (true) or lunar/starlight elements (false).
  static bool isDaytime(TimePhase phase) {
    switch (phase) {
      case TimePhase.dawn:
      case TimePhase.morning:
      case TimePhase.midday:
      case TimePhase.afternoon:
        return true;
      case TimePhase.dinner:
      case TimePhase.night:
        return false;
    }
  }

  /// Title greeting for the time phase.
  static String getGreeting(TimePhase phase) {
    switch (phase) {
      case TimePhase.dawn:
        return 'Early Morning 🌅';
      case TimePhase.morning:
        return 'Good Morning ☀️';
      case TimePhase.midday:
        return 'Peak Lunch Hours 🔥';
      case TimePhase.afternoon:
        return 'Good Afternoon 🌇';
      case TimePhase.dinner:
        return 'Dinner Peak 🌙';
      case TimePhase.night:
        return 'Night Ledger 🌌';
    }
  }

  /// Contextual guidance subtitle for opening the business day.
  static String getSubtitle(TimePhase phase) {
    switch (phase) {
      case TimePhase.dawn:
        return 'Set opening cash drawer amount & prep for morning breakfast shift.';
      case TimePhase.morning:
        return 'Breakfast rush is starting! Open day to record daily meals & sales.';
      case TimePhase.midday:
        return 'High midday meal activity. Open day to start fast customer checkout.';
      case TimePhase.afternoon:
        return 'Afternoon tea & snacks shift. Set opening cash to track live sales.';
      case TimePhase.dinner:
        return 'Dinner rush in progress! Record evening meals & settle transactions.';
      case TimePhase.night:
        return 'Review your daily recap or open shift to record late night orders.';
    }
  }

  /// Ambient background gradient for the dynamic card container.
  static List<Color> getCardGradient(TimePhase phase, bool isDark) {
    if (isDark) {
      switch (phase) {
        case TimePhase.dawn:
          return const [Color(0xFF2A1B28), Color(0xFF161F30)];
        case TimePhase.morning:
          return const [Color(0xFF2C1E14), Color(0xFF161F30)];
        case TimePhase.midday:
          return const [Color(0xFF33200D), Color(0xFF161F30)];
        case TimePhase.afternoon:
          return const [Color(0xFF2F181B), Color(0xFF161F30)];
        case TimePhase.dinner:
          return const [Color(0xFF181B34), Color(0xFF101424)];
        case TimePhase.night:
          return const [Color(0xFF0F1527), Color(0xFF0A0E17)];
      }
    } else {
      switch (phase) {
        case TimePhase.dawn:
          return const [Color(0xFFFFF3EB), Color(0xFFFFFFFF)];
        case TimePhase.morning:
          return const [Color(0xFFFFF8E7), Color(0xFFFFFFFF)];
        case TimePhase.midday:
          return const [Color(0xFFFFFAEE), Color(0xFFFFFFFF)];
        case TimePhase.afternoon:
          return const [Color(0xFFFFF4EC), Color(0xFFFFFFFF)];
        case TimePhase.dinner:
          return const [Color(0xFFF1F3FB), Color(0xFFFFFFFF)];
        case TimePhase.night:
          return const [Color(0xFFEEF2F9), Color(0xFFFFFFFF)];
      }
    }
  }

  /// Primary accent color for the celestial body and aura rings.
  static Color getPrimaryAccent(TimePhase phase) {
    switch (phase) {
      case TimePhase.dawn:
        return const Color(0xFFFB923C); // Warm Peach / Orange 400
      case TimePhase.morning:
        return const Color(0xFFF59E0B); // Amber 500
      case TimePhase.midday:
        return AppColors.primary; // Saffron 600
      case TimePhase.afternoon:
        return const Color(0xFFEA580C); // Terracotta
      case TimePhase.dinner:
        return const Color(0xFF818CF8); // Indigo 400
      case TimePhase.night:
        return const Color(0xFF38BDF8); // Sky Blue 400
    }
  }

  /// Secondary glow color for the celestial body.
  static Color getSecondaryAccent(TimePhase phase) {
    switch (phase) {
      case TimePhase.dawn:
        return const Color(0xFFF43F5E); // Rose 500
      case TimePhase.morning:
        return const Color(0xFFFBBF24); // Warm Gold
      case TimePhase.midday:
        return const Color(0xFFF97316); // Bright Orange
      case TimePhase.afternoon:
        return const Color(0xFFC026D3); // Purple / Sunset
      case TimePhase.dinner:
        return const Color(0xFF6366F1); // Indigo 500
      case TimePhase.night:
        return const Color(0xFF818CF8); // Soft Starlight Violet
    }
  }

  /// Badge tag text shown in the header or card corner.
  static String getBadgeLabel(TimePhase phase) {
    switch (phase) {
      case TimePhase.dawn:
        return 'Sunrise Dawn';
      case TimePhase.morning:
        return 'Morning Rush';
      case TimePhase.midday:
        return 'Midday Peak';
      case TimePhase.afternoon:
        return 'Golden Hour';
      case TimePhase.dinner:
        return 'Dinner Shift';
      case TimePhase.night:
        return 'Night Hours';
    }
  }
}
