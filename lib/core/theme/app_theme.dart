import 'package:flutter/material.dart';
import 'package:nextpos/core/brand/app_brand.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final background =
        dark ? const Color(0xFF0F131B) : AppBrand.background;
    final surface = dark ? const Color(0xFF171C26) : AppBrand.surface;
    final onSurface = dark ? const Color(0xFFF3F5F8) : AppBrand.ink;
    final onSurfaceVariant =
        dark ? const Color(0xFFAAB2C0) : AppBrand.muted;
    final outline =
        dark ? const Color(0xFF303846) : AppBrand.border;

    final scheme = ColorScheme.fromSeed(
      seedColor: AppBrand.primary,
      brightness: brightness,
    ).copyWith(
      primary: AppBrand.primary,
      onPrimary: Colors.white,
      secondary: AppBrand.primary,
      onSecondary: Colors.white,
      surface: surface,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
      outline: outline,
      outlineVariant: outline,
      error: AppBrand.danger,
      onError: Colors.white,
    );

    final baseText = (dark ? ThemeData.dark() : ThemeData.light())
        .textTheme
        .apply(
          fontFamily: 'Inter',
          bodyColor: onSurface,
          displayColor: onSurface,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      dialogBackgroundColor: surface,
      colorScheme: scheme,
      textTheme: baseText,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: baseText.titleLarge?.copyWith(
          color: onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 70,
        backgroundColor: surface,
        indicatorColor: AppBrand.primary,
        elevation: 0,
        labelTextStyle: WidgetStatePropertyAll(
          baseText.labelSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: baseText.bodyMedium?.copyWith(color: onSurfaceVariant),
        labelStyle: baseText.bodyMedium?.copyWith(color: onSurfaceVariant),
        prefixIconColor: onSurfaceVariant,
        suffixIconColor: onSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppBrand.primary, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppBrand.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: baseText.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppBrand.primary,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          side: BorderSide(color: outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: baseText.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: outline,
        space: 1,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: dark ? const Color(0xFFE8ECF4) : AppBrand.ink,
        contentTextStyle: baseText.bodyMedium?.copyWith(
          color: dark ? const Color(0xFF10141C) : Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
