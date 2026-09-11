import 'package:flutter/material.dart';

import 'app_semantic_colors.dart';

/// The app's two `ThemeData` instances — the single place light/dark theming
/// is defined, so no screen ever builds its own `ThemeData`.
///
/// Colors and typography match the BYEPO Technologies brand (byepo.com):
/// brand orange accent, Manrope typeface, and the site's own light/dark
/// background pair.
class AppTheme {
  const AppTheme._();

  static const _brandOrange = Color(0xFFFFA500);
  static const _inkLight = Color(0xFF151515);
  static const _inkDark = Color(0xFFFFFFFF);
  static const _bgPrimaryLight = Color(0xFFFFFFFF);
  static const _bgSecondaryLight = Color(0xFFF6F6F6);
  static const _bgPrimaryDark = Color(0xFF1F2839);
  static const _bgSecondaryDark = Color(0xFF171E2B);

  // `surfaceContainer`/`surfaceContainerLow` are pinned alongside `surface`
  // because ColorScheme.fromSeed derives them algorithmically from the seed,
  // not from `surface` — AppBar/NavigationBar (surfaceContainer) and the
  // default Card (surfaceContainerLow) would otherwise render an M3-generated
  // gray instead of the brand's secondary background tone.
  static final ColorScheme _lightScheme = ColorScheme.fromSeed(
    seedColor: _brandOrange,
    brightness: Brightness.light,
  ).copyWith(
    primary: _brandOrange,
    // Dark ink on orange (~9:1 contrast) instead of white (~2.2:1, fails WCAG AA).
    onPrimary: _inkLight,
    surface: _bgPrimaryLight,
    onSurface: _inkLight,
    surfaceContainer: _bgSecondaryLight,
    surfaceContainerLow: _bgSecondaryLight,
  );

  static final ColorScheme _darkScheme = ColorScheme.fromSeed(
    seedColor: _brandOrange,
    brightness: Brightness.dark,
  ).copyWith(
    primary: _brandOrange,
    onPrimary: _inkLight,
    surface: _bgPrimaryDark,
    onSurface: _inkDark,
    surfaceContainer: _bgSecondaryDark,
    surfaceContainerLow: _bgSecondaryDark,
  );

  static ThemeData get light => ThemeData(
        colorScheme: _lightScheme,
        brightness: Brightness.light,
        fontFamily: 'Manrope',
        useMaterial3: true,
        extensions: const [AppSemanticColors.light],
      );

  static ThemeData get dark => ThemeData(
        colorScheme: _darkScheme,
        brightness: Brightness.dark,
        fontFamily: 'Manrope',
        useMaterial3: true,
        extensions: const [AppSemanticColors.dark],
      );
}
