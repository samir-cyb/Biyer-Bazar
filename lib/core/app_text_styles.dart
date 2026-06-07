import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Display / Hero — Cormorant Garamond: ultra-luxury, perfect for weddings
  static TextStyle displayLarge = GoogleFonts.cormorantGaramond(
    fontSize: 38,
    fontWeight: FontWeight.w700,
    color: AppColors.charcoal,
    height: 1.15,
    letterSpacing: -0.5,
  );

  static TextStyle displayMedium = GoogleFonts.cormorantGaramond(
    fontSize: 30,
    fontWeight: FontWeight.w600,
    color: AppColors.charcoal,
    height: 1.2,
    letterSpacing: -0.3,
  );

  static TextStyle displaySmall = GoogleFonts.cormorantGaramond(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.charcoal,
    height: 1.25,
  );

  // Headings — DM Sans: clean, modern, highly legible
  static TextStyle headingLarge = GoogleFonts.dmSans(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.charcoal,
    letterSpacing: -0.2,
  );

  static TextStyle headingMedium = GoogleFonts.dmSans(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: AppColors.charcoal,
    letterSpacing: -0.1,
  );

  static TextStyle headingSmall = GoogleFonts.dmSans(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.charcoal,
  );

  // Body — DM Sans
  static TextStyle bodyLarge = GoogleFonts.dmSans(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.charcoalMid,
    height: 1.6,
  );

  static TextStyle bodyMedium = GoogleFonts.dmSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.charcoalMid,
    height: 1.55,
  );

  static TextStyle bodySmall = GoogleFonts.dmSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.charcoalLight,
    height: 1.5,
  );

  // Labels
  static TextStyle labelLarge = GoogleFonts.dmSans(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.6,
    color: AppColors.charcoal,
  );

  static TextStyle labelMedium = GoogleFonts.dmSans(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
    color: AppColors.charcoalLight,
  );

  // Currency / Numbers — Cormorant Garamond for the elegant feel
  static TextStyle currencyHero = GoogleFonts.cormorantGaramond(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    color: AppColors.crimson,
    letterSpacing: -0.5,
  );

  static TextStyle currencyMedium = GoogleFonts.dmSans(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.crimson,
    letterSpacing: 0.1,
  );

  // Bangla-friendly (Hind Siliguri covers Bengali script beautifully)
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
