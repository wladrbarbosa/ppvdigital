import 'package:flutter/material.dart';
import 'package:ppvdigital/app/capacitacao/tarefas_habitos/tarefas_habitos_controller.dart';
import 'package:ppvdigital/app/capacitacao/financas/financas_controller.dart';
import 'package:ppvdigital/core.dart';
import 'package:ppvdigital/routes.g.dart';
import 'package:routefly/routefly.dart';

class CapacitacaoPage extends StatefulWidget {
  const CapacitacaoPage({
    super.key,
    this.title = 'Capacitação Técnica',
  });
  
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
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text('Sair', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              await Core.loginController.signOut();
              Routefly.navigate(routePaths.login);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: GridView.count(
          crossAxisCount: 5,
          children: [
            Card(
              child: InkWell(
                onTap: () {
                  TarefasHabitosController.tarefasHabitosFuture = null;
                  Routefly.navigate(routePaths.capacitacao.tarefasHabitos.path);
                },
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Hábitos e Tarefas',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const Text(
                        'Controle os seus hábitos',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Card(
              child: InkWell(
                onTap: () {
                  FinancasController.financasFuture = null;
                  Routefly.navigate(routePaths.capacitacao.financas);
                },
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Finanças',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const Text(
                        'Controle os seus gastos e ganhos',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
