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
  static bool fromTabClick = false;

  void updateTabIndex(int index) {
    setState(() {
      tabController!.index = index;
    });
  }

  @override
  void initState() {
    super.initState();

    // Precisa acontecer sempre para que funcione a troca visual das tabs na TabBar
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

    tabController?.addListener(tabListening);
  }

  void tabListening() {
    if (tabController?.indexIsChanging ?? false) {
      fromTabClick = true;

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
    return KeyedSubtree(
      key: Core.globalKey,
      child: Scaffold(
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
        body: RouterOutlet(
          defaultWidget: ListaHabitosTarefasPage(key: GlobalKey(),),
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
      ),
    );
  }
}
