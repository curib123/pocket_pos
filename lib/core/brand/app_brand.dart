import 'package:flutter/material.dart';

/// Pocket Inventory's visual identity.
///
/// Blue remains the primary product color. Red and orange are reserved for
/// inventory status so out-of-stock and low-stock states are immediately clear.
class AppBrand {
  AppBrand._();

  static const String name = 'Pocket Inventory';
  static const String tagline = 'Simple stock, klaro araw-araw.';

  static const Color primary = Color(0xFF2457D6);
  static const Color primaryDark = Color(0xFF173B93);
  static const Color primarySoft = Color(0xFFEAF0FF);
  static const Color primaryFaint = Color(0xFFF5F7FF);

  static const Color warning = Color(0xFFF79009);
  static const Color warningSoft = Color(0xFFFFFAEB);
  static const Color danger = Color(0xFFD92D20);
  static const Color dangerSoft = Color(0xFFFEF3F2);

  // Light palette constants kept for legacy screens.
  static const Color ink = Color(0xFF111827);
  static const Color muted = Color(0xFF667085);
  static const Color border = Color(0xFFE4E7EC);
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color inkOf(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  static Color mutedOf(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant;

  static Color borderOf(BuildContext context) =>
      Theme.of(context).colorScheme.outlineVariant;

  static Color surfaceOf(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

  static Color backgroundOf(BuildContext context) =>
      Theme.of(context).scaffoldBackgroundColor;

  static Color primarySoftOf(BuildContext context) => isDark(context)
      ? Color.alphaBlend(primary.withOpacity(.20), surfaceOf(context))
      : primarySoft;

  static Color primaryFaintOf(BuildContext context) => isDark(context)
      ? Color.alphaBlend(primary.withOpacity(.10), surfaceOf(context))
      : primaryFaint;

  static Color warningSoftOf(BuildContext context) => isDark(context)
      ? Color.alphaBlend(warning.withOpacity(.16), surfaceOf(context))
      : warningSoft;

  static Color dangerSoftOf(BuildContext context) => isDark(context)
      ? Color.alphaBlend(danger.withOpacity(.16), surfaceOf(context))
      : dangerSoft;
}
