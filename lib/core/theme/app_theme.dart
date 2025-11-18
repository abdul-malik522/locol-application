import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:localtrade/core/theme/app_colors.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData lightTheme() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surfaceTint: AppColors.surface,
        brightness: Brightness.light,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(
          fontSize: 48,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
        labelLarge: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.8),
        ),
        hintStyle: const TextStyle(color: AppColors.textHint),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary.withOpacity(0.15),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
      ),
    );
  }

  static ThemeData darkTheme() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
        primary: AppColors.primaryDark,
        secondary: AppColors.secondaryDark,
        surfaceTint: AppColors.surfaceDark,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.backgroundDark,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(
          fontSize: 48,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimaryDark,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimaryDark,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          color: AppColors.textPrimaryDark,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: AppColors.textSecondaryDark,
        ),
        labelLarge: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimaryDark,
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.textPrimaryDark,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimaryDark,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondaryDark,
        type: BottomNavigationBarType.fixed,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.dividerDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.8),
        ),
        hintStyle: const TextStyle(color: AppColors.textHint),
        labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedColor: AppColors.primary.withOpacity(0.2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerDark,
        thickness: 1,
      ),
    );
  }
}

