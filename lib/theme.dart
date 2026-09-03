// ignore_for_file: use_full_hex_values_for_flutter_colors

import 'package:flutter/material.dart';
import 'package:ppvdigital/design_system/design_system.dart';

class MaterialTheme {
  const MaterialTheme(this.textTheme);
  final TextTheme textTheme;

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primaryLight,
      surfaceTint: AppColors.primaryLight,
      onPrimary: AppColors.onPrimaryLight,
      primaryContainer: AppColors.primaryContainerLight,
      onPrimaryContainer: AppColors.onPrimaryContainerLight,
      secondary: AppColors.secondaryLight,
      onSecondary: AppColors.onSecondaryLight,
      secondaryContainer: AppColors.secondaryContainerLight,
      onSecondaryContainer: AppColors.onSecondaryContainerLight,
      tertiary: AppColors.tertiaryLight,
      onTertiary: AppColors.onTertiaryLight,
      tertiaryContainer: AppColors.tertiaryContainerLight,
      onTertiaryContainer: AppColors.onTertiaryContainerLight,
      error: AppColors.pastelError,
      onError: AppColors.onPastelError,
      errorContainer: AppColors.pastelErrorContainer,
      onErrorContainer: AppColors.onPastelErrorContainer,
      surface: AppColors.backgroundLight,
      onSurface: AppColors.textPrimaryLight,
      onSurfaceVariant: AppColors.textSecondaryLight,
      outline: AppColors.borderLight,
      outlineVariant: AppColors.dividerLight,
      shadow: Color(0x141A202C),
      scrim: Color(0x33000000),
      inverseSurface: AppColors.surfaceDark,
      inversePrimary: AppColors.primaryDark,
      primaryFixed: AppColors.primaryContainerLight,
      onPrimaryFixed: AppColors.onPrimaryContainerLight,
      primaryFixedDim: AppColors.primaryLight,
      onPrimaryFixedVariant: AppColors.onPrimaryContainerLight,
      secondaryFixed: AppColors.secondaryContainerLight,
      onSecondaryFixed: AppColors.onSecondaryContainerLight,
      secondaryFixedDim: AppColors.secondaryLight,
      onSecondaryFixedVariant: AppColors.onSecondaryContainerLight,
      tertiaryFixed: AppColors.tertiaryContainerLight,
      onTertiaryFixed: AppColors.onTertiaryContainerLight,
      tertiaryFixedDim: AppColors.tertiaryLight,
      onTertiaryFixedVariant: AppColors.onTertiaryContainerLight,
      surfaceDim: Color(0xFFF0F3F7),
      surfaceBright: AppColors.backgroundLight,
      surfaceContainerLowest: AppColors.surfaceLight,
      surfaceContainerLow: Color(0xFFF4F6F9),
      surfaceContainer: Color(0xFFEFF2F6),
      surfaceContainerHigh: Color(0xFFE9EDF2),
      surfaceContainerHighest: Color(0xFFE3E8EE),
    );
  }

  ThemeData light() {
    return theme(lightScheme());
  }

  static ColorScheme lightMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(4285411368),
      surfaceTint: Color(4287646274),
      onPrimary: Color(4294967295),
      primaryContainer: Color(4289355862),
      onPrimaryContainer: Color(4294967295),
      secondary: Color(4278209108),
      onSecondary: Color(4294967295),
      secondaryContainer: Color(4280713101),
      onSecondaryContainer: Color(4294967295),
      tertiary: Color(4282661746),
      onTertiary: Color(4294967295),
      tertiaryContainer: Color(4286016936),
      onTertiaryContainer: Color(4294967295),
      error: Color(4285215507),
      onError: Color(4294967295),
      errorContainer: Color(4289225535),
      onErrorContainer: Color(4294967295),
      surface: Color(4294965495),
      onSurface: Color(4280490264),
      onSurfaceVariant: Color(4282074183),
      outline: Color(4283982179),
      outlineVariant: Color(4285758591),
      shadow: Color(4278190080),
      scrim: Color(4278190080),
      inverseSurface: Color(4281937453),
      inversePrimary: Color(4294948010),
      primaryFixed: Color(4289355862),
      onPrimaryFixed: Color(4294967295),
      primaryFixedDim: Color(4287449151),
      onPrimaryFixedVariant: Color(4294967295),
      secondaryFixed: Color(4280713101),
      onSecondaryFixed: Color(4294967295),
      secondaryFixedDim: Color(4278216306),
      onSecondaryFixedVariant: Color(4294967295),
      tertiaryFixed: Color(4286016936),
      onTertiaryFixed: Color(4294967295),
      tertiaryFixedDim: Color(4284372110),
      onTertiaryFixedVariant: Color(4294967295),
      surfaceDim: Color(4293449428),
      surfaceBright: Color(4294965495),
      surfaceContainerLowest: Color(4294967295),
      surfaceContainerLow: Color(4294963439),
      surfaceContainer: Color(4294765288),
      surfaceContainerHigh: Color(4294370530),
      surfaceContainerHighest: Color(4294041308),
    );
  }

  ThemeData lightMediumContrast() {
    return theme(lightMediumContrastScheme());
  }

  static ColorScheme lightHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(4282650635),
      surfaceTint: Color(4287646274),
      onPrimary: Color(4294967295),
      primaryContainer: Color(4285411368),
      onPrimaryContainer: Color(4294967295),
      secondary: Color(4278200108),
      onSecondary: Color(4294967295),
      secondaryContainer: Color(4278209108),
      onSecondaryContainer: Color(4294967295),
      tertiary: Color(4280490319),
      onTertiary: Color(4294967295),
      tertiaryContainer: Color(4282661746),
      onTertiaryContainer: Color(4294967295),
      error: Color(4282324480),
      onError: Color(4294967295),
      errorContainer: Color(4285215507),
      onErrorContainer: Color(4294967295),
      surface: Color(4294965495),
      onSurface: Color(4278190080),
      onSurfaceVariant: Color(4280100136),
      outline: Color(4282074183),
      outlineVariant: Color(4282074183),
      shadow: Color(4278190080),
      scrim: Color(4278190080),
      inverseSurface: Color(4281937453),
      inversePrimary: Color(4294961123),
      primaryFixed: Color(4285411368),
      onPrimaryFixed: Color(4294967295),
      primaryFixedDim: Color(4283570709),
      onPrimaryFixedVariant: Color(4294967295),
      secondaryFixed: Color(4278209108),
      onSecondaryFixed: Color(4294967295),
      secondaryFixedDim: Color(4278202937),
      onSecondaryFixedVariant: Color(4294967295),
      tertiaryFixed: Color(4282661746),
      onTertiaryFixed: Color(4294967295),
      tertiaryFixedDim: Color(4281214043),
      onTertiaryFixedVariant: Color(4294967295),
      surfaceDim: Color(4293449428),
      surfaceBright: Color(4294965495),
      surfaceContainerLowest: Color(4294967295),
      surfaceContainerLow: Color(4294963439),
      surfaceContainer: Color(4294765288),
      surfaceContainerHigh: Color(4294370530),
      surfaceContainerHighest: Color(4294041308),
    );
  }

  ThemeData lightHighContrast() {
    return theme(lightHighContrastScheme());
  }

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primaryDark,
      surfaceTint: AppColors.primaryDark,
      onPrimary: AppColors.onPrimaryDark,
      primaryContainer: AppColors.primaryContainerDark,
      onPrimaryContainer: AppColors.onPrimaryContainerDark,
      secondary: AppColors.secondaryDark,
      onSecondary: AppColors.onSecondaryDark,
      secondaryContainer: AppColors.secondaryContainerDark,
      onSecondaryContainer: AppColors.onSecondaryContainerDark,
      tertiary: AppColors.tertiaryDark,
      onTertiary: AppColors.onTertiaryDark,
      tertiaryContainer: AppColors.tertiaryContainerDark,
      onTertiaryContainer: AppColors.onTertiaryContainerDark,
      error: AppColors.pastelError,
      onError: AppColors.onPastelError,
      errorContainer: Color(0xFF4E2626),
      onErrorContainer: AppColors.pastelErrorContainer,
      surface: AppColors.backgroundDark,
      onSurface: AppColors.textPrimaryDark,
      onSurfaceVariant: AppColors.textSecondaryDark,
      outline: AppColors.borderDark,
      outlineVariant: AppColors.dividerDark,
      shadow: Color(0x33000000),
      scrim: Color(0x66000000),
      inverseSurface: AppColors.surfaceLight,
      inversePrimary: AppColors.primaryLight,
      primaryFixed: AppColors.primaryContainerLight,
      onPrimaryFixed: AppColors.onPrimaryContainerLight,
      primaryFixedDim: AppColors.primaryLight,
      onPrimaryFixedVariant: AppColors.onPrimaryContainerLight,
      secondaryFixed: AppColors.secondaryContainerLight,
      onSecondaryFixed: AppColors.onSecondaryContainerLight,
      secondaryFixedDim: AppColors.secondaryLight,
      onSecondaryFixedVariant: AppColors.onSecondaryContainerLight,
      tertiaryFixed: AppColors.tertiaryContainerLight,
      onTertiaryFixed: AppColors.onTertiaryContainerLight,
      tertiaryFixedDim: AppColors.tertiaryLight,
      onTertiaryFixedVariant: AppColors.onTertiaryContainerLight,
      surfaceDim: Color(0xFF13151A),
      surfaceBright: Color(0xFF282D38),
      surfaceContainerLowest: AppColors.surfaceDark,
      surfaceContainerLow: Color(0xFF1B1F27),
      surfaceContainer: Color(0xFF202530),
      surfaceContainerHigh: Color(0xFF262B37),
      surfaceContainerHighest: Color(0xFF2C3240),
    );
  }

  ThemeData dark() {
    return theme(darkScheme());
  }

  static ColorScheme darkMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(4294949552),
      surfaceTint: Color(4294948010),
      onPrimary: Color(4281533443),
      primaryContainer: Color(4291591024),
      onPrimaryContainer: Color(4278190080),
      secondary: Color(4287027174),
      onSecondary: Color(4278196766),
      secondaryContainer: Color(4283014314),
      onSecondaryContainer: Color(4278190080),
      tertiary: Color(4291740671),
      onTertiary: Color(4279700035),
      tertiaryContainer: Color(4287924678),
      onTertiaryContainer: Color(4278190080),
      error: Color(4294950043),
      onError: Color(4281076992),
      errorContainer: Color(4291395160),
      onErrorContainer: Color(4278190080),
      surface: Color(4279898384),
      onSurface: Color(4294965753),
      onSurfaceVariant: Color(4291022031),
      outline: Color(4288390311),
      outlineVariant: Color(4286285191),
      shadow: Color(4278190080),
      scrim: Color(4278190080),
      inverseSurface: Color(4294041308),
      inversePrimary: Color(4285805869),
      primaryFixed: Color(4294957781),
      onPrimaryFixed: Color(4281073921),
      primaryFixedDim: Color(4294948010),
      onPrimaryFixedVariant: Color(4284359709),
      secondaryFixed: Color(4288606206),
      onSecondaryFixed: Color(4278195224),
      secondaryFixedDim: Color(4286764002),
      onSecondaryFixedVariant: Color(4278205508),
      tertiaryFixed: Color(4293320447),
      onTertiaryFixed: Color(4279370814),
      tertiaryFixedDim: Color(4291477247),
      onTertiaryFixedVariant: Color(4281871973),
      surfaceDim: Color(4279898384),
      surfaceBright: Color(4282529589),
      surfaceContainerLowest: Color(4279503883),
      surfaceContainerLow: Color(4280490264),
      surfaceContainer: Color(4280753436),
      surfaceContainerHigh: Color(4281477158),
      surfaceContainerHighest: Color(4282200625),
    );
  }

  ThemeData darkMediumContrast() {
    return theme(darkMediumContrastScheme());
  }

  static ColorScheme darkHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(4294965752),
      surfaceTint: Color(4294948010),
      onPrimary: Color(4278190080),
      primaryContainer: Color(4294949552),
      onPrimaryContainer: Color(4278190080),
      secondary: Color(4294114815),
      onSecondary: Color(4278190080),
      secondaryContainer: Color(4287027174),
      onSecondaryContainer: Color(4278190080),
      tertiary: Color(4294900223),
      onTertiary: Color(4278190080),
      tertiaryContainer: Color(4291740671),
      onTertiaryContainer: Color(4278190080),
      error: Color(4294965752),
      onError: Color(4278190080),
      errorContainer: Color(4294950043),
      onErrorContainer: Color(4278190080),
      surface: Color(4279898384),
      onSurface: Color(4294967295),
      onSurfaceVariant: Color(4294180095),
      outline: Color(4291022031),
      outlineVariant: Color(4291022031),
      shadow: Color(4278190080),
      scrim: Color(4278190080),
      inverseSurface: Color(4294041308),
      inversePrimary: Color(4283308050),
      primaryFixed: Color(4294959323),
      onPrimaryFixed: Color(4278190080),
      primaryFixedDim: Color(4294949552),
      onPrimaryFixedVariant: Color(4281533443),
      secondaryFixed: Color(4289655551),
      onSecondaryFixed: Color(4278190080),
      secondaryFixedDim: Color(4287027174),
      onSecondaryFixedVariant: Color(4278196766),
      tertiaryFixed: Color(4293583871),
      onTertiaryFixed: Color(4278190080),
      tertiaryFixedDim: Color(4291740671),
      onTertiaryFixedVariant: Color(4279700035),
      surfaceDim: Color(4279898384),
      surfaceBright: Color(4282529589),
      surfaceContainerLowest: Color(4279503883),
      surfaceContainerLow: Color(4280490264),
      surfaceContainer: Color(4280753436),
      surfaceContainerHigh: Color(4281477158),
      surfaceContainerHighest: Color(4282200625),
    );
  }

  ThemeData darkHighContrast() {
    return theme(darkHighContrastScheme());
  }

  ThemeData theme(ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return ThemeData(
      useMaterial3: true,
      brightness: colorScheme.brightness,
      colorScheme: colorScheme,
      textTheme: textTheme.apply(
        bodyColor: textColor,
        displayColor: textColor,
      ),
      scaffoldBackgroundColor: colorScheme.surface,
      canvasColor: colorScheme.surface,
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.roundedLg,
          side: BorderSide(color: borderColor, width: 1.0),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.roundedXl,
          side: BorderSide(color: borderColor, width: 1.0),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: textColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.roundedMd,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: borderColor, width: 1.0),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.roundedMd,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: AppRadius.roundedMd,
          borderSide: BorderSide(color: borderColor, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.roundedMd,
          borderSide: BorderSide(color: borderColor, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.roundedMd,
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
    );
  }

  List<ExtendedColor> get extendedColors => [];
}

class ExtendedColor {
  const ExtendedColor({
    required this.seed,
    required this.value,
    required this.light,
    required this.lightHighContrast,
    required this.lightMediumContrast,
    required this.dark,
    required this.darkHighContrast,
    required this.darkMediumContrast,
  });

  final Color seed;
  final Color value;
  final ColorFamily light;
  final ColorFamily lightHighContrast;
  final ColorFamily lightMediumContrast;
  final ColorFamily dark;
  final ColorFamily darkHighContrast;
  final ColorFamily darkMediumContrast;
}

class ColorFamily {
  const ColorFamily({
    required this.color,
    required this.onColor,
    required this.colorContainer,
    required this.onColorContainer,
  });

  final Color color;
  final Color onColor;
  final Color colorContainer;
  final Color onColorContainer;
}
