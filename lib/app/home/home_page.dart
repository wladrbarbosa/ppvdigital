import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ppvdigital/app/capacitacao/financas/financas_controller.dart';
import 'package:ppvdigital/app/capacitacao/tarefas_habitos/tarefas_habitos_controller.dart';
import 'package:ppvdigital/app/home/widgets/configuracoes_modal_widget.dart';
import 'package:ppvdigital/core.dart';
import 'package:ppvdigital/design_system/design_system.dart';
import 'package:ppvdigital/routes.g.dart';
import 'package:ppvdigital/services/pwa_update_service.dart';
import 'package:routefly/routefly.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.title = 'Seapruma'});

  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _updateAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkPwaUpdate();
  }

  Future<void> _checkPwaUpdate() async {
    if (kIsWeb) {
      final available = await PwaUpdateService.isUpdateAvailable(
        Core.appVersion,
      );
      if (mounted && available) {
        setState(() {
          _updateAvailable = true;
        });
      }
    }
  }

  void _showUpdateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedLg),
        title: Row(
          children: [
            Icon(
              _updateAvailable ? Icons.system_update : Icons.refresh,
              color: _updateAvailable
                  ? AppColors.pastelSuccess
                  : AppColors.pastelWarning,
            ),
            const SizedBox(width: 8),
            Text(
              _updateAvailable
                  ? 'Nova Versão Disponível!'
                  : 'Atualizar Aplicativo',
            ),
          ],
        ),
        content: Text(
          _updateAvailable
              ? 'Uma nova versão do Seapruma foi implantada no servidor.\n\nDeseja recarregar o app agora para aplicar as melhorias?'
              : 'Deseja limpar os arquivos em cache e forçar o recarregamento do aplicativo?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _updateAvailable
                  ? AppColors.pastelSuccess
                  : AppColors.pastelWarning,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.bolt),
            label: const Text('Atualizar Agora'),
            onPressed: () {
              Navigator.pop(context);
              PwaUpdateService.forceAppUpdate();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedLg),
        title: const Text('Confirmar Saída'),
        content: const Text('Deseja realmente sair da sua conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.pastelError,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await Core.loginController.signOut();
      Routefly.navigate(routePaths.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        actions: [
          if (kIsWeb)
            IconButton(
              icon: Tooltip(
                message: _updateAvailable
                    ? 'Nova versão do Seapruma disponível! Clique para recarregar.'
                    : 'Recarregar aplicação e limpar cache',
                child: Icon(
                  _updateAvailable ? Icons.system_update : Icons.refresh,
                  color: _updateAvailable ? AppColors.pastelSuccess : null,
                ),
              ),
              tooltip: _updateAvailable
                  ? 'Nova versão disponível! Clique para atualizar.'
                  : 'Forçar Atualização / Limpar Cache',
              onPressed: _showUpdateDialog,
            ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Configurações',
            onPressed: () => ConfiguracoesModalWidget.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.pastelError),
            tooltip: 'Sair',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xl,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Início',
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Gerencie suas atividades diárias e acompanhe sua saúde financeira.',
                  style: TextStyle(color: Theme.of(context).hintColor),
                ),
                const SizedBox(height: AppSpacing.xl),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 600;
                    return isMobile
                        ? Column(
                            children: [
                              _buildCard(
                                title: 'Hábitos e Tarefas',
                                description: 'Controle a execução de suas metas diárias, crie hábitos saudáveis e agende tarefas.',
                                icon: Icons.playlist_add_check_rounded,
                                color: AppColors.pastelInfo,
                                onTap: () {
                                  TarefasHabitosController
                                          .tarefasHabitosFuture =
                                      null;
                                  Routefly.navigate(
                                    routePaths.capacitacao.tarefasHabitos.path,
                                  );
                                },
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _buildCard(
                                title: 'Finanças',
                                description: 'Organize suas contas, receitas, despesas, transferências e acompanhe transações divididas.',
                                icon: Icons.account_balance_wallet_rounded,
                                color: AppColors.pastelSuccess,
                                onTap: () {
                                  FinancasController.financasFuture = null;
                                  Routefly.navigate(
                                    routePaths.capacitacao.financas,
                                  );
                                },
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: _buildCard(
                                  title: 'Hábitos e Tarefas',
                                  description: 'Controle a execução de suas metas diárias, crie hábitos saudáveis e agende tarefas.',
                                  icon: Icons.playlist_add_check_rounded,
                                  color: AppColors.pastelInfo,
                                  onTap: () {
                                    TarefasHabitosController
                                            .tarefasHabitosFuture =
                                        null;
                                    Routefly.navigate(
                                      routePaths
                                          .capacitacao
                                          .tarefasHabitos
                                          .path,
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: AppSpacing.lg),
                              Expanded(
                                child: _buildCard(
                                  title: 'Finanças',
                                  description: 'Organize suas contas, receitas, despesas, transferências e acompanhe transações divididas.',
                                  icon: Icons.account_balance_wallet_rounded,
                                  color: AppColors.pastelSuccess,
                                  onTap: () {
                                    FinancasController.financasFuture = null;
                                    Routefly.navigate(
                                      routePaths.capacitacao.financas,
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.roundedLg,
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.12),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.roundedLg,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: AppRadius.roundedMd,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).hintColor,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Acessar',
                    style: TextStyle(fontWeight: FontWeight.bold, color: color),
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  Icon(Icons.arrow_forward_rounded, color: color, size: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
