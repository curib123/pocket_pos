import 'package:flutter/material.dart';

/// BantayStock's visual identity.
///
/// The product intentionally uses one brand hue (blue) plus neutral surfaces
/// and text. Status meaning is communicated with copy and icons instead of
/// introducing extra red/green/yellow accent colors.
class AppBrand {
  AppBrand._();

  static const String name = 'BantayStock';
  static const String tagline = 'Simple stock, klaro araw-araw.';

  static const Color primary = Color(0xFF2457D6);
  static const Color primaryDark = Color(0xFF173B93);
  static const Color primarySoft = Color(0xFFEAF0FF);
  static const Color primaryFaint = Color(0xFFF5F7FF);

  static const Color ink = Color(0xFF111827);
  static const Color muted = Color(0xFF667085);
  static const Color border = Color(0xFFE4E7EC);
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
}
