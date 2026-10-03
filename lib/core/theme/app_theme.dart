import 'package:flutter/material.dart';
import 'package:nextpos/core/brand/app_brand.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final baseText = ThemeData.light().textTheme.apply(
          fontFamily: 'Inter',
          bodyColor: AppBrand.ink,
          displayColor: AppBrand.ink,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppBrand.background,
      canvasColor: AppBrand.background,
      dialogBackgroundColor: AppBrand.surface,
      colorScheme: const ColorScheme.light(
        primary: AppBrand.primary,
        onPrimary: Colors.white,
        secondary: AppBrand.primary,
        onSecondary: Colors.white,
        surface: AppBrand.surface,
        onSurface: AppBrand.ink,
        error: AppBrand.primary,
        onError: Colors.white,
        outline: AppBrand.border,
      ),
      textTheme: baseText,
      appBarTheme: AppBarTheme(
        backgroundColor: AppBrand.background,
        foregroundColor: AppBrand.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: baseText.titleLarge?.copyWith(
          color: AppBrand.ink,
          fontWeight: FontWeight.w700,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 70,
        backgroundColor: AppBrand.surface,
        indicatorColor: AppBrand.primarySoft,
        elevation: 0,
        labelTextStyle: WidgetStatePropertyAll(
          baseText.labelSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppBrand.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: baseText.bodyMedium?.copyWith(color: AppBrand.muted),
        labelStyle: baseText.bodyMedium?.copyWith(color: AppBrand.muted),
        prefixIconColor: AppBrand.muted,
        suffixIconColor: AppBrand.muted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppBrand.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppBrand.border),
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
          side: const BorderSide(color: AppBrand.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: baseText.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppBrand.border,
        space: 1,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppBrand.ink,
        contentTextStyle: baseText.bodyMedium?.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppBrand.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppBrand.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
