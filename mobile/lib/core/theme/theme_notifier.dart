import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/hive_service.dart';

final themeNotifierProvider =
    StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.dark) {
    _loadSavedTheme();
  }

  void _loadSavedTheme() {
    final savedTheme = HiveService.cacheBox.get('theme_mode') as String?;
    if (savedTheme == 'light') {
      state = ThemeMode.light;
    } else if (savedTheme == 'dark') {
      state = ThemeMode.dark;
    } else if (savedTheme == 'system') {
      state = ThemeMode.system;
    }
  }

  Future<void> toggleTheme() async {
    if (state == ThemeMode.dark) {
      state = ThemeMode.light;
      await HiveService.cacheBox.put('theme_mode', 'light');
    } else {
      state = ThemeMode.dark;
      await HiveService.cacheBox.put('theme_mode', 'dark');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await HiveService.cacheBox.put('theme_mode', mode.name);
  }
}
