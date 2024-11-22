import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:liquid_progress_indicator_v2/liquid_progress_indicator.dart';
import 'package:ppvdigital/core.dart';

class ListaHabitosTarefasPage extends StatefulWidget {
  const ListaHabitosTarefasPage({
    super.key,
  });

  @override
  State<ListaHabitosTarefasPage> createState() => _ListaHabitosTarefasPageState();
}

class _ListaHabitosTarefasPageState extends State<ListaHabitosTarefasPage> {
  final double width = 220.0;
  final double height = 120.0;
  final GlobalKey<AnimatedGridState> _gridKey = GlobalKey<AnimatedGridState>();
  int? _selectedItem;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: AnimatedGrid(
        key: _gridKey,
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: width,
          mainAxisExtent: height,
          mainAxisSpacing: 10.0,
          crossAxisSpacing: 10.0,
        ),
        initialItemCount: Core.instance.tarefasHabitosController.tarefasHabitosList.length,
        itemBuilder: (itemContext, index, animation) {
          return LayoutBuilder(
            builder: (BuildContext layoutContext, BoxConstraints constraints) {
              return Observer(
                warnWhenNoObservables: true,
                name: 'tarefas_habitos',
                builder: (observerContext) {
                  return LiquidCustomProgressIndicator(
                    value: 1.05,
                    backgroundColor: Colors.transparent,
                    direction: Axis.vertical,
                    shapePath: Path()
                      ..addRRect(
                        RRect.fromRectAndRadius(
                          Rect.fromLTWH(
                            5,
                            5,
                            constraints.maxWidth - 10,
                            constraints.maxHeight - 10,
                          ),
                          const Radius.circular(20),
                        ),
                      ),
                    center: Card(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    Text(
                                      Core.instance.tarefasHabitosController.tarefasHabitosList[index].data['nome'] as String,
                                    ),
                                    Text(
                                      '${Core.instance.tarefasHabitosController.tarefasHabitosList[index].data['vezes_praticado']} vezes',
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      Core.instance.tarefasHabitosController.updateQtdHabito(
                                        Core.instance.tarefasHabitosController.tarefasHabitosList[index].$id,
                                        (Core.instance.tarefasHabitosController.tarefasHabitosList[index].data['vezes_praticado'] as int) + 1,
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.add_circle,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: Core.instance.tarefasHabitosController.tarefasHabitosList[index].data['vezes_praticado'] == 0 ? null : () {
                                      Core.instance.tarefasHabitosController.updateQtdHabito(
                                        Core.instance.tarefasHabitosController.tarefasHabitosList[index].$id,
                                        (Core.instance.tarefasHabitosController.tarefasHabitosList[index].data['vezes_praticado'] as int) - 1,
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.remove_circle,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ).animate().flipH();
                },
              );
            },
          );
        },
      ),
    );
  }
}
