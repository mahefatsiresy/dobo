import 'package:flutter/material.dart';

import 'tokens.dart';

const _family = 'Atkinson Hyperlegible Next';
const _fallback = ['Noto Sans'];
const _tabular = [FontFeature.tabularFigures()];

/// The phone app's theme (docs/design.md): ink on paper, light only, type
/// built for reading in sunlight, 56 dp buttons.
ThemeData doboTheme() {
  const c = DoboColors.standard;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: c.ink,
        dynamicSchemeVariant: DynamicSchemeVariant.monochrome,
      ).copyWith(
        primary: c.ink,
        onPrimary: c.paper,
        secondary: c.inkMuted,
        onSecondary: c.paper,
        surface: c.paper,
        onSurface: c.ink,
        onSurfaceVariant: c.inkMuted,
        outline: c.line,
        outlineVariant: c.line,
        error: c.danger,
        onError: c.paper,
        surfaceTint: Colors.transparent,
      );

  TextStyle style(double size, FontWeight weight, {Color? colour}) => TextStyle(
    fontFamily: _family,
    fontFamilyFallback: _fallback,
    fontSize: size,
    fontWeight: weight,
    color: colour ?? c.ink,
  );
  const regular = FontWeight.w400;
  const semiBold = FontWeight.w600;
  const bold = FontWeight.w700;
  final text = TextTheme(
    displayLarge: style(48, bold),
    displayMedium: style(40, bold),
    displaySmall: style(34, bold),
    headlineLarge: style(32, bold),
    headlineMedium: style(30, bold),
    headlineSmall: style(28, bold).copyWith(fontFeatures: _tabular),
    titleLarge: style(22, semiBold),
    titleMedium: style(18, semiBold).copyWith(fontFeatures: _tabular),
    titleSmall: style(16, semiBold),
    bodyLarge: style(16, regular).copyWith(height: 1.4),
    bodyMedium: style(16, regular),
    bodySmall: style(14, regular, colour: c.inkMuted),
    labelLarge: style(16, semiBold),
    labelMedium: style(14, semiBold),
    labelSmall: style(14, regular),
  );

  final shape8 = RoundedRectangleBorder(borderRadius: BorderRadius.circular(8));
  const tall = Size(64, 56);
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: scheme,
    fontFamily: _family,
    fontFamilyFallback: _fallback,
    textTheme: text,
    scaffoldBackgroundColor: c.paper,
    extensions: const [c],
    appBarTheme: AppBarTheme(
      backgroundColor: c.paper,
      foregroundColor: c.ink,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      titleTextStyle: text.titleLarge,
      shape: Border(bottom: BorderSide(color: c.line)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: c.paper,
      surfaceTintColor: Colors.transparent,
      indicatorColor: c.shade,
      labelTextStyle: WidgetStatePropertyAll(text.labelMedium),
      iconTheme: WidgetStatePropertyAll(IconThemeData(color: c.ink)),
    ),
    dividerTheme: DividerThemeData(color: c.line, thickness: 1, space: 1),
    cardTheme: CardThemeData(
      color: c.paper,
      surfaceTintColor: Colors.transparent,
      shape: shape8.copyWith(side: BorderSide(color: c.line)),
      elevation: 0,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: tall,
        shape: shape8,
        textStyle: text.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: tall,
        shape: shape8,
        foregroundColor: c.ink,
        side: BorderSide(color: c.ink),
        textStyle: text.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: tall,
        shape: shape8,
        foregroundColor: c.ink,
        textStyle: text.labelLarge,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.paper,
      surfaceTintColor: Colors.transparent,
      shape: shape8,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: c.ink,
      contentTextStyle: text.bodyMedium!.copyWith(color: c.paper),
    ),
  );
}
