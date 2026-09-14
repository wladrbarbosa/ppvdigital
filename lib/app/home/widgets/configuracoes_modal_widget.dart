import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:intl/intl.dart';
import 'package:ppvdigital/app/home/widgets/backup_restore_dialog.dart';
import 'package:ppvdigital/controllers/backup_controller.dart';
import 'package:ppvdigital/core.dart';
import 'package:ppvdigital/design_system/design_system.dart';
import 'package:ppvdigital/models/backup/backup_payload_model.dart';
import 'package:ppvdigital/services/backup/backup_file_loader.dart';

/// Modal bottom sheet para seleção de modo de exibição (claro/escuro/sistema),
/// paletas pastéis do Design System e Backup & Restauração (Manual e Google Drive).
class ConfiguracoesModalWidget extends StatefulWidget {
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
  State<ConfiguracoesModalWidget> createState() =>
      _ConfiguracoesModalWidgetState();
}

class _ConfiguracoesModalWidgetState extends State<ConfiguracoesModalWidget> {
  @override
  void initState() {
    super.initState();
    // Inicializa leitura das configurações de backup persistidas se registrado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Core.getIt.isRegistered<BackupController>()) {
        Core.backupController.loadSettings();
      }
    });
  }

  Future<void> _handleDownloadBackup(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final backupController = Core.backupController;

    BackupRestoreDialog.showProgressDialog(
      context: context,
      title: 'Gerando Backup...',
      controller: backupController,
    );

    final filePath = await backupController.downloadManualBackup();
    final success = filePath != null;

    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          success
              ? (backupController.successMessage ?? 'Backup baixado com sucesso!')
              : (backupController.errorMessage ?? 'Falha ao baixar backup.'),
        ),
        backgroundColor:
            success ? AppColors.pastelSuccess : AppColors.pastelError,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _processRestoreJson(
    BuildContext context,
    String jsonString,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final backupController = Core.backupController;

    BackupPayloadModel payload;
    try {
      payload = BackupPayloadModel.fromJson(jsonString);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Arquivo inválido ou ilegível: $e'),
          backgroundColor: AppColors.pastelError,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final cleanFirst =
        await BackupRestoreDialog.showRestoreConfirmationDialog(
      context: context,
      payload: payload,
    );

    if (cleanFirst == null || !context.mounted) return;

    BackupRestoreDialog.showProgressDialog(
      context: context,
      title: 'Restaurando Dados...',
      controller: backupController,
    );

    final success = await backupController.restoreFromManualJson(
      jsonString,
      cleanReplace: cleanFirst,
    );

    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          success
              ? (backupController.successMessage ??
                  'Dados restaurados com sucesso!')
              : (backupController.errorMessage ??
                  'Falha ao restaurar dados.'),
        ),
        backgroundColor:
            success ? AppColors.pastelSuccess : AppColors.pastelError,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleManualRestore(BuildContext context) async {
    // Oferece opções: Selecionar arquivo JSON ou colar texto
    final option = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
        final surfaceColor =
            isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
        final textColor =
            isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
        final textSecondary =
            isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

        return Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl),
            ),
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Restaurar Backup Manual',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Como você deseja carregar o arquivo de backup?',
                style: TextStyle(fontSize: 12, color: textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                leading: const Icon(Icons.file_open_outlined),
                title: const Text('Selecionar arquivo do dispositivo (.json)'),
                subtitle: const Text('Carregar arquivo salvo anteriormente'),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.roundedMd,
                ),
                onTap: () => Navigator.of(sheetContext).pop('file'),
              ),
              ListTile(
                leading: const Icon(Icons.paste_outlined),
                title: const Text('Colar texto JSON manualmente'),
                subtitle: const Text('Ideal para colar dados copiados'),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.roundedMd,
                ),
                onTap: () => Navigator.of(sheetContext).pop('paste'),
              ),
            ],
          ),
        );
      },
    );

    if (option == null || !context.mounted) return;

    if (option == 'file') {
      final jsonContent = await pickJsonFile();
      if (jsonContent != null && context.mounted) {
        await _processRestoreJson(context, jsonContent);
      }
    } else if (option == 'paste' && context.mounted) {
      await BackupRestoreDialog.showPasteJsonDialog(
        context: context,
        onConfirm: (content) async {
          if (context.mounted) {
            await _processRestoreJson(context, content);
          }
        },
      );
    }
  }

  Future<void> _handleUploadGoogleDrive(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final backupController = Core.backupController;

    BackupRestoreDialog.showProgressDialog(
      context: context,
      title: 'Enviando ao Google Drive...',
      controller: backupController,
    );

    final success = await backupController.uploadBackupToGoogleDrive();

    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          success
              ? (backupController.successMessage ??
                  'Backup salvo no Google Drive com sucesso!')
              : (backupController.errorMessage ??
                  'Falha ao enviar backup para o Google Drive.'),
        ),
        backgroundColor:
            success ? AppColors.pastelSuccess : AppColors.pastelError,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleRestoreFromGoogleDrive(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final backupController = Core.backupController;

    await BackupRestoreDialog.showDriveBackupsDialog(
      context: context,
      controller: backupController,
      onSelect: (item, cleanFirst) async {
        BackupRestoreDialog.showProgressDialog(
          context: context,
          title: 'Restaurando do Google Drive...',
          controller: backupController,
        );

        final success = await backupController.restoreFromGoogleDrive(
          item.id ?? '',
          cleanReplace: cleanFirst,
        );

        if (!context.mounted) return;
        Navigator.of(context, rootNavigator: true).pop();

        messenger.showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? (backupController.successMessage ??
                      'Dados restaurados com sucesso do Google Drive!')
                  : (backupController.errorMessage ??
                      'Falha ao restaurar do Google Drive.'),
            ),
            backgroundColor:
                success ? AppColors.pastelSuccess : AppColors.pastelError,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  Future<void> _handleConnectGoogleDrive(BuildContext context) async {
    if (!Core.getIt.isRegistered<BackupController>()) return;
    final messenger = ScaffoldMessenger.of(context);
    final backupController = Core.backupController;

    // Se o Client ID não estiver configurado, solicita ao usuário via diálogo amigável
    if (!backupController.hasGoogleClientId) {
      final enteredId = await BackupRestoreDialog.showGoogleClientIdDialog(
        context: context,
        initialValue: backupController.googleClientId,
      );
      if (enteredId == null || enteredId.trim().isEmpty) {
        return; // Usuário cancelou ou não preencheu
      }

      final success = await backupController.connectGoogleDrive(
        clientId: enteredId.trim(),
      );

      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            success
                ? (backupController.successMessage ??
                    'Conectado ao Google Drive com sucesso!')
                : (backupController.errorMessage ??
                    'Falha ao conectar ao Google Drive.'),
          ),
          backgroundColor:
              success ? AppColors.pastelSuccess : AppColors.pastelError,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Já possui Client ID configurado: conecta diretamente
    final success = await backupController.connectGoogleDrive();
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          success
              ? (backupController.successMessage ??
                  'Conectado ao Google Drive com sucesso!')
              : (backupController.errorMessage ??
                  'Falha ao conectar ao Google Drive.'),
        ),
        backgroundColor:
            success ? AppColors.pastelSuccess : AppColors.pastelError,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleDisconnectGoogleDrive(BuildContext context) async {
    if (!Core.getIt.isRegistered<BackupController>()) return;
    final messenger = ScaffoldMessenger.of(context);
    final backupController = Core.backupController;

    await backupController.disconnectGoogleDrive();
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          backupController.successMessage ?? 'Google Drive desconectado.',
        ),
        backgroundColor: AppColors.pastelSuccess,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    try {
      return DateFormat("dd/MM/yyyy 'às' HH:mm", 'pt_BR').format(dt);
    } catch (_) {
      final d = dt.day.toString().padLeft(2, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final y = dt.year;
      final h = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$d/$m/$y às $h:$min';
    }
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
    final cardBgColor =
        isDark ? AppColors.surfaceDark : AppColors.backgroundLight;

    return Observer(
      builder: (_) {
        final currentMode = Core.themeController.themeMode;
        final currentPalette = Core.themeController.palette;
        final backupController = Core.getIt.isRegistered<BackupController>()
            ? Core.backupController
            : null;

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.90,
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
                            'Personalize aparência, paleta e gerencie backups',
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

                      if (backupController != null) ...[
                        const SizedBox(height: AppSpacing.xl),

                        // Seção 3: Backup e Restauração de Dados
                      Row(
                        children: [
                          Icon(
                            Icons.cloud_sync_outlined,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'Backup e Restauração de Dados',
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
                        'Exporte seus dados com segurança ou ative a sincronização com o Google Drive',
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondaryColor,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.mdSm),

                      // Card: Backup Manual
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: cardBgColor,
                          borderRadius: AppRadius.roundedLg,
                          border: Border.all(color: borderColor),
                          boxShadow: AppShadows.soft,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(AppSpacing.xs),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.primaryContainerDark.withValues(
                                            alpha: 0.2,
                                          )
                                        : AppColors.primaryContainerLight,
                                    borderRadius: AppRadius.roundedSm,
                                  ),
                                  child: Icon(
                                    Icons.file_download_outlined,
                                    size: 18,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Backup Manual (.json)',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                      Text(
                                        'Exportação completa de contas, transações e tarefas',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: textSecondaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: backupController.isBackingUp ||
                                            backupController.isRestoring
                                        ? null
                                        : () => _handleDownloadBackup(context),
                                    icon: const Icon(
                                      Icons.download_rounded,
                                      size: 16,
                                    ),
                                    label: const Text('Exportar Arquivo'),
                                    style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: AppRadius.roundedMd,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: backupController.isBackingUp ||
                                            backupController.isRestoring
                                        ? null
                                        : () => _handleManualRestore(context),
                                    icon: const Icon(
                                      Icons.upload_file_rounded,
                                      size: 16,
                                    ),
                                    label: const Text('Restaurar Arquivo'),
                                    style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: AppRadius.roundedMd,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Card: Integração Google Drive
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: cardBgColor,
                          borderRadius: AppRadius.roundedLg,
                          border: Border.all(color: borderColor),
                          boxShadow: AppShadows.soft,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(AppSpacing.xs),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.secondaryContainerDark.withValues(
                                            alpha: 0.2,
                                          )
                                        : AppColors.secondaryContainerLight,
                                    borderRadius: AppRadius.roundedSm,
                                  ),
                                  child: Icon(
                                    Icons.add_to_drive_outlined,
                                    size: 18,
                                    color: isDark
                                        ? AppColors.secondaryDark
                                        : AppColors.secondaryLight,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Google Drive',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                      Text(
                                        backupController.isGoogleConnected
                                            ? 'Conectado como ${backupController.googleUserEmail ?? 'Google User'}'
                                            : 'Não conectado ao Google Drive',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: backupController.isGoogleConnected
                                              ? AppColors.onPastelSuccessContainer
                                              : textSecondaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (backupController.isGoogleConnected)
                                  TextButton.icon(
                                    onPressed: backupController.isLoading
                                        ? null
                                        : () => _handleDisconnectGoogleDrive(
                                            context),
                                    icon: const Icon(
                                      Icons.logout_rounded,
                                      size: 14,
                                    ),
                                    label: const Text(
                                      'Desconectar',
                                      style: TextStyle(fontSize: 11),
                                    ),
                                  )
                                else ...[
                                  IconButton(
                                    tooltip: 'Configurar Google Client ID',
                                    icon: const Icon(
                                      Icons.settings_outlined,
                                      size: 16,
                                    ),
                                    onPressed: () async {
                                      final enteredId =
                                          await BackupRestoreDialog
                                              .showGoogleClientIdDialog(
                                        context: context,
                                        initialValue:
                                            backupController.googleClientId,
                                      );
                                      if (enteredId != null &&
                                          enteredId.trim().isNotEmpty) {
                                        await backupController
                                            .setGoogleClientId(enteredId.trim());
                                      }
                                    },
                                  ),
                                  FilledButton.tonalIcon(
                                    onPressed: (backupController.isLoading ||
                                            backupController.isBackingUp ||
                                            backupController.isRestoring)
                                        ? null
                                        : () =>
                                            _handleConnectGoogleDrive(context),
                                    icon: backupController.isLoading
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.login_rounded,
                                            size: 14,
                                          ),
                                    label: Text(
                                      backupController.isLoading
                                          ? 'Conectando...'
                                          : 'Conectar',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.sm,
                                        vertical: AppSpacing.xs,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: AppRadius.roundedMd,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const Divider(height: AppSpacing.lg),

                            // Switch de Backup Automático Diário
                            Material(
                              type: MaterialType.transparency,
                              child: SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                value: backupController.isAutoBackupEnabled,
                                onChanged: backupController.isGoogleConnected
                                    ? (val) => backupController
                                        .setAutoBackupEnabled(val)
                                    : null,
                                title: Text(
                                  'Backup Automático Diário',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: backupController.isGoogleConnected
                                        ? textColor
                                        : textSecondaryColor,
                                  ),
                                ),
                                subtitle: Text(
                                  backupController.lastBackupTime != null
                                      ? 'Último envio: ${_formatDateTime(backupController.lastBackupTime!)}'
                                      : (backupController.isGoogleConnected
                                          ? 'Sincroniza automaticamente a cada 24h'
                                          : 'Conecte o Google Drive para habilitar'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: textSecondaryColor,
                                  ),
                                ),
                              ),
                            ),

                            if (backupController.isGoogleConnected) ...[
                              const SizedBox(height: AppSpacing.xs),
                              Row(
                                children: [
                                  Expanded(
                                    child: FilledButton.icon(
                                      onPressed: backupController.isBackingUp ||
                                              backupController.isRestoring
                                          ? null
                                          : () => _handleUploadGoogleDrive(
                                              context),
                                      icon: const Icon(
                                        Icons.cloud_upload_outlined,
                                        size: 16,
                                      ),
                                      label: const Text('Fazer Backup Agora'),
                                      style: FilledButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: AppRadius.roundedMd,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: backupController.isBackingUp ||
                                              backupController.isRestoring
                                          ? null
                                          : () => _handleRestoreFromGoogleDrive(
                                              context),
                                      icon: const Icon(
                                        Icons.cloud_download_outlined,
                                        size: 16,
                                      ),
                                      label: const Text('Restaurar do Drive'),
                                      style: OutlinedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: AppRadius.roundedMd,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],

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
