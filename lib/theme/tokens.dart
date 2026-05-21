import 'package:flutter/material.dart';

/// Design tokens — mirror of design/theme.js.
/// Never hardcode these values elsewhere; reference them by name.
class AppTokens {
  // ── color
  static const Color bg = Color(0xFF0A0907);
  static const Color surface = Color(0xFF13110F);
  static const Color surfaceHi = Color(0xFF1A1714);
  static const Color ink = Color(0xFFEFE6D4);
  static const Color inkDim = Color(0xFFA59C8A);
  static const Color inkMuted = Color(0xFF6B6356);
  static const Color accent = Color(0xFFD9B36A);
  static const Color onAccent = Color(0xFF1A1208);
  static const Color danger = Color(0xFFC4664C);

  static Color get line => ink.withOpacity(0.08);
  static Color get lineStrong => ink.withOpacity(0.14);
  static Color get accent10 => accent.withOpacity(0.10);
  static Color get accent20 => accent.withOpacity(0.20);
  static Color get danger10 => danger.withOpacity(0.10);

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
