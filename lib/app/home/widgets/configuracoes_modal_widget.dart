import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:ppvdigital/core.dart';
import 'package:ppvdigital/design_system/design_system.dart';

/// Modal bottom sheet para seleção de modo de exibição (claro/escuro/sistema)
/// e das 10 paletas pastéis oficiais do Design System do Seapruma.
class ConfiguracoesModalWidget extends StatelessWidget {
  const ConfiguracoesModalWidget({super.key});

  /// Exibe o modal bottom sheet de configurações formatado com tokens do Design System.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ConfiguracoesModalWidget(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondaryColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Observer(
      builder: (_) {
        final currentMode = Core.themeController.themeMode;
        final currentPalette = Core.themeController.palette;

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
            maxWidth: 600,
          ),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl),
            ),
            border: Border(
              top: BorderSide(color: borderColor),
              left: BorderSide(color: borderColor),
              right: BorderSide(color: borderColor),
            ),
            boxShadow: AppShadows.floating,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Barra de arrasto no topo
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: AppSpacing.sm),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: textSecondaryColor.withValues(alpha: 0.3),
                    borderRadius: AppRadius.roundedFull,
                  ),
                ),
              ),

              // Cabeçalho
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.mdSm,
                  AppSpacing.sm,
                  AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Configurações',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            'Personalize a aparência e cores do aplicativo',
                            style: TextStyle(
                              fontSize: 12,
                              color: textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: textSecondaryColor),
                      tooltip: 'Fechar',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Conteúdo rolável
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Seção 1: Modo de Exibição
                      Row(
                        children: [
                          Icon(
                            Icons.brightness_6_outlined,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'Modo de Exibição',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment<ThemeMode>(
                            value: ThemeMode.light,
                            label: Text('Claro'),
                            icon: Icon(Icons.light_mode_outlined),
                          ),
                          ButtonSegment<ThemeMode>(
                            value: ThemeMode.dark,
                            label: Text('Escuro'),
                            icon: Icon(Icons.dark_mode_outlined),
                          ),
                          ButtonSegment<ThemeMode>(
                            value: ThemeMode.system,
                            label: Text('Sistema'),
                            icon: Icon(Icons.brightness_auto_outlined),
                          ),
                        ],
                        selected: {currentMode},
                        onSelectionChanged: (newSelection) {
                          if (newSelection.isNotEmpty) {
                            Core.themeController.setThemeMode(newSelection.first);
                          }
                        },
                        style: ButtonStyle(
                          shape: WidgetStatePropertyAll(
                            RoundedRectangleBorder(
                              borderRadius: AppRadius.roundedLg,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Seção 2: Paletas do Design System
                      Row(
                        children: [
                          Icon(
                            Icons.palette_outlined,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'Paleta Pastel do Design System',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                            'Selecione o tom pastel principal de destaque para todo o app',
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondaryColor,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.mdSm),

                      // Grade das 10 Paletas
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: AppThemePalette.values.length,
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 260,
                          mainAxisExtent: 64,
                          crossAxisSpacing: AppSpacing.sm,
                          mainAxisSpacing: AppSpacing.sm,
                        ),
                        itemBuilder: (context, index) {
                          final palette = AppThemePalette.values[index];
                          final isSelected = currentPalette == palette;
                          final displayColor =
                              isDark ? palette.primaryDark : palette.primaryLight;
                          final containerColor = isDark
                              ? palette.primaryContainerDark
                              : palette.primaryContainerLight;

                          return Material(
                            color: isSelected
                                ? containerColor.withValues(alpha: 0.6)
                                : surfaceColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.roundedLg,
                              side: BorderSide(
                                color: isSelected
                                    ? displayColor
                                    : borderColor,
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: InkWell(
                              borderRadius: AppRadius.roundedLg,
                              onTap: () {
                                Core.themeController.setPalette(palette);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.mdSm,
                                  vertical: AppSpacing.xs,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: displayColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isDark
                                              ? Colors.white24
                                              : Colors.black12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Text(
                                        palette.label,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? (isDark
                                                  ? palette.onPrimaryContainerDark
                                                  : palette.onPrimaryContainerLight)
                                              : textColor,
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(
                                        Icons.check_circle_rounded,
                                        size: 18,
                                        color: displayColor,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
