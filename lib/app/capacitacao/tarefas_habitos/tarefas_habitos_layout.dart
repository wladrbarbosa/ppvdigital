import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:ppvdigital/app/capacitacao/tarefas_habitos/tarefas_page.dart';
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

  static const List<Color> _presetColors = [
    Colors.teal,
    Colors.tealAccent,
    Colors.blue,
    Colors.blueAccent,
    Colors.purple,
    Colors.purpleAccent,
    Colors.orange,
    Colors.orangeAccent,
    Colors.pink,
    Colors.pinkAccent,
    Colors.green,
    Colors.greenAccent,
    Colors.amber,
    Colors.amberAccent,
    Colors.red,
    Colors.redAccent,
    Colors.indigo,
    Colors.indigoAccent,
    Colors.cyan,
    Colors.cyanAccent,
  ];

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
          when url == routePaths.capacitacao.tarefasHabitos.habitos:
        tabController = TabController(initialIndex: 1, vsync: this, length: 4);
      case final String url
          when url == routePaths.capacitacao.tarefasHabitos.calendario:
        tabController = TabController(initialIndex: 2, vsync: this, length: 4);
      case final String url
          when url == routePaths.capacitacao.tarefasHabitos.categorias:
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
          Routefly.navigate(routePaths.capacitacao.tarefasHabitos.habitos);
        case 2:
          Routefly.navigate(routePaths.capacitacao.tarefasHabitos.calendario);
        case 3:
          Routefly.navigate(routePaths.capacitacao.tarefasHabitos.categorias);
        default:
          Routefly.navigate(
            routePaths.capacitacao.tarefasHabitos.tarefas,
          );
      }
    }
  }

  @override
  void dispose() {
    tabController?.removeListener(tabListening);
    super.dispose();
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.color_lens, color: Colors.blueAccent),
              SizedBox(width: 8),
              Text('Configurações de Cores'),
            ],
          ),
          content: Observer(
            builder: (_) {
              final Color currentHabitColor =
                  Core.tarefasHabitosController.habitColor.value;
              final Color currentTaskColor =
                  Core.tarefasHabitosController.taskColor.value;

              Widget buildColorPicker({
                required String label,
                required Color selectedColor,
                required ValueChanged<Color> onColorSelected,
              }) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _presetColors.map((color) {
                        final bool isSelected = color.value == selectedColor.value;
                        return GestureDetector(
                          onTap: () => onColorSelected(color),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(color: Colors.white, width: 3)
                                  : Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: color.withOpacity(0.6),
                                        blurRadius: 6,
                                        spreadRadius: 2,
                                      )
                                    ]
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 20,
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                );
              }

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildColorPicker(
                      label: 'Cor dos Hábitos',
                      selectedColor: currentHabitColor,
                      onColorSelected: (color) {
                        Core.tarefasHabitosController.setHabitColor(color);
                      },
                    ),
                    const SizedBox(height: 24),
                    buildColorPicker(
                      label: 'Cor das Tarefas',
                      selectedColor: currentTaskColor,
                      onColorSelected: (color) {
                        Core.tarefasHabitosController.setTaskColor(color);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: Core.globalKey,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tarefas e Hábitos'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Routefly.navigate(routePaths.capacitacao.path);
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                _showSettingsDialog(context);
              },
            ),
          ],
        ),
        bottomNavigationBar: Material(
          color: Theme.of(context).cardColor,
          elevation: 8,
          child: SafeArea(
            child: TabBar(
              controller: tabController,
              tabs: const [
                Tab(icon: Icon(Icons.task_alt), text: 'Tarefas'),
                Tab(icon: Icon(Icons.star_border), text: 'Hábitos'),
                Tab(icon: Icon(Icons.calendar_month), text: 'Calendário'),
                Tab(icon: Icon(Icons.category), text: 'Categorias'),
              ],
            ),
          ),
        ),
        body: const RouterOutlet(
          defaultWidget: TarefasListPage(),
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
