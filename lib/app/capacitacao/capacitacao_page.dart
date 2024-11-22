import 'package:flutter/material.dart';
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
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: GridView.count(
          crossAxisCount: 5,
          children: [
            Card(
              child: InkWell(
                onTap: () {
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
          ],
        ),
      ),
    );
  }
}
