import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tokens.dart';

/// Light / dark preference, persisted. Mirrors the web portfolio's
/// next-themes setup: `defaultTheme="light"`, `enableSystem={false}`.
class ThemeController extends StateNotifier<Brightness> {
  ThemeController(super.initial);

  static const _key = 'theme';

  /// Read the saved preference before `runApp` so the first frame is right.
  static Future<Brightness> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_key) == 'dark'
          ? Brightness.dark
          : Brightness.light;
    } catch (_) {
      return Brightness.light;
    }
  }

  bool get isDark => state == Brightness.dark;

  Future<void> set(Brightness b) async {
    if (b == state) return;
    state = b;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, b == Brightness.dark ? 'dark' : 'light');
    } catch (_) {}
  }

  Future<void> toggle() => set(isDark ? Brightness.light : Brightness.dark);
}

/// Overridden in `main()` with the loaded preference.
final themeControllerProvider =
    StateNotifierProvider<ThemeController, Brightness>(
  (ref) => ThemeController(Brightness.light),
);

AppPalette paletteFor(Brightness b) =>
    b == Brightness.dark ? AppPalette.dark : AppPalette.light;
