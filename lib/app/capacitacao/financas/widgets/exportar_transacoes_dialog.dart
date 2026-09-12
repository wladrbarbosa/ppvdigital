import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:ppvdigital/app/capacitacao/financas/services/transaction_export_service.dart';
import 'package:ppvdigital/design_system/design_system.dart';
import 'package:ppvdigital/models/transacao_model.dart';

enum ExportFormat {
  whatsapp,
  csv,
}

enum ExportStructure {
  groupByDateWithBalance,
  totalOnly,
}

class ExportarTransacoesDialog extends StatefulWidget {
  const ExportarTransacoesDialog({
    super.key,
    required this.transactions,
    this.saldosDiarios,
    required this.currentMonth,
    this.filterSummary,
  });

  final List<TransacaoModel> transactions;
  final Map<String, double>? saldosDiarios;
  final DateTime currentMonth;
  final String? filterSummary;

  @override
  State<ExportarTransacoesDialog> createState() =>
      _ExportarTransacoesDialogState();
}

class _ExportarTransacoesDialogState extends State<ExportarTransacoesDialog> {
  ExportFormat _selectedFormat = ExportFormat.whatsapp;
  ExportStructure _selectedStructure = ExportStructure.groupByDateWithBalance;
  bool _isDownloading = false;
  final ScrollController _previewScrollController = ScrollController();

  @override
  void dispose() {
    _previewScrollController.dispose();
    super.dispose();
  }

  String _generateContent() {
    final bool isGrouped =
        _selectedStructure == ExportStructure.groupByDateWithBalance;

    if (_selectedFormat == ExportFormat.whatsapp) {
      return TransactionExportService.formatWhatsApp(
        transactions: widget.transactions,
        groupByDateWithBalance: isGrouped,
        saldosDiarios: widget.saldosDiarios,
        currentMonth: widget.currentMonth,
        filterSummary: widget.filterSummary,
      );
    } else {
      return TransactionExportService.formatCsv(
        transactions: widget.transactions,
        groupByDateWithBalance: isGrouped,
        saldosDiarios: widget.saldosDiarios,
        currentMonth: widget.currentMonth,
      );
    }
  }

  Future<void> _copyContent() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final content = _generateContent();

    messenger.showSnackBar(
      const SnackBar(
        content: Text('Copiado para a área de transferência!'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );

    await Clipboard.setData(ClipboardData(text: content));

    if (!mounted) return;
    navigator.pop();
  }

  Future<void> _downloadCsv() async {
    setState(() {
      _isDownloading = true;
    });

    final content = _generateContent();
    final monthStr = DateFormat('yyyy_MM').format(widget.currentMonth);
    final fileName = 'transacoes_$monthStr.csv';

    try {
      final path = await TransactionExportService.downloadCsvFile(
        csvContent: content,
        fileName: fileName,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            path != null && path != 'downloaded'
                ? 'Arquivo salvo em: $path'
                : 'Download do CSV iniciado!',
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar CSV: $e'),
          backgroundColor: AppColors.pastelError,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final monthName = DateFormat("MMMM 'de' yyyy", 'pt_BR').format(widget.currentMonth);
    final capitalizedMonth = monthName[0].toUpperCase() + monthName.substring(1);

    final previewContent = _generateContent();

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.roundedLg,
      ),
      titlePadding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.xs,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
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
                      ? AppColors.primaryContainerLight.withValues(alpha: 0.15)
                      : AppColors.primaryContainerLight,
                  borderRadius: AppRadius.roundedSm,
                ),
                child: Icon(
                  Icons.share_outlined,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Exportar Transações',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Fechar',
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${widget.transactions.length} transações filtradas em $capitalizedMonth',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              if (widget.filterSummary != null &&
                  widget.filterSummary!.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Filtros: ${widget.filterSummary!.trim()}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),

              // Seção: Formato
              Text(
                'Formato de exportação',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              SegmentedButton<ExportFormat>(
                segments: const [
                  ButtonSegment(
                    value: ExportFormat.whatsapp,
                    label: Text('WhatsApp'),
                    icon: Icon(Icons.chat_bubble_outline, size: 16),
                  ),
                  ButtonSegment(
                    value: ExportFormat.csv,
                    label: Text('CSV'),
                    icon: Icon(Icons.table_chart_outlined, size: 16),
                  ),
                ],
                selected: {_selectedFormat},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _selectedFormat = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Seção: Estrutura dos dados
              Text(
                'Estrutura dos dados',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              SegmentedButton<ExportStructure>(
                segments: const [
                  ButtonSegment(
                    value: ExportStructure.groupByDateWithBalance,
                    label: Text('Por data com saldo acumulado'),
                  ),
                  ButtonSegment(
                    value: ExportStructure.totalOnly,
                    label: Text('Somente transações com total'),
                  ),
                ],
                selected: {_selectedStructure},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _selectedStructure = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Seção: Pré-visualização
              Text(
                'Pré-visualização',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.backgroundDark
                      : AppColors.backgroundLight,
                  borderRadius: AppRadius.roundedMd,
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: Scrollbar(
                  controller: _previewScrollController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _previewScrollController,
                    child: SelectableText(
                      previewContent,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        height: 1.4,
                      ),
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
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        if (_selectedFormat == ExportFormat.csv) ...[
          OutlinedButton.icon(
            onPressed: _isDownloading ? null : _downloadCsv,
            icon: _isDownloading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download, size: 18),
            label: const Text('Baixar .csv'),
          ),
        ],
        FilledButton.icon(
          onPressed: _copyContent,
          icon: const Icon(Icons.copy, size: 18),
          label: const Text('Copiar'),
        ),
      ],
    );
  }
}
