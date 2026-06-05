import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary:   AppColors.crimson,
        secondary: AppColors.gold,
        surface:   AppColors.surface,
        onPrimary:   Colors.white,
        onSecondary: AppColors.charcoal,
        onSurface:   AppColors.charcoal,
        error:       AppColors.error,
      ),
      extensions: const [AppGlassTokens.light],
      textTheme: GoogleFonts.latoTextTheme().copyWith(
        displayLarge: GoogleFonts.playfairDisplay(
          fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.charcoal,
        ),
        displayMedium: GoogleFonts.playfairDisplay(
          fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.charcoal,
        ),
        headlineLarge: GoogleFonts.lato(
          fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.charcoal,
        ),
        bodyLarge: GoogleFonts.lato(
          fontSize: 16, color: AppColors.charcoalMid,
        ),
        bodyMedium: GoogleFonts.lato(
          fontSize: 14, color: AppColors.charcoalMid,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.charcoal),
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.charcoal,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.crimson,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.lato(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3),
        ).copyWith(
          // Subtle press shadow for tactile feel
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) return Colors.white.withOpacity(0.1);
            return null;
          }),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.charcoal.withOpacity(0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.charcoal.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.crimson, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        labelStyle: GoogleFonts.lato(fontSize: 14, color: AppColors.charcoalLight),
        hintStyle: GoogleFonts.lato(fontSize: 14, color: AppColors.charcoalLight),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.crimson,
        inactiveTrackColor: AppColors.crimson.withOpacity(0.15),
        thumbColor: AppColors.crimson,
        overlayColor: AppColors.crimson.withOpacity(0.1),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
        trackHeight: 4,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.crimson.withOpacity(0.1),
        labelStyle: GoogleFonts.lato(fontSize: 13, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.charcoal.withOpacity(0.12)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppColors.crimson,
        unselectedItemColor: AppColors.charcoalLight,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppColors.background,
        elevation: 16,
        shadowColor: Colors.black.withOpacity(0.15),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentTextStyle: GoogleFonts.lato(fontSize: 14, color: Colors.white),
      ),
    );
  }
}
