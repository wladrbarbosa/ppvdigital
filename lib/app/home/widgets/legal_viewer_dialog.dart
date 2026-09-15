import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ppvdigital/design_system/design_system.dart';
import 'package:url_launcher/url_launcher.dart';

/// Diálogo e visualizador in-app para a Política de Privacidade e os Termos de Serviço
/// do Seapruma, integrado ao Design System Pastel e com opção de abrir versão web.
class LegalViewerDialog extends StatelessWidget {
  const LegalViewerDialog({
    super.key,
    required this.title,
    required this.subtitle,
    required this.webUrl,
    required this.sections,
  });

  final String title;
  final String subtitle;
  final String webUrl;
  final List<LegalSectionItem> sections;

  /// Exibe o diálogo da Política de Privacidade.
  static Future<void> showPrivacyPolicy(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => LegalViewerDialog(
        title: 'Política de Privacidade',
        subtitle: 'Conformidade LGPD, Google Play & Escopo Google Drive',
        webUrl: 'privacidade.html',
        sections: _privacyPolicySections,
      ),
    );
  }

  /// Exibe o diálogo dos Termos de Serviço.
  static Future<void> showTermsOfService(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => LegalViewerDialog(
        title: 'Termos de Serviço',
        subtitle: 'Condições gerais, uso da plataforma e propriedade de dados',
        webUrl: 'termos.html',
        sections: _termsOfServiceSections,
      ),
    );
  }

  Future<void> _openInBrowser(BuildContext context) async {
    try {
      final uri = Uri.parse(webUrl);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
        webOnlyWindowName: '_blank',
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível abrir o navegador.'),
            backgroundColor: AppColors.pastelError,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao abrir link: $e'),
            backgroundColor: AppColors.pastelError,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondaryColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Dialog(
      backgroundColor: backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedXl),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 680,
          maxHeight: 700,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabeçalho do Modal
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainerLight,
                      borderRadius: AppRadius.roundedMd,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'S',
                      style: TextStyle(
                        color: AppColors.onPastelSuccessContainer,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 11,
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

            // Conteúdo Rolável com as Seções
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: sections.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) {
                  final section = sections[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: section.isHighlight
                          ? (isDark
                              ? AppColors.surfaceDark
                              : AppColors.primaryContainerLight.withOpacity(0.5))
                          : (isDark ? AppColors.surfaceDark : AppColors.backgroundLight),
                      borderRadius: AppRadius.roundedLg,
                      border: Border.all(
                        color: section.isHighlight
                            ? AppColors.primaryLight
                            : borderColor,
                        width: section.isHighlight ? 1.5 : 1,
                      ),
                    ),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (section.icon != null) ...[
                              Icon(
                                section.icon,
                                size: 18,
                                color: section.isHighlight
                                    ? AppColors.primaryLight
                                    : textSecondaryColor,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                            ],
                            Expanded(
                              child: Text(
                                section.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          section.body,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.55,
                            color: textColor.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const Divider(height: 1),

            // Rodapé com Ações
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  Text(
                    'Seapruma • 2026',
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondaryColor,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _openInBrowser(context),
                        icon: const Icon(Icons.open_in_browser_rounded, size: 16),
                        label: const Text('Abrir Web'),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.roundedMd,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.roundedMd,
                          ),
                        ),
                        child: const Text('Entendido'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LegalSectionItem {
  const LegalSectionItem({
    required this.title,
    required this.body,
    this.icon,
    this.isHighlight = false,
  });

  final String title;
  final String body;
  final IconData? icon;
  final bool isHighlight;
}

const List<LegalSectionItem> _privacyPolicySections = [
  LegalSectionItem(
    title: '1. Visão Geral e Identificação',
    body:
        'O Seapruma é uma plataforma voltada para o planejamento pessoal, gestão de hábitos, acompanhamento de tarefas e controle financeiro. Atuamos sob o modelo offline-first com sincronização segura e conformidade estrita com a LGPD (Lei 13.709/2018).',
    icon: Icons.shield_outlined,
  ),
  LegalSectionItem(
    title: '2. Dados Tratados e Finalidade',
    body:
        'Tratamos dados cadastrais mínimos (e-mail para autenticação) e informações operacionais inseridas pelo próprio usuário (contas, lançamentos, tarefas e metas). Seus dados nunca são vendidos ou comercializados.',
    icon: Icons.data_usage_outlined,
  ),
  LegalSectionItem(
    title: '3. Integração com Google Drive (drive.file)',
    body:
        'O escopo Google Drive solicitado (drive.file) é restrito exclusivamente para criar e restaurar os arquivos de backup gerados pelo próprio Seapruma (Seapruma_Backup_*.json). O app NÃO possui acesso a nenhum outro arquivo pessoal no seu Google Drive.',
    icon: Icons.cloud_outlined,
    isHighlight: true,
  ),
  LegalSectionItem(
    title: '4. Armazenamento e Segurança (Appwrite)',
    body:
        'Conexões protegidas via HTTPS/TLS e WSS seguro. Isolamento total por conta de usuário no banco de dados e validação de integridade criptográfica SHA-256 para backups.',
    icon: Icons.lock_outline,
  ),
  LegalSectionItem(
    title: '5. Direitos do Titular & Exclusão de Dados',
    body:
        'Em conformidade com o Art. 18 da LGPD, você possui direito de acesso, correção, exportação integral (JSON/CSV) e exclusão total da conta e dados mediante solicitação para suporte@seapruma.app.',
    icon: Icons.delete_outline,
    isHighlight: true,
  ),
];

const List<LegalSectionItem> _termsOfServiceSections = [
  LegalSectionItem(
    title: '1. Aceitação dos Termos',
    body:
        'Ao acessar ou utilizar o Seapruma, você concorda expressamente com as condições deste documento e com a Política de Privacidade do aplicativo.',
    icon: Icons.handshake_outlined,
  ),
  LegalSectionItem(
    title: '2. Objeto e Plataforma',
    body:
        'O Seapruma é uma ferramenta de apoio computacional à autogestão pessoal, financeira e de rotinas diárias com arquitetura offline-first.',
    icon: Icons.apps_outlined,
  ),
  LegalSectionItem(
    title: '3. Propriedade dos Dados',
    body:
        'Você é o proprietário integral e soberano de todos os seus lançamentos, transações financeiras, tarefas e anotações cadastradas. O aplicativo concede a liberdade de exportá-los a qualquer momento.',
    icon: Icons.inventory_2_outlined,
    isHighlight: true,
  ),
  LegalSectionItem(
    title: '4. Isenção de Consultoria Financeira',
    body:
        'O Seapruma não presta consultoria contábil, financeira, fiscal ou de investimentos. Todos os relatórios refletem os dados inseridos e as decisões financeiras são de exclusiva responsabilidade do usuário.',
    icon: Icons.info_outline,
    isHighlight: true,
  ),
  LegalSectionItem(
    title: '5. Backups e Google Drive',
    body:
        'O usuário pode utilizar o backup opcional no Google Drive via escopo restrito drive.file. A guarda da conta Google e do espaço de armazenamento é de sua responsabilidade.',
    icon: Icons.backup_outlined,
  ),
  LegalSectionItem(
    title: '6. Legislação Aplicável e Contato',
    body:
        'Estes termos são regidos pelas leis da República Federativa do Brasil e pelo Marco Civil da Internet. Dúvidas ou suporte: suporte@seapruma.app.',
    icon: Icons.gavel_outlined,
  ),
];
