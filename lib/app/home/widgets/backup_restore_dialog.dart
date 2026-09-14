import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:intl/intl.dart';
import 'package:ppvdigital/controllers/backup_controller.dart';
import 'package:ppvdigital/core.dart';
import 'package:ppvdigital/design_system/design_system.dart';
import 'package:ppvdigital/models/backup/backup_payload_model.dart';
import 'package:ppvdigital/services/backup/google_drive_backup_service.dart';

/// Diálogos auxiliares para resumo, progresso e confirmação de Backup e Restauração.
class BackupRestoreDialog {
  /// Exibe diálogo modal de progresso em tempo real durante backup ou restauração.
  static Future<void> showProgressDialog({
    required BuildContext context,
    required String title,
    required BackupController controller,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
        final textColor = isDark
            ? AppColors.textPrimaryDark
            : AppColors.textPrimaryLight;
        final textSecondary = isDark
            ? AppColors.textSecondaryDark
            : AppColors.textSecondaryLight;
        final surfaceColor = isDark
            ? AppColors.surfaceDark
            : AppColors.surfaceLight;

        return PopScope(
          canPop: false,
          child: AlertDialog(
            backgroundColor: surfaceColor,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedLg),
            title: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            content: Observer(
              builder: (_) {
                final progress = controller.progressValue;
                final message = controller.progressMessage;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LinearProgressIndicator(
                      value: (progress != null && progress > 0.0)
                          ? progress
                          : null,
                      backgroundColor: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(dialogContext).colorScheme.primary,
                      ),
                      borderRadius: AppRadius.roundedFull,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      message.isNotEmpty ? message : 'Processando dados...',
                      style: TextStyle(fontSize: 13, color: textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Por favor, aguarde e não feche o aplicativo.',
                      style: TextStyle(
                        fontSize: 11,
                        color: textSecondary.withValues(alpha: 0.8),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  /// Exibe diálogo com o resumo do backup antes de confirmar a restauração.
  static Future<bool?> showRestoreConfirmationDialog({
    required BuildContext context,
    required BackupPayloadModel payload,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
        final textColor = isDark
            ? AppColors.textPrimaryDark
            : AppColors.textPrimaryLight;
        final textSecondary = isDark
            ? AppColors.textSecondaryDark
            : AppColors.textSecondaryLight;
        final surfaceColor = isDark
            ? AppColors.surfaceDark
            : AppColors.surfaceLight;
        final borderColor = isDark
            ? AppColors.borderDark
            : AppColors.borderLight;

        final currentUserEmail = Core.loginController.email;
        final isDifferentUser =
            currentUserEmail != null &&
            currentUserEmail.isNotEmpty &&
            payload.userEmail.isNotEmpty &&
            currentUserEmail.toLowerCase() != payload.userEmail.toLowerCase();

        final formattedDate = _formatDateTime(payload.exportedAt);

        final contasCount = (payload.data['contas'] as List?)?.length ?? 0;
        final contatosCount = (payload.data['contatos'] as List?)?.length ?? 0;
        final transacoesCount =
            (payload.data['transacoes'] as List?)?.length ?? 0;
        final tarefasCount =
            (payload.data['tarefasEHabitos'] as List?)?.length ?? 0;
        final historicoCount =
            (payload.data['historicoTarefasHabitos'] as List?)?.length ?? 0;
        final categoriasCount =
            ((payload.data['categoriasTransacoes'] as List?)?.length ?? 0) +
            ((payload.data['categoriasTarefasHabitos'] as List?)?.length ?? 0);

        bool cleanFirst = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: surfaceColor,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedLg),
              titlePadding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xs,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              actionsPadding: const EdgeInsets.all(AppSpacing.md),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.primaryContainerLight.withValues(
                              alpha: 0.2,
                            )
                          : AppColors.primaryContainerLight,
                      borderRadius: AppRadius.roundedSm,
                    ),
                    child: Icon(
                      Icons.restore_page_rounded,
                      color: Theme.of(dialogContext).colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Confirmar Restauração',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (isDifferentUser) ...[
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.pastelWarningContainer,
                            borderRadius: AppRadius.roundedMd,
                            border: Border.all(color: AppColors.pastelWarning),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: AppColors.onPastelWarningContainer,
                                size: 20,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  'Atenção: Este backup pertence a "${payload.userEmail}", mas você está conectado como "$currentUserEmail".',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.onPastelWarningContainer,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],

                      Text(
                        'Detalhes do Backup',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),

                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.surfaceDark
                              : AppColors.backgroundLight,
                          borderRadius: AppRadius.roundedMd,
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          children: [
                            _buildSummaryRow(
                              'Data do Backup',
                              formattedDate,
                              textColor,
                              textSecondary,
                            ),
                            const Divider(height: AppSpacing.sm),
                            _buildSummaryRow(
                              'Total de Entidades',
                              '${payload.summary.totalRecords}',
                              textColor,
                              textSecondary,
                            ),
                            const Divider(height: AppSpacing.sm),
                            _buildSummaryRow(
                              'Transações',
                              '$transacoesCount',
                              textColor,
                              textSecondary,
                            ),
                            const Divider(height: AppSpacing.sm),
                            _buildSummaryRow(
                              'Contas Financeiras',
                              '$contasCount',
                              textColor,
                              textSecondary,
                            ),
                            const Divider(height: AppSpacing.sm),
                            _buildSummaryRow(
                              'Tarefas e Hábitos',
                              '$tarefasCount',
                              textColor,
                              textSecondary,
                            ),
                            const Divider(height: AppSpacing.sm),
                            _buildSummaryRow(
                              'Histórico de Execuções',
                              '$historicoCount',
                              textColor,
                              textSecondary,
                            ),
                            const Divider(height: AppSpacing.sm),
                            _buildSummaryRow(
                              'Categorias (Total)',
                              '$categoriasCount',
                              textColor,
                              textSecondary,
                            ),
                            const Divider(height: AppSpacing.sm),
                            _buildSummaryRow(
                              'Contatos',
                              '$contatosCount',
                              textColor,
                              textSecondary,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Opção de substituição limpa vs mesclagem
                      Text(
                        'Modo de Restauração',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),

                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: AppRadius.roundedMd,
                          onTap: () {
                            setState(() {
                              cleanFirst = !cleanFirst;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: cleanFirst
                                  ? AppColors.pastelErrorContainer.withValues(
                                      alpha: 0.3,
                                    )
                                  : isDark
                                  ? AppColors.surfaceDark
                                  : AppColors.backgroundLight,
                              borderRadius: AppRadius.roundedMd,
                              border: Border.all(
                                color: cleanFirst
                                    ? AppColors.pastelError
                                    : borderColor,
                              ),
                            ),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: cleanFirst,
                                  onChanged: (val) {
                                    setState(() {
                                      cleanFirst = val ?? false;
                                    });
                                  },
                                  activeColor: AppColors.pastelError,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Substituição Limpa (Limpar antes de restaurar)',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: cleanFirst
                                              ? AppColors.pastelError
                                              : textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        cleanFirst
                                            ? 'Remove os dados atuais do banco antes de inserir os dados do backup.'
                                            : 'Modo padrão: Atualiza registros existentes e insere novos sem apagar outros.',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(color: textSecondary),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => Navigator.of(dialogContext).pop(cleanFirst),
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('Restaurar Agora'),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.roundedMd,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Exibe diálogo para listar e selecionar backups armazenados no Google Drive.
  static Future<void> showDriveBackupsDialog({
    required BuildContext context,
    required BackupController controller,
    required Future<void> Function(DriveBackupItem item, bool cleanReplace)
    onSelect,
  }) {
    // Dispara recarregamento da lista de backups no Drive
    controller.fetchDriveBackups();

    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
        final textColor = isDark
            ? AppColors.textPrimaryDark
            : AppColors.textPrimaryLight;
        final textSecondary = isDark
            ? AppColors.textSecondaryDark
            : AppColors.textSecondaryLight;
        final surfaceColor = isDark
            ? AppColors.surfaceDark
            : AppColors.surfaceLight;

        return AlertDialog(
          backgroundColor: surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedLg),
          titlePadding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.xs,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          actionsPadding: const EdgeInsets.all(AppSpacing.md),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.primaryContainerLight.withValues(
                              alpha: 0.2,
                            )
                          : AppColors.primaryContainerLight,
                      borderRadius: AppRadius.roundedSm,
                    ),
                    child: Icon(
                      Icons.cloud_download_outlined,
                      color: Theme.of(dialogContext).colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Backups no Google Drive',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
            ],
          ),
          content: SizedBox(
            width: 520,
            height: 360,
            child: Observer(
              builder: (_) {
                if (controller.driveBackupsLoading) {
                  return const SizedBox(
                    height: 180,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final backups = controller.driveBackups;
                if (backups.isEmpty) {
                  return SizedBox(
                    height: 140,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.cloud_off_rounded,
                            size: 36,
                            color: textSecondary,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Nenhum backup encontrado no Google Drive.',
                            style: TextStyle(
                              fontSize: 13,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: backups.length,
                  separatorBuilder: (_, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = backups[index];
                    final dateStr = item.createdTime != null
                        ? _formatDateTime(item.createdTime!)
                        : 'Data desconhecida';

                    final sizeBytes = int.tryParse(item.size ?? '');
                    final sizeKb = sizeBytes != null
                        ? (sizeBytes / 1024).toStringAsFixed(1)
                        : null;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: AppSpacing.xxs,
                      ),
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: isDark
                            ? AppColors.primaryContainerLight.withValues(
                                alpha: 0.15,
                              )
                            : AppColors.primaryContainerLight,
                        child: Icon(
                          Icons.insert_drive_file_outlined,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      title: Text(
                        item.name ?? 'Backup',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        sizeKb != null ? '$dateStr • $sizeKb KB' : dateStr,
                        style: TextStyle(fontSize: 11, color: textSecondary),
                      ),
                      trailing: FilledButton.tonal(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.roundedMd,
                          ),
                        ),
                        onPressed: () async {
                          Navigator.of(dialogContext).pop();
                          // Pergunta confirmação de restauração
                          final cleanReplace = await showDialog<bool>(
                            context: context,
                            builder: (confirmCtx) => AlertDialog(
                              backgroundColor: surfaceColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: AppRadius.roundedLg,
                              ),
                              title: Text(
                                'Restaurar este arquivo?',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              content: Text(
                                'Deseja restaurar "${item.name ?? 'este arquivo'}"?',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: textSecondary,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(confirmCtx).pop(),
                                  child: Text(
                                    'Cancelar',
                                    style: TextStyle(color: textSecondary),
                                  ),
                                ),
                                OutlinedButton(
                                  onPressed: () =>
                                      Navigator.of(confirmCtx).pop(false),
                                  child: const Text('Mesclar (Padrão)'),
                                ),
                                FilledButton(
                                  onPressed: () =>
                                      Navigator.of(confirmCtx).pop(true),
                                  child: const Text('Substituição Limpa'),
                                ),
                              ],
                            ),
                          );

                          if (cleanReplace != null) {
                            await onSelect(item, cleanReplace);
                          }
                        },
                        child: const Text(
                          'Restaurar',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Fechar', style: TextStyle(color: textSecondary)),
            ),
          ],
        );
      },
    );
  }

  /// Exibe diálogo para colar manualmente o conteúdo JSON do backup caso o usuário prefira.
  static Future<void> showPasteJsonDialog({
    required BuildContext context,
    required Future<void> Function(String jsonContent) onConfirm,
  }) {
    final textController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
        final textColor = isDark
            ? AppColors.textPrimaryDark
            : AppColors.textPrimaryLight;
        final textSecondary = isDark
            ? AppColors.textSecondaryDark
            : AppColors.textSecondaryLight;
        final surfaceColor = isDark
            ? AppColors.surfaceDark
            : AppColors.surfaceLight;
        final borderColor = isDark
            ? AppColors.borderDark
            : AppColors.borderLight;

        String? errorMessage;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: surfaceColor,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedLg),
              title: Text(
                'Colar Conteúdo JSON do Backup',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 500,
                  maxHeight: 300,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Cole abaixo o texto JSON completo do seu arquivo de backup exportado anteriormente.',
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Expanded(
                      child: TextField(
                        controller: textController,
                        maxLines: null,
                        expands: true,
                        style: TextStyle(fontSize: 12, color: textColor),
                        decoration: InputDecoration(
                          hintText: '{\n  "version": 1,\n  ...\n}',
                          errorText: errorMessage,
                          border: OutlineInputBorder(
                            borderRadius: AppRadius.roundedMd,
                            borderSide: BorderSide(color: borderColor),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(color: textSecondary),
                  ),
                ),
                FilledButton(
                  onPressed: () async {
                    final text = textController.text.trim();
                    if (text.isEmpty) {
                      setState(() {
                        errorMessage = 'Por favor, informe o conteúdo JSON.';
                      });
                      return;
                    }
                    try {
                      jsonDecode(text);
                    } catch (_) {
                      setState(() {
                        errorMessage = 'Conteúdo JSON inválido.';
                      });
                      return;
                    }

                    Navigator.of(dialogContext).pop();
                    await onConfirm(text);
                  },
                  child: const Text('Carregar e Analisar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static Widget _buildSummaryRow(
    String label,
    String value,
    Color textColor,
    Color secondaryColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: secondaryColor)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDateTime(DateTime dt) {
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
}
