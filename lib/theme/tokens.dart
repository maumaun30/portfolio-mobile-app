import 'package:flutter/material.dart';

/// One full set of colors. Mirrors the CSS custom properties in the web
/// portfolio's `app/globals.css` (`:root` = light, `.dark` = Gold Noir).
class AppPalette {
  const AppPalette({
    required this.brightness,
    required this.bg,
    required this.surface,
    required this.surfaceHi,
    required this.ink,
    required this.inkDim,
    required this.inkMuted,
    required this.accent,
    required this.onAccent,
    required this.danger,
  });

  final Brightness brightness;
  final Color bg;
  final Color surface;
  final Color surfaceHi;
  final Color ink;
  final Color inkDim;
  final Color inkMuted;
  final Color accent;
  final Color onAccent;
  final Color danger;

  /// Light — warm paper, deep gold accent.
  static const light = AppPalette(
    brightness: Brightness.light,
    bg: Color(0xFFF5F0E6),
    surface: Color(0xFFFBF8F2),
    surfaceHi: Color(0xFFEBE4D6),
    ink: Color(0xFF1A1610),
    inkDim: Color(0xFF605C54), // ink @ 68% over bg
    inkMuted: Color(0xFF8C877F), // ink @ 48% over bg
    accent: Color(0xFF8A6424),
    onAccent: Color(0xFFFBF8F2),
    danger: Color(0xFFB91C1C),
  );

  /// Gold Noir — dark, warm, single accent.
  static const dark = AppPalette(
    brightness: Brightness.dark,
    bg: Color(0xFF0A0907),
    surface: Color(0xFF13110F),
    surfaceHi: Color(0xFF1A1714),
    ink: Color(0xFFEFE6D4),
    inkDim: Color(0xFFA59C8A),
    inkMuted: Color(0xFF6B6356),
    accent: Color(0xFFD9B36A),
    onAccent: Color(0xFF1A1208),
    danger: Color(0xFFC4664C),
  );
}

/// Design tokens — mirror of design/theme.js.
/// Never hardcode these values elsewhere; reference them by name.
///
/// Colors resolve against the active [AppPalette], swapped by the theme
/// controller (see `theme_controller.dart`).
class AppTokens {
  static AppPalette _p = AppPalette.light;
  static AppPalette get palette => _p;
  static void use(AppPalette p) => _p = p;
  static bool get isDark => _p.brightness == Brightness.dark;

  // ── color
  static Color get bg => _p.bg;
  static Color get surface => _p.surface;
  static Color get surfaceHi => _p.surfaceHi;
  static Color get ink => _p.ink;
  static Color get inkDim => _p.inkDim;
  static Color get inkMuted => _p.inkMuted;
  static Color get accent => _p.accent;
  static Color get onAccent => _p.onAccent;
  static Color get danger => _p.danger;

  static Color get line => ink.withOpacity(isDark ? 0.08 : 0.10);
  static Color get lineStrong => ink.withOpacity(isDark ? 0.14 : 0.18);
  static Color get accent10 => accent.withOpacity(0.10);
  static Color get accent20 => accent.withOpacity(0.20);
  static Color get danger10 => danger.withOpacity(0.10);

  /// Translucent scrim behind modal sheets.
  static Color get scrim => bg.withOpacity(0.7);

  /// Ink as a 6-digit hex (no `#`) — for CDN-tinted icons (simpleicons).
  static String get inkHex =>
      (ink.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0');

  // ── geometry
  static const double gutter = 18;
  static const double rowPadV = 14;
  static const double inputRadius = 11;
  static const double cardRadius = 14;
  static const double pillRadius = 999;

  // ── type families (used by AppTheme + google_fonts fallback)
  static const String sans = 'Inter';
  static const String mono = 'JetBrainsMono';
}
