import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Display / Hero
  static TextStyle displayLarge = GoogleFonts.playfairDisplay(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: AppColors.charcoal,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static TextStyle displayMedium = GoogleFonts.playfairDisplay(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: AppColors.charcoal,
    height: 1.25,
    letterSpacing: -0.3,
  );

  static TextStyle displaySmall = GoogleFonts.playfairDisplay(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.charcoal,
    height: 1.3,
  );

  // Headings
  static TextStyle headingLarge = GoogleFonts.lato(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.charcoal,
    letterSpacing: 0.1,
  );

  static TextStyle headingMedium = GoogleFonts.lato(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: AppColors.charcoal,
    letterSpacing: 0.1,
  );

  static TextStyle headingSmall = GoogleFonts.lato(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.charcoal,
  );

  // Body
  static TextStyle bodyLarge = GoogleFonts.lato(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.charcoalMid,
    height: 1.6,
  );

  static TextStyle bodyMedium = GoogleFonts.lato(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.charcoalMid,
    height: 1.55,
  );

  static TextStyle bodySmall = GoogleFonts.lato(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.charcoalLight,
    height: 1.5,
  );

  // Labels
  static TextStyle labelLarge = GoogleFonts.lato(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
    color: AppColors.charcoal,
  );

  static TextStyle labelMedium = GoogleFonts.lato(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.0,
    color: AppColors.charcoalLight,
  );

  // Currency / Numbers
  static TextStyle currencyHero = GoogleFonts.playfairDisplay(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.crimson,
    letterSpacing: -0.5,
  );

  static TextStyle currencyMedium = GoogleFonts.lato(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.crimson,
    letterSpacing: 0.2,
  );

  // Bangla-friendly fallback (Hind Siliguri covers Bengali script)
  static TextStyle bangla = GoogleFonts.hindSiliguri(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.charcoalMid,
    height: 1.6,
  );

  static TextStyle banglaHeading = GoogleFonts.hindSiliguri(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.charcoal,
  );
}
