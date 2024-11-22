import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:ppvdigital/app/capacitacao/tarefas_habitos/lista_habitos_tarefas_page.dart';
import 'package:ppvdigital/core.dart';
import 'package:ppvdigital/routes.g.dart';
import 'package:routefly/routefly.dart';

class TarefasPage extends StatefulWidget {
  const TarefasPage({
    super.key,
    this.title = 'Tarefas e Hábitos',
  });
  
  final String title;

  @override
  TarefasPageState createState() => TarefasPageState();
}

class TarefasPageState extends State<TarefasPage> with SingleTickerProviderStateMixin {
  static TabController? tabController;
  Future<void>? tarefasHabitosList;
  static GlobalKey globalKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    tarefasHabitosList = Core.instance.tarefasHabitosController.loadDocuments();

    if (tabController == null) {
      switch (Routefly.currentUri.path) {
        case final String url when url == routePaths.capacitacao.tarefasHabitos.calendario:
          tabController = TabController(initialIndex: 1, vsync: this, length: 4);
        case final String url when url == routePaths.capacitacao.tarefasHabitos.categorias:
          tabController = TabController(initialIndex: 2, vsync: this, length: 4);
        case final String url when url == routePaths.capacitacao.tarefasHabitos.historico:
          tabController = TabController(initialIndex: 3, vsync: this, length: 4);
        default:
          tabController = TabController(vsync: this, length: 4);
      }
    }

    tabController?.addListener(tabListening);
  }

  void tabListening() {
    if (tabController?.indexIsChanging ?? false) {
      switch (tabController?.index) {
        case 1:
          Routefly.navigate(routePaths.capacitacao.tarefasHabitos.calendario);
        case 2:
          Routefly.navigate(routePaths.capacitacao.tarefasHabitos.categorias);
        case 3:
          Routefly.navigate(routePaths.capacitacao.tarefasHabitos.historico);
        default:
          Routefly.navigate(routePaths.capacitacao.tarefasHabitos.listaHabitosTarefas);
      }
    }
  }

  @override
  void dispose() {
    tabController?.removeListener(tabListening);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: globalKey,
      appBar: AppBar(
        bottom: TabBar(
          controller: tabController,
          tabs: const [
            ListTile(
              title: Text(
              'Tarefas/Hábitos',
              ),
            ),
            ListTile(
              title: Text(
              'Calendário',
              ),
            ),
            ListTile(
              title: Text(
              'Categorias',
              ),
            ),
            ListTile(
              title: Text(
              'Histórico',
              ),
            ),
          ],
        ),
        title: const Text('Tarefas e Hábitos'),
      ),
      body: FutureBuilder(
        future: tarefasHabitosList,
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.connectionState == ConnectionState.done) {
            return const RouterOutlet(
              defaultWidget: ListaHabitosTarefasPage(),
            );
          }
          else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
      floatingActionButton: SpeedDial(
        tooltip: 'Adicionar',
        spaceBetweenChildren: 16,
        children: [
          SpeedDialChild(
            label: 'Tarefa/Hábito',
            child: const Icon(Icons.task),
            onTap: () {
              Routefly.pushNavigate(routePaths.capacitacao.criarEditarHabitoTarefa, arguments: Routefly.currentUri.path);
            },
          ),
          SpeedDialChild(
            label: 'Categoria',
            child: const Icon(Icons.category_outlined),
          ),
        ],
        child: const Icon(Icons.add),
      ),
    );
  }
}
