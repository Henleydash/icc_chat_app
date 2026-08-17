import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palette reprise du site web IN CRYPT Codage, pour garder
/// une identité visuelle cohérente entre le site et l'application.
class AppColors {
  static const navy = Color(0xFF0A1533);
  static const navy2 = Color(0xFF101F45);
  static const blue = Color(0xFF2B5CFF);
  static const blueLight = Color(0xFF6E93FF);
  static const orange = Color(0xFFFF8C1A);
  static const orange2 = Color(0xFFFFB25C);
  static const paper = Color(0xFFF5F7FF);
  static const white = Color(0xFFFFFFFF);
  static const ink = Color(0xFF0A1533);
  static const inkSoft = Color(0xFF4C567A);
  static const inkFaint = Color(0xFF8A93B8);
  static const line = Color(0xFFE1E6F5);
  static const green = Color(0xFF1DB876);
  static const danger = Color(0xFFE0483E);

  static const avatarPalette = [blue, orange, green, navy2];
}

/// Dégradé principal utilisé sur les éléments d'accent (logo, badges, CTA).
const kBrandGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [AppColors.blue, AppColors.orange],
);

ThemeData buildAppTheme() {
  final base = ThemeData(useMaterial3: true, brightness: Brightness.light);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.paper,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.blue,
      secondary: AppColors.orange,
      surface: AppColors.white,
      error: AppColors.danger,
    ),
    textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.spaceGrotesk(
          fontWeight: FontWeight.w700, color: AppColors.navy, letterSpacing: -0.5),
      displayMedium: GoogleFonts.spaceGrotesk(
          fontWeight: FontWeight.w700, color: AppColors.navy, letterSpacing: -0.5),
      titleLarge: GoogleFonts.spaceGrotesk(
          fontWeight: FontWeight.w700, color: AppColors.navy),
      titleMedium: GoogleFonts.spaceGrotesk(
          fontWeight: FontWeight.w600, color: AppColors.navy),
      bodyMedium: GoogleFonts.inter(color: AppColors.ink),
      bodySmall: GoogleFonts.inter(color: AppColors.inkSoft),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.paper,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      foregroundColor: AppColors.navy,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.line, width: 1.4),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.line, width: 1.4),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.blue, width: 1.6),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.orange,
        foregroundColor: AppColors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        elevation: 0,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.white,
      selectedItemColor: AppColors.navy,
      unselectedItemColor: AppColors.inkFaint,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
    ),
  );
}
