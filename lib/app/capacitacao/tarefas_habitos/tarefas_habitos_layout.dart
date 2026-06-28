import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:ppvdigital/app/capacitacao/tarefas_habitos/lista_habitos_tarefas_page.dart';
import 'package:ppvdigital/core.dart';
import 'package:ppvdigital/routes.g.dart';
import 'package:routefly/routefly.dart';

class TarefasPage extends StatefulWidget {
  const TarefasPage({super.key, this.title = 'Tarefas e Hábitos'});

  final String title;

  @override
  TarefasPageState createState() => TarefasPageState();
}

class TarefasPageState extends State<TarefasPage>
    with SingleTickerProviderStateMixin {
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
      case final String url
          when url == routePaths.capacitacao.tarefasHabitos.calendario:
        tabController = TabController(initialIndex: 1, vsync: this, length: 3);
      case final String url
          when url == routePaths.capacitacao.tarefasHabitos.categorias:
        tabController = TabController(initialIndex: 2, vsync: this, length: 3);
      default:
        tabController = TabController(vsync: this, length: 3);
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
        default:
          Routefly.navigate(
            routePaths.capacitacao.tarefasHabitos.listaHabitosTarefas,
          );
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
          title: const Text('Tarefas e Hábitos'),
        ),
        bottomNavigationBar: Material(
          color: Theme.of(context).cardColor,
          elevation: 8,
          child: SafeArea(
            child: TabBar(
              controller: tabController,
              tabs: const [
                Tab(icon: Icon(Icons.task), text: 'Tarefas/Hábitos'),
                Tab(icon: Icon(Icons.calendar_month), text: 'Calendário'),
                Tab(icon: Icon(Icons.category), text: 'Categorias'),
              ],
            ),
          ),
        ),
        body: RouterOutlet(
          defaultWidget: ListaHabitosTarefasPage(key: GlobalKey()),
        ),
        floatingActionButtonLocation: ExpandableFab.location,
        floatingActionButton: ExpandableFab(
          children: [
            FloatingActionButton.extended(
              tooltip: 'Tarefa/Hábito',
              label: const Text('Tarefa/Hábito'),
              icon: const Icon(Icons.task),
              onPressed: () {
                Routefly.pushNavigate(
                  routePaths.capacitacao.criarEditarHabitoTarefa,
                  arguments: Routefly.currentUri.path,
                );
              },
            ),
            FloatingActionButton.extended(
              tooltip: 'Categoria',
              label: const Text('Categoria'),
              icon: const Icon(Icons.category_outlined),
              onPressed: () {
                Routefly.pushNavigate(
                  routePaths.capacitacao.criarEditarCategoria,
                  arguments: Routefly.currentUri.path,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
