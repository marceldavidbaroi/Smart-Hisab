import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/hive_service.dart';

final localeNotifierProvider =
    StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  static const String _storageKey = 'app_locale';

  LocaleNotifier() : super(const Locale('en')) {
    _loadSavedLocale();
  }

  void _loadSavedLocale() {
    try {
      final savedCode = HiveService.cacheBox.get(_storageKey) as String?;
      if (savedCode == 'bn') {
        state = const Locale('bn');
      } else {
        state = const Locale('en');
      }
    } catch (_) {
      state = const Locale('en');
    }
  }

  Future<void> toggleLocale() async {
    if (state.languageCode == 'bn') {
      await setLocale(const Locale('en'));
    } else {
      await setLocale(const Locale('bn'));
    }
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    try {
      await HiveService.cacheBox.put(_storageKey, locale.languageCode);
    } catch (_) {}
  }
}
