import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tokens.dart';

/// Custom ThemeData over Material 3.
/// Rule of thumb: if M3 surfaces a brand color, override it.
/// If M3 surfaces a tint or shadow, kill it. Borders carry structure.
class AppTheme {
  /// Builds the theme for [palette]. Also makes it the active token set so
  /// widgets reading [AppTokens] directly agree with the ThemeData.
  static ThemeData build(AppPalette palette) {
    AppTokens.use(palette);
    final isDark = palette.brightness == Brightness.dark;
    final colorScheme = (isDark ? ColorScheme.dark : ColorScheme.light)(
      primary: AppTokens.accent,
      onPrimary: AppTokens.onAccent,
      secondary: AppTokens.accent,
      onSecondary: AppTokens.onAccent,
      surface: AppTokens.surface,
      onSurface: AppTokens.ink,
      error: AppTokens.danger,
      onError: AppTokens.ink,
      outline: AppTokens.line,
      surfaceTint: Colors.transparent, // kill M3 tint
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: palette.brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppTokens.bg,
      canvasColor: AppTokens.bg,
      dividerColor: AppTokens.line,
      splashFactory: InkSparkle.splashFactory,
    );

    final textTheme = GoogleFonts.interTextTheme(base.textTheme).copyWith(
      displayLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.6,
        color: AppTokens.ink,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
        color: AppTokens.ink,
      ),
      titleMedium: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: AppTokens.ink,
      ),
      bodyLarge: TextStyle(
        fontSize: 15,
        height: 1.5,
        color: AppTokens.ink,
      ),
      bodyMedium: TextStyle(
        fontSize: 13.5,
        height: 1.5,
        color: AppTokens.ink,
      ),
      labelLarge: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppTokens.ink,
      ),
    ).apply(bodyColor: AppTokens.ink, displayColor: AppTokens.ink);

    OutlineInputBorder borderOf(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.inputRadius),
          borderSide: BorderSide(color: c, width: 1),
        );

    return base.copyWith(
      textTheme: textTheme,
      primaryTextTheme: textTheme,

      // — fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppTokens.surface,
        contentPadding:
            EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: borderOf(AppTokens.line),
        enabledBorder: borderOf(AppTokens.line),
        focusedBorder: borderOf(AppTokens.accent),
        errorBorder: borderOf(AppTokens.danger),
        focusedErrorBorder: borderOf(AppTokens.danger),
        hintStyle: TextStyle(color: AppTokens.inkMuted),
        labelStyle: TextStyle(color: AppTokens.inkDim),
      ),

      // — primary CTAs are full-bleed pills
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppTokens.accent,
          foregroundColor: AppTokens.onAccent,
          minimumSize: Size.fromHeight(48),
          shape: StadiumBorder(),
          textStyle: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // — secondary (outlined) buttons follow the same shape
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTokens.ink,
          side: BorderSide(color: AppTokens.line),
          minimumSize: Size.fromHeight(48),
          shape: StadiumBorder(),
          textStyle: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // — text buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppTokens.accent,
          textStyle: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      // — app bar: flat, no elevation tint
      appBarTheme: AppBarTheme(
        backgroundColor: AppTokens.bg,
        foregroundColor: AppTokens.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppTokens.ink,
        ),
      ),

      // — drawer
      drawerTheme: DrawerThemeData(
        backgroundColor: AppTokens.surface,
        elevation: 0,
        width: 304,
        shape: RoundedRectangleBorder(),
      ),

      // — bottom sheets (confirm modals, image upload)
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppTokens.surface,
        modalBackgroundColor: AppTokens.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: AppTokens.line,
        thickness: 1,
        space: 1,
      ),

      // Avoid raw ListTile — but if used, line it up with the gutter.
      listTileTheme: ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: AppTokens.gutter),
        minVerticalPadding: 12,
      ),

      // Kill M3 card defaults; we use plain Containers + borders.
      cardTheme: CardThemeData(
        color: AppTokens.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.cardRadius),
          side: BorderSide(color: AppTokens.line),
        ),
      ),
    );
  }

  static TextStyle monoStyle({
    double fontSize = 12,
    Color? color,
    FontWeight weight = FontWeight.w500,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      fontWeight: weight,
      letterSpacing: 0.06 * fontSize / 10.5,
      color: color ?? AppTokens.inkMuted,
    );
  }
}
