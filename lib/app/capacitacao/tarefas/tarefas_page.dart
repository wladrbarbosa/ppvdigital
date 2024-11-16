import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

class TarefasPage extends StatefulWidget {
  const TarefasPage({
    super.key,
    this.title = 'Tarefas',
  });
  
  final String title;

  @override
  _TarefasPageState createState() => _TarefasPageState();
}

class _TarefasPageState extends State<TarefasPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    _tabController = TabController(vsync: this, length: 3);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            ListTile(
              title: Text(
              'Tarefas',
              ),
            ),
            ListTile(
              title: Text(
              'Calendário',
              ),
            ),
            ListTile(
              title: Text(
              'Histórico',
              ),
            ),
          ],
        ),
        title: const Text('Tarefas'),
      ),
      body: Observer(
        name: 'tarefas',
        builder: (context) {
          return Container();
        },
      ),
      floatingActionButton: SpeedDial(
        tooltip: 'Adicionar',
        childrenButtonSize: const Size(100, 100),
        spaceBetweenChildren: 20,
        children: [
          SpeedDialChild(
            child: const Text('Tarefa'),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          SpeedDialChild(
            child: const Text('Categoria'),
            backgroundColor: Colors.deepOrange,
            foregroundColor: Colors.white,
          ),
        ],
        child: const Icon(Icons.add),
      ),
    );
  }
}
