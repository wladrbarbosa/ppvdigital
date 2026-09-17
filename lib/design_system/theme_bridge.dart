import 'package:flutter/material.dart' as flutter_material;
import 'package:material_ui/material_ui.dart' as m_ui;
import 'package:ppvdigital/design_system/app_colors.dart';
import 'package:syncfusion_flutter_core/theme.dart' as sf_theme;

/// Ponte de integração entre o ecossistema modular `package:material_ui`
/// e bibliotecas legadas ou de terceiros (como `syncfusion_flutter_calendar`)
/// que consultam `Theme.of(context)` de `package:flutter/material.dart`.
abstract final class ThemeBridge {
  /// Converte um [m_ui.ThemeData] em [flutter_material.ThemeData] equivalente,
  /// garantindo que widgets que usam `package:flutter/material.dart`
  /// herdem com precisão cores, brilho, modo escuro e tipografia do Design System.
  static flutter_material.ThemeData toFlutterMaterialTheme(
    m_ui.ThemeData uiTheme,
  ) {
    final uiColorScheme = uiTheme.colorScheme;
    final flutterColorScheme = flutter_material.ColorScheme(
      brightness: uiColorScheme.brightness,
      primary: uiColorScheme.primary,
      onPrimary: uiColorScheme.onPrimary,
      primaryContainer: uiColorScheme.primaryContainer,
      onPrimaryContainer: uiColorScheme.onPrimaryContainer,
      secondary: uiColorScheme.secondary,
      onSecondary: uiColorScheme.onSecondary,
      secondaryContainer: uiColorScheme.secondaryContainer,
      onSecondaryContainer: uiColorScheme.onSecondaryContainer,
      tertiary: uiColorScheme.tertiary,
      onTertiary: uiColorScheme.onTertiary,
      tertiaryContainer: uiColorScheme.tertiaryContainer,
      onTertiaryContainer: uiColorScheme.onTertiaryContainer,
      error: uiColorScheme.error,
      onError: uiColorScheme.onError,
      errorContainer: uiColorScheme.errorContainer,
      onErrorContainer: uiColorScheme.onErrorContainer,
      surface: uiColorScheme.surface,
      onSurface: uiColorScheme.onSurface,
      onSurfaceVariant: uiColorScheme.onSurfaceVariant,
      outline: uiColorScheme.outline,
      outlineVariant: uiColorScheme.outlineVariant,
      shadow: uiColorScheme.shadow,
      scrim: uiColorScheme.scrim,
      inverseSurface: uiColorScheme.inverseSurface,
      inversePrimary: uiColorScheme.inversePrimary,
      surfaceDim: uiColorScheme.surfaceDim,
      surfaceBright: uiColorScheme.surfaceBright,
      surfaceContainerLowest: uiColorScheme.surfaceContainerLowest,
      surfaceContainerLow: uiColorScheme.surfaceContainerLow,
      surfaceContainer: uiColorScheme.surfaceContainer,
      surfaceContainerHigh: uiColorScheme.surfaceContainerHigh,
      surfaceContainerHighest: uiColorScheme.surfaceContainerHighest,
    );

    final uiTextTheme = uiTheme.textTheme;
    final flutterTextTheme = flutter_material.TextTheme(
      displayLarge: uiTextTheme.displayLarge,
      displayMedium: uiTextTheme.displayMedium,
      displaySmall: uiTextTheme.displaySmall,
      headlineLarge: uiTextTheme.headlineLarge,
      headlineMedium: uiTextTheme.headlineMedium,
      headlineSmall: uiTextTheme.headlineSmall,
      titleLarge: uiTextTheme.titleLarge,
      titleMedium: uiTextTheme.titleMedium,
      titleSmall: uiTextTheme.titleSmall,
      bodyLarge: uiTextTheme.bodyLarge,
      bodyMedium: uiTextTheme.bodyMedium,
      bodySmall: uiTextTheme.bodySmall,
      labelLarge: uiTextTheme.labelLarge,
      labelMedium: uiTextTheme.labelMedium,
      labelSmall: uiTextTheme.labelSmall,
    );

    return flutter_material.ThemeData(
      useMaterial3: true,
      brightness: uiTheme.brightness,
      colorScheme: flutterColorScheme,
      scaffoldBackgroundColor: uiTheme.scaffoldBackgroundColor,
      canvasColor: uiTheme.canvasColor,
      textTheme: flutterTextTheme,
    );
  }

  /// Gera um [sf_theme.SfCalendarThemeData] sintonizado com o Design System
  /// Pastel & Leveza, utilizando os tokens semânticos e tipográficos ativos no contexto.
  static sf_theme.SfCalendarThemeData createSfCalendarTheme(
    m_ui.BuildContext context,
  ) {
    final uiTheme = m_ui.Theme.of(context);
    final isDark = uiTheme.brightness == m_ui.Brightness.dark;
    final primaryColor = uiTheme.colorScheme.primary;
    final onPrimaryColor = uiTheme.colorScheme.onPrimary;
    final textTheme = uiTheme.textTheme;

    final headerTextStyle = (textTheme.titleMedium ?? const m_ui.TextStyle())
        .copyWith(
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          fontWeight: m_ui.FontWeight.bold,
        );

    final viewHeaderDayTextStyle =
        (textTheme.bodySmall ?? const m_ui.TextStyle()).copyWith(
          color:
              isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          fontWeight: m_ui.FontWeight.w600,
        );

    final viewHeaderDateTextStyle =
        (textTheme.titleSmall ?? const m_ui.TextStyle()).copyWith(
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          fontWeight: m_ui.FontWeight.bold,
        );

    final timeTextStyle = (textTheme.labelSmall ?? const m_ui.TextStyle())
        .copyWith(
          color:
              isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        );

    final todayTextStyle = (textTheme.titleSmall ?? const m_ui.TextStyle())
        .copyWith(color: onPrimaryColor, fontWeight: m_ui.FontWeight.bold);

    final activeDatesTextStyle =
        (textTheme.bodyMedium ?? const m_ui.TextStyle()).copyWith(
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        );

    final trailingLeadingDatesTextStyle =
        (textTheme.bodyMedium ?? const m_ui.TextStyle()).copyWith(
          color: (isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight)
              .withValues(alpha: 0.38),
        );

    return sf_theme.SfCalendarThemeData(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      headerBackgroundColor:
          isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      headerTextStyle: headerTextStyle,
      viewHeaderBackgroundColor:
          isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      viewHeaderDayTextStyle: viewHeaderDayTextStyle,
      viewHeaderDateTextStyle: viewHeaderDateTextStyle,
      timeTextStyle: timeTextStyle,
      todayHighlightColor: primaryColor,
      todayTextStyle: todayTextStyle,
      cellBorderColor: isDark ? AppColors.borderDark : AppColors.borderLight,
      selectionBorderColor: primaryColor,
      agendaBackgroundColor:
          isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      agendaDayTextStyle: viewHeaderDayTextStyle,
      agendaDateTextStyle: viewHeaderDateTextStyle,
      activeDatesTextStyle: activeDatesTextStyle,
      trailingDatesTextStyle: trailingLeadingDatesTextStyle,
      leadingDatesTextStyle: trailingLeadingDatesTextStyle,
    );
  }
}
