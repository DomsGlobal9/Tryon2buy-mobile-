import 'package:flutter/material.dart';

class AppColors {
  // Brand Backgrounds (Warm aesthetic matching web #ede8df)
  static const Color background = Color(0xFFEDE8DF);

  /// The website's page colour. Used by the home tab and result canvases.
  static const Color cream = Color(0xFFFAF7F2);

  /// Hairline on cream surfaces.
  static const Color creamBorder = Color(0xFFE5E0D8);

  /// The website's near-black ink. Slightly warmer than [primary].
  static const Color ink = Color(0xFF1A1410);
  static const Color backgroundLight = Color(0xFFF7F5F0);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1D1A);

  // Primary & Accent
  static const Color primary = Color(0xFF1A1917);
  static const Color primaryDark = Color(0xFF121110);
  static const Color accentGold = Color(0xFFD4AF37);
  static const Color accentGoldLight = Color(0xFFF4E5B8);

  /// The orange "2" in the TRYON2BUY wordmark — the true brand accent.
  static const Color brandOrange = Color(0xFFEF7F1F);
  static const Color brandOrangeLight = Color(0xFFFBE2CC);

  // Status & Feedback
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFED6C02);
  static const Color error = Color(0xFFD32F2F);
  static const Color info = Color(0xFF0288D1);

  // Text
  static const Color textPrimary = Color(0xFF1A1917);
  static const Color textSecondary = Color(0xFF4A463F);
  static const Color textMuted = Color(0xFF6B655B);
  static const Color textWhite = Color(0xFFFFFFFF);

  // Borders & Dividers
  static const Color border = Color(0xFFDDD7CD);
  static const Color borderLight = Color(0xFFEBE6DD);

  // Glassmorphism overlays
  static Color glassWhite = Colors.white.withValues(alpha: 0.7);
  static Color glassDark = Colors.black.withValues(alpha: 0.6);
}
