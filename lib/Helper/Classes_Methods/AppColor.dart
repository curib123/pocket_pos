import 'package:flutter/material.dart';
import 'package:nextpos/core/brand/app_brand.dart';

/// Compatibility color tokens for legacy screens.
///
/// New Pocket Inventory UI should import AppBrand directly. These aliases keep older
/// components visually aligned with the one-hue brand while they are retired.
class AppColor {
  static const Color primary = AppBrand.primary;
  static const Color accent = AppBrand.primary;
  static const Color secondary = AppBrand.primary;

  static const Color background = AppBrand.background;
  static const Color surface = AppBrand.surface;
  static const Color textPrimary = AppBrand.ink;
  static const Color textSecondary = AppBrand.muted;
  static const Color secondarySurface = AppBrand.primaryFaint;

  static const Color warning = AppBrand.primary;
  static const Color warningBackground = AppBrand.primarySoft;
  static const Color warningText = AppBrand.primaryDark;

  static const Color error = AppBrand.primary;
  static const Color errorBackground = AppBrand.primarySoft;
  static const Color errorText = AppBrand.primaryDark;

  static const Color success = AppBrand.primary;
  static const Color successBackground = AppBrand.primarySoft;
  static const Color successText = AppBrand.primaryDark;
}
