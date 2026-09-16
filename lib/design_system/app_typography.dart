import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
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
      return TextTheme(
        displayLarge: GoogleFonts.plusJakartaSans(
          textStyle: baseTextTheme.displayLarge,
          color: primaryColor,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.plusJakartaSans(
          textStyle: baseTextTheme.displayMedium,
          color: primaryColor,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        headlineLarge: GoogleFonts.plusJakartaSans(
          textStyle: baseTextTheme.headlineLarge,
          color: primaryColor,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          textStyle: baseTextTheme.headlineMedium,
          color: primaryColor,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          textStyle: baseTextTheme.titleLarge,
          color: primaryColor,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          textStyle: baseTextTheme.titleMedium,
          color: primaryColor,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: GoogleFonts.plusJakartaSans(
          textStyle: baseTextTheme.titleSmall,
          color: secondaryColor,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          textStyle: baseTextTheme.bodyLarge,
          color: primaryColor,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          textStyle: baseTextTheme.bodyMedium,
          color: primaryColor,
          fontWeight: FontWeight.w400,
          height: 1.45,
        ),
        bodySmall: GoogleFonts.plusJakartaSans(
          textStyle: baseTextTheme.bodySmall,
          color: secondaryColor,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: GoogleFonts.plusJakartaSans(
          textStyle: baseTextTheme.labelLarge,
          color: primaryColor,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
        labelMedium: GoogleFonts.plusJakartaSans(
          textStyle: baseTextTheme.labelMedium,
          color: secondaryColor,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: GoogleFonts.plusJakartaSans(
          textStyle: baseTextTheme.labelSmall,
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
