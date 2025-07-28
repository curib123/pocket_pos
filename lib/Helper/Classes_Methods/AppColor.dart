import 'package:flutter/material.dart';

class AppColor {
  // 🟦 Primary – Deep Teal (Teal-700)
  static const Color primary = Color(0xFF0F766E); // Strong, calming, confident

  // 🟣 Accent – Soft Lilac
  static const Color accent = Color(0xFFD8B4FE); // Light Violet — pops against teal

  // 🪵 Secondary – Cool Gray
  static const Color secondary = Color(0xFF94A3B8); // Balanced, neutral fallback

  // ☁️ Background – Ultra Soft
  static const Color background = Color(0xFFFAFAFA); // Gentle on eyes

  // 📄 Surface – Clean White
  static const Color surface = Color(0xFFFFFFFF); // For cards, modals, etc.

  // 🖋️ Text – Crisp & Clear
  static const Color textPrimary = Color(0xFF111827);    // Deep slate
  static const Color textSecondary = Color(0xFF6B7280);  // Muted gray

  // ⚠️ Warning – Warm Honey
  static const Color warning = Color(0xFFFBBF24);           // Amber-400
  static const Color warningBackground = Color(0xFFFFF7E6); // Light amber bg
  static const Color warningText = Color(0xFF78350F);       // Deep amber text

  // ❌ Error – Rose Red
  static const Color error = Color(0xFFEF4444);             // Red-500
  static const Color errorBackground = Color(0xFFFFE4E6);   // Gentle red bg
  static const Color errorText = Color(0xFF7F1D1D);         // Contrast error label

  // ✅ Success – Emerald
  static const Color success = Color(0xFF10B981);           // Emerald-500
  static const Color successBackground = Color(0xFFF0FDF4); // Light minty bg
  static const Color successText = Color(0xFF064E3B);       // Deep green

  // 🔘 Inputs / Fields – Ultra Light Gray
  static const Color secondarySurface = Color(0xFFF3F4F6); // Field bg, soft contrast
}
