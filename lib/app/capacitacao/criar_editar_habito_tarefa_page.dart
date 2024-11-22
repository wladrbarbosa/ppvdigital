import 'package:flutter/material.dart';
import 'package:routefly/routefly.dart';

Route routeBuilder(BuildContext context, RouteSettings settings) {
  return DialogRoute(
    context: context,
    settings: settings,
    builder: (context)  => PopScope(
      onPopInvokedWithResult:(didPop, result) {
        final String? lastRoute = settings.arguments as String?;
        
        if (lastRoute != null) {
          Routefly.navigate(lastRoute);
        }
      },
      child: const Dialog(
        child: CriarHabitoTarefaPage(),
      ),
    ),
  );
}

class CriarHabitoTarefaPage extends StatefulWidget {
  const CriarHabitoTarefaPage({
    super.key,
    this.title = 'Capacitação Técnica',
  });
  
  final String title;

  @override
  _CriarHabitoTarefaPageState createState() => _CriarHabitoTarefaPageState();
}

class _CriarHabitoTarefaPageState extends State<CriarHabitoTarefaPage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          Text(
            'Criar/Editar Tarefa/Hábito',
            style: Theme.of(context).textTheme.headlineLarge,
          )
        ],
      ),
    );
  }
}
