import 'package:material_ui/material_ui.dart';
import 'package:ppvdigital/design_system/app_colors.dart';
import 'package:ppvdigital/design_system/app_radius.dart';
import 'package:ppvdigital/design_system/app_shadows.dart';

/// Decorações visuais padronizadas do Design System Seapruma.
/// Fornece cartões com bordas sutis, sombras suaves e badges translúcidos.
abstract final class AppDecorations {
  /// Decoração de cartão suave com leveza visual, borda delicada e sombra difusa
  static BoxDecoration card({
    bool isDark = false,
    Color? backgroundColor,
    Color? borderColor,
    BorderRadius? borderRadius,
    List<BoxShadow>? shadows,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
      borderRadius: borderRadius ?? AppRadius.roundedLg,
      border: Border.all(
        color: borderColor ?? (isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      boxShadow: shadows ?? AppShadows.card,
    );
  }

  /// Decoração de badge/tag translúcido em estilo pílula com cores pastéis
  static BoxDecoration badge({
    required Color backgroundColor,
    Color? borderColor,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: borderRadius ?? AppRadius.roundedFull,
      border: borderColor != null
          ? Border.all(color: borderColor.withValues(alpha: 0.5))
          : null,
    );
  }

  /// Decoração para campos de formulário e containers interativos
  static BoxDecoration input({
    bool isDark = false,
    bool isFocused = false,
    Color? customBorderColor,
  }) {
    final defaultBorder = isDark ? AppColors.borderDark : AppColors.borderLight;
    final focusBorder = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return BoxDecoration(
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      borderRadius: AppRadius.roundedMd,
      border: Border.all(
        color: customBorderColor ?? (isFocused ? focusBorder : defaultBorder),
        width: isFocused ? 1.5 : 1.0,
      ),
    );
  }
}
