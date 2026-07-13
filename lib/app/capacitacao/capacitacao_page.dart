import 'package:flutter/material.dart';
import 'package:ppvdigital/app/capacitacao/financas/financas_controller.dart';
import 'package:ppvdigital/app/capacitacao/tarefas_habitos/tarefas_habitos_controller.dart';
import 'package:ppvdigital/core.dart';
import 'package:ppvdigital/routes.g.dart';
import 'package:routefly/routefly.dart';

class CapacitacaoPage extends StatefulWidget {
  const CapacitacaoPage({super.key, this.title = 'Seapruma'});

  final String title;

  @override
  _CapacitacaoPageState createState() => _CapacitacaoPageState();
}

class _CapacitacaoPageState extends State<CapacitacaoPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            tooltip: 'Sair',
            onPressed: () async {
              await Core.loginController.signOut();
              Routefly.navigate(routePaths.login);
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Início',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Gerencie suas atividades diárias e acompanhe sua saúde financeira.',
                  style: TextStyle(color: Theme.of(context).hintColor),
                ),
                const SizedBox(height: 32),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 600;
                    return isMobile
                        ? Column(
                            children: [
                              _buildCard(
                                title: 'Hábitos e Tarefas',
                                description:
                                    'Controle a execução de suas metas diárias, crie hábitos saudáveis e agende tarefas.',
                                icon: Icons.playlist_add_check_rounded,
                                color: Colors.deepPurple,
                                onTap: () {
                                  TarefasHabitosController
                                          .tarefasHabitosFuture =
                                      null;
                                  Routefly.navigate(
                                    routePaths.capacitacao.tarefasHabitos.path,
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildCard(
                                title: 'Finanças',
                                description:
                                    'Organize suas contas, receitas, despesas, transferências e acompanhe transações divididas.',
                                icon: Icons.account_balance_wallet_rounded,
                                color: Colors.teal,
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
                                  description:
                                      'Controle a execução de suas metas diárias, crie hábitos saudáveis e agende tarefas.',
                                  icon: Icons.playlist_add_check_rounded,
                                  color: Colors.deepPurple,
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
                              const SizedBox(width: 24),
                              Expanded(
                                child: _buildCard(
                                  title: 'Finanças',
                                  description:
                                      'Organize suas contas, receitas, despesas, transferências e acompanhe transações divididas.',
                                  icon: Icons.account_balance_wallet_rounded,
                                  color: Colors.teal,
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
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).hintColor,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Acessar',
                    style: TextStyle(fontWeight: FontWeight.bold, color: color),
                  ),
                  const SizedBox(width: 4),
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
