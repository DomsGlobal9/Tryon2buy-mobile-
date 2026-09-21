import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// The website's type system, ported one role at a time.
///
/// tryon2buy.com mixes seven Google families, each with a fixed job:
///
/// | Role                                   | Family           |
/// |----------------------------------------|------------------|
/// | Headlines, page titles                 | EB Garamond      |
/// | Paragraph copy                         | Inter            |
/// | Marketing page base text               | Montserrat       |
/// | Small uppercase eyebrows / labels      | Outfit           |
/// | Nav links and call-to-action buttons   | Merriweather     |
/// | Studio / gallery / fitting-room chrome | Courier Prime    |
/// | Studio panel headings                  | Playfair Display |
/// | B2B portal and catalog                 | Space Grotesk    |
///
/// Screens pick by role, never by family name, so a font swap is one edit.
class AppTypography {
  const AppTypography._();

  // ── Headlines (EB Garamond) ────────────────────────────────────────────

  static TextStyle display({
    double size = 42,
    Color color = AppColors.textPrimary,
    FontStyle style = FontStyle.normal,
  }) =>
      GoogleFonts.ebGaramond(
        fontSize: size,
        fontWeight: FontWeight.w600,
        fontStyle: style,
        height: 1.1,
        letterSpacing: -0.3,
        color: color,
      );

  static TextStyle get displayLarge => display(size: 34);
  static TextStyle get displayMedium => display(size: 28);
  static TextStyle get titleLarge => display(size: 23);

  /// Sub-headings inside cards and rows. The website sets these in the
  /// running sans at bold weight, not in the serif.
  static TextStyle get titleMedium => GoogleFonts.inter(
        fontSize: 16.5,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  // ── Body (Inter / Montserrat) ──────────────────────────────────────────

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        height: 1.45,
      );

  /// Marketing pages (home, about, solutions, journal) sit on Montserrat.
  static TextStyle marketing({
    double size = 15,
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.textSecondary,
  }) =>
      GoogleFonts.montserrat(
        fontSize: size,
        fontWeight: weight,
        height: 1.5,
        color: color,
      );

  // ── Labels (Outfit) ────────────────────────────────────────────────────

  /// Small tracked uppercase label. Callers upper-case the string.
  static TextStyle eyebrow({
    double size = 12,
    Color color = AppColors.textSecondary,
    double letterSpacing = 1.4,
  }) =>
      GoogleFonts.outfit(
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: letterSpacing,
        color: color,
      );

  static TextStyle get labelSmall => GoogleFonts.outfit(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      );

  // ── Buttons and nav (Merriweather) ─────────────────────────────────────

  /// Website buttons: Merriweather bold, uppercase, wide tracking.
  static TextStyle cta({
    double size = 13.5,
    Color color = AppColors.textWhite,
    double letterSpacing = 1.4,
  }) =>
      GoogleFonts.merriweather(
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: letterSpacing,
        color: color,
      );

  static TextStyle get buttonText => cta();

  // ── Studio chrome (Courier Prime / Playfair Display) ───────────────────

  /// Body text in the merchant studio, galleries and the fitting room.
  static TextStyle mono({
    double size = 13,
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.textPrimary,
    double letterSpacing = 0,
  }) =>
      GoogleFonts.courierPrime(
        fontSize: size,
        fontWeight: weight,
        letterSpacing: letterSpacing,
        height: 1.45,
        color: color,
      );

  /// Tracked uppercase step labels ("1 SELECT CATEGORY").
  static TextStyle monoLabel({
    double size = 12,
    Color color = AppColors.textPrimary,
    double letterSpacing = 1.2,
  }) =>
      mono(size: size, weight: FontWeight.w700, color: color, letterSpacing: letterSpacing);

  /// Studio panel headings ("Virtual Fitting Room").
  static TextStyle studioHeading({
    double size = 20,
    Color color = AppColors.textPrimary,
  }) =>
      GoogleFonts.playfairDisplay(
        fontSize: size,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: color,
      );

  // ── B2B portal (Space Grotesk) ─────────────────────────────────────────

  static TextStyle grotesk({
    double size = 15,
    FontWeight weight = FontWeight.w600,
    Color color = AppColors.textPrimary,
    double letterSpacing = 0,
  }) =>
      GoogleFonts.spaceGrotesk(
        fontSize: size,
        fontWeight: weight,
        letterSpacing: letterSpacing,
        height: 1.4,
        color: color,
      );
}
