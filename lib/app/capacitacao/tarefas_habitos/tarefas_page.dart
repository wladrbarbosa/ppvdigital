import 'package:flutter/material.dart';
import 'package:ppvdigital/app/capacitacao/tarefas_habitos/lista_habitos_tarefas_widget.dart';

class TarefasListPage extends StatelessWidget {
  const TarefasListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ListaHabitosTarefasWidget(
      key: ValueKey('tarefa'),
      onlyTipo: 'tarefa',
    );
  }
}
