// ignore_for_file: use_full_hex_values_for_flutter_colors

import 'package:flutter/material.dart';

class MaterialTheme {
  const MaterialTheme(this.textTheme);
  final TextTheme textTheme;

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(4287646274),
      surfaceTint: Color(4287646274),
      onPrimary: Color(4294967295),
      primaryContainer: Color(4294957781),
      onPrimaryContainer: Color(4282059014),
      secondary: Color(4278216821),
      onSecondary: Color(4294967295),
      secondaryContainer: Color(4288606206),
      onSecondaryContainer: Color(4278198052),
      tertiary: Color(4284503696),
      onTertiary: Color(4294967295),
      tertiaryContainer: Color(4293320447),
      onTertiaryContainer: Color(4280029513),
      error: Color(4287450668),
      onError: Color(4294967295),
      errorContainer: Color(4294958027),
      onErrorContainer: Color(4281602304),
      surface: Color(4294965495),
      onSurface: Color(4280490264),
      onSurfaceVariant: Color(4282337355),
      outline: Color(4285495675),
      outlineVariant: Color(4290758859),
      shadow: Color(4278190080),
      scrim: Color(4278190080),
      inverseSurface: Color(4281937453),
      inversePrimary: Color(4294948010),
      primaryFixed: Color(4294957781),
      onPrimaryFixed: Color(4282059014),
      primaryFixedDim: Color(4294948010),
      onPrimaryFixedVariant: Color(4285740076),
      secondaryFixed: Color(4288606206),
      onSecondaryFixed: Color(4278198052),
      secondaryFixedDim: Color(4286764002),
      onSecondaryFixedVariant: Color(4278210392),
      tertiaryFixed: Color(4293320447),
      onTertiaryFixed: Color(4280029513),
      tertiaryFixedDim: Color(4291477247),
      onTertiaryFixedVariant: Color(4282924919),
      surfaceDim: Color(4293449428),
      surfaceBright: Color(4294965495),
      surfaceContainerLowest: Color(4294967295),
      surfaceContainerLow: Color(4294963439),
      surfaceContainer: Color(4294765288),
      surfaceContainerHigh: Color(4294370530),
      surfaceContainerHighest: Color(4294041308),
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
      primary: Color(4294948010),
      surfaceTint: Color(4294948010),
      onPrimary: Color(4283833880),
      primaryContainer: Color(4285740076),
      onPrimaryContainer: Color(4294957781),
      secondary: Color(4286764002),
      onSecondary: Color(4278203965),
      secondaryContainer: Color(4278210392),
      onSecondaryContainer: Color(4288606206),
      tertiary: Color(4291477247),
      onTertiary: Color(4281477215),
      tertiaryContainer: Color(4282924919),
      onTertiaryContainer: Color(4293320447),
      error: Color(4294948498),
      onError: Color(4283703555),
      errorContainer: Color(4285544215),
      onErrorContainer: Color(4294958027),
      surface: Color(4279898384),
      onSurface: Color(4294041308),
      onSurfaceVariant: Color(4290758859),
      outline: Color(4287206037),
      outlineVariant: Color(4282337355),
      shadow: Color(4278190080),
      scrim: Color(4278190080),
      inverseSurface: Color(4294041308),
      inversePrimary: Color(4287646274),
      primaryFixed: Color(4294957781),
      onPrimaryFixed: Color(4282059014),
      primaryFixedDim: Color(4294948010),
      onPrimaryFixedVariant: Color(4285740076),
      secondaryFixed: Color(4288606206),
      onSecondaryFixed: Color(4278198052),
      secondaryFixedDim: Color(4286764002),
      onSecondaryFixedVariant: Color(4278210392),
      tertiaryFixed: Color(4293320447),
      onTertiaryFixed: Color(4280029513),
      tertiaryFixedDim: Color(4291477247),
      onTertiaryFixedVariant: Color(4282924919),
      surfaceDim: Color(4279898384),
      surfaceBright: Color(4282529589),
      surfaceContainerLowest: Color(4279503883),
      surfaceContainerLow: Color(4280490264),
      surfaceContainer: Color(4280753436),
      surfaceContainerHigh: Color(4281477158),
      surfaceContainerHighest: Color(4282200625),
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


  ThemeData theme(ColorScheme colorScheme) => ThemeData(
     useMaterial3: true,
     brightness: colorScheme.brightness,
     colorScheme: colorScheme,
     textTheme: textTheme.apply(
       bodyColor: colorScheme.onSurface,
       displayColor: colorScheme.onSurface,
     ),
     scaffoldBackgroundColor: colorScheme.surface,
     canvasColor: colorScheme.surface,
  );


  List<ExtendedColor> get extendedColors => [
  ];
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
