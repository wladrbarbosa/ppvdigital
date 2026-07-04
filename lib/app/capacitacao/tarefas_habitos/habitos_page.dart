import 'package:flutter/material.dart';
import 'package:ppvdigital/app/capacitacao/tarefas_habitos/lista_habitos_tarefas_widget.dart';

class HabitosListPage extends StatelessWidget {
  const HabitosListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ListaHabitosTarefasWidget(onlyTipo: 'habito');
  }
}
