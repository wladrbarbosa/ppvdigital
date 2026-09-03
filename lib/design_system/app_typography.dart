import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ppvdigital/design_system/app_colors.dart';

/// Tokens tipográficos do Design System Seapruma.
/// Adota 'Plus Jakarta Sans' para proporcionalidade geométrica moderna,
/// ritmo respirável e legibilidade superior sem fadiga visual.
abstract final class AppTypography {
  static const String fontFamily = 'Plus Jakarta Sans';
  static const String fallbackFontFamily = 'Inter';

  /// Gera a escala tipográfica limpa com fallback seguro caso o Google Fonts falhe
  static TextTheme createTextTheme(BuildContext context, {bool isDark = false}) {
    final baseTextTheme = Theme.of(context).textTheme;
    final primaryColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    try {
      final googleTheme = GoogleFonts.plusJakartaSansTextTheme(baseTextTheme);
      return googleTheme.copyWith(
        displayLarge: googleTheme.displayLarge?.copyWith(
          color: primaryColor,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        displayMedium: googleTheme.displayMedium?.copyWith(
          color: primaryColor,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        headlineLarge: googleTheme.headlineLarge?.copyWith(
          color: primaryColor,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        headlineMedium: googleTheme.headlineMedium?.copyWith(
          color: primaryColor,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        titleLarge: googleTheme.titleLarge?.copyWith(
          color: primaryColor,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
        ),
        titleMedium: googleTheme.titleMedium?.copyWith(
          color: primaryColor,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: googleTheme.titleSmall?.copyWith(
          color: secondaryColor,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: googleTheme.bodyLarge?.copyWith(
          color: primaryColor,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        bodyMedium: googleTheme.bodyMedium?.copyWith(
          color: primaryColor,
          fontWeight: FontWeight.w400,
          height: 1.45,
        ),
        bodySmall: googleTheme.bodySmall?.copyWith(
          color: secondaryColor,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: googleTheme.labelLarge?.copyWith(
          color: primaryColor,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
        labelMedium: googleTheme.labelMedium?.copyWith(
          color: secondaryColor,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: googleTheme.labelSmall?.copyWith(
          color: secondaryColor,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
        ),
      );
    } catch (_) {
      return baseTextTheme.apply(
        bodyColor: primaryColor,
        displayColor: primaryColor,
      );
    }
  }
}
