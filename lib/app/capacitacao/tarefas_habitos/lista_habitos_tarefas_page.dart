import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:liquid_progress_indicator_v2/liquid_progress_indicator.dart';
import 'package:ppvdigital/app/capacitacao/tarefas_habitos/tarefas_habitos_controller.dart';
import 'package:ppvdigital/core.dart';
import 'package:ppvdigital/models/tarefas_habitos_qtd_model.dart';
import 'package:ppvdigital/routes.g.dart';
import 'package:routefly/routefly.dart';

extension RoundCorrectDouble on double {
  double roundDouble(int places) {
    final num mod = pow(10.0, places);
    return (this * mod).roundToDouble() / mod;
  }
}

extension RoundCorrectNum on num {
  num roundDouble(int places) {
    final num mod = pow(10.0, places);
    return (this * mod).roundToDouble() / mod;
  }
}

class ListaHabitosTarefasPage extends StatefulWidget {
  const ListaHabitosTarefasPage({super.key});

  @override
  State<ListaHabitosTarefasPage> createState() =>
      ListaHabitosTarefasPageState();
}

class ListaHabitosTarefasPageState extends State<ListaHabitosTarefasPage> {
  final double width = 220.0;
  final double height = 120.0;
  static int? qtdItems;
  late int? _selectedItem;

  @override
  void initState() {
    super.initState();
    TarefasHabitosController.tarefasHabitosFuture = Core
        .tarefasHabitosController
        .loadDocuments();
  }

  double _calculateCycleProgress(TarefaHabitoQtdModel qtd) {
    final DateTime now = DateTime.now();
    final DateTime origBeginning = qtd.createdAt;
    final String reiniciaEmTipo = qtd.reiniciaEmTipo;
    final int reiniciaEmQtd = qtd.reiniciaEmQtd;

    final Duration beginningNowDiff = now.difference(origBeginning);
    DateTime startPeriod = origBeginning;
    DateTime endPeriod = origBeginning;

    switch (reiniciaEmTipo) {
      case 'dias':
        final int blocks = beginningNowDiff.inDays ~/ reiniciaEmQtd;
        startPeriod = origBeginning.add(Duration(days: blocks * reiniciaEmQtd));
        endPeriod = startPeriod.add(Duration(days: reiniciaEmQtd));
        break;
      case 'semanas':
        final int blocks = beginningNowDiff.inDays ~/ (7 * reiniciaEmQtd);
        startPeriod =
            origBeginning.add(Duration(days: blocks * 7 * reiniciaEmQtd));
        endPeriod = startPeriod.add(Duration(days: 7 * reiniciaEmQtd));
        break;
      case 'meses':
        final int monthDiff = (now.year - origBeginning.year) * 12 +
            (now.month - origBeginning.month);
        final int blocks = monthDiff ~/ reiniciaEmQtd;
        startPeriod = DateTime(
          origBeginning.year,
          origBeginning.month + (blocks * reiniciaEmQtd),
          origBeginning.day,
        );
        endPeriod = DateTime(
          startPeriod.year,
          startPeriod.month + reiniciaEmQtd,
          startPeriod.day,
        );
        break;
      case 'anos':
        final int yearDiff = now.year - origBeginning.year;
        final int blocks = yearDiff ~/ reiniciaEmQtd;
        startPeriod = DateTime(
          origBeginning.year + (blocks * reiniciaEmQtd),
          origBeginning.month,
          origBeginning.day,
        );
        endPeriod = DateTime(
          startPeriod.year + reiniciaEmQtd,
          startPeriod.month,
          startPeriod.day,
        );
        break;
      default:
        final int blocks = beginningNowDiff.inHours ~/ reiniciaEmQtd;
        startPeriod =
            origBeginning.add(Duration(hours: blocks * reiniciaEmQtd));
        endPeriod = startPeriod.add(Duration(hours: reiniciaEmQtd));
        break;
    }

    final int totalMs = endPeriod.difference(startPeriod).inMilliseconds;
    if (totalMs <= 0) return 0.0;
    final int elapsedMs = now.difference(startPeriod).inMilliseconds;
    final double progress = (elapsedMs / totalMs).clamp(0.0, 1.0);
    return progress;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: TarefasHabitosController.tarefasHabitosFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData &&
            snapshot.connectionState == ConnectionState.done) {
          return Observer(
            builder: (context) {
              final list = Core.tarefasHabitosController.tarefasHabitosList;
              return Container(
                padding: const EdgeInsets.all(16.0),
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: width,
                    mainAxisExtent: height,
                    mainAxisSpacing: 10.0,
                    crossAxisSpacing: 10.0,
                  ),
                  itemCount: list.length,
                  itemBuilder: (itemContext, index) {
                    final item = list[index];
                    final qtd = item.tarefasHabitosQtd.firstOrNull;
                    final double progress = qtd != null ? _calculateCycleProgress(qtd) : 0.0;
                    final int animDurationMs =
                        (3000 * (1.0 - progress)).clamp(300, 3000).toInt();

                    final bool metaBatida = item.tarefasHabitosQtd.isNotEmpty &&
                        item.tarefasHabitosQtd.every((el) => el.vezesPraticado >= el.metaVezes);
                    final bool showAnimation = progress >= 0.25 && !metaBatida;

                    return LayoutBuilder(
                      builder: (BuildContext layoutContext, BoxConstraints constraints) {
                        return Observer(
                          warnWhenNoObservables: true,
                          name: 'tarefas_habitos',
                          builder: (observerContext) {
                            final List<Widget> children = [];

                            for (
                              int i = 0;
                              i <
                                  Core
                                      .tarefasHabitosController
                                      .tarefasHabitosList[index]
                                      .tarefasHabitosQtd
                                      .length;
                              i++
                            ) {
                              final int greaterMeta = Core
                                  .tarefasHabitosController
                                  .tarefasHabitosList[index]
                                  .tarefasHabitosQtd
                                  .fold(
                                    0,
                                    (previousValue, el) =>
                                        el.metaVezes > previousValue
                                        ? el.metaVezes
                                        : previousValue,
                                  );
                              final Color? liquidColor =
                                  Core
                                      .tarefasHabitosController
                                      .tarefasHabitosList[index]
                                      .tarefasHabitosQtd
                                      .isNotEmpty
                                  ? Core
                                        .tarefasHabitosController
                                        .tarefasHabitosList[index]
                                        .tarefasHabitosQtd[i]
                                        .categoriasTarefasHabitos
                                        ?.cor
                                  : null;

                              children.add(
                                Expanded(
                                  child: LiquidCustomProgressIndicator(
                                    value:
                                        Core
                                            .tarefasHabitosController
                                            .tarefasHabitosList[index]
                                            .tarefasHabitosQtd[i]
                                            .vezesPraticado *
                                        1.05 /
                                        greaterMeta,
                                    backgroundColor: Colors.transparent,
                                    valueColor: liquidColor != null
                                        ? AlwaysStoppedAnimation(liquidColor)
                                        : null,
                                    direction: Axis.vertical,
                                    shapePath: Path()
                                      ..addRRect(
                                        RRect.fromRectAndCorners(
                                          Rect.fromLTWH(
                                            i == 0 ? 5 : 0,
                                            5,
                                            ((constraints.maxWidth - 10) /
                                                Core
                                                    .tarefasHabitosController
                                                    .tarefasHabitosList[index]
                                                    .tarefasHabitosQtd
                                                    .length),
                                            constraints.maxHeight - 10,
                                          ),
                                          topLeft: Radius.circular(
                                            i == 0 ? 20 : 0,
                                          ),
                                          topRight: Radius.circular(
                                            i ==
                                                    Core
                                                            .tarefasHabitosController
                                                            .tarefasHabitosList[index]
                                                            .tarefasHabitosQtd
                                                            .length -
                                                        1
                                                ? 20
                                                : 0,
                                          ),
                                          bottomLeft: Radius.circular(
                                            i == 0 ? 20 : 0,
                                          ),
                                          bottomRight: Radius.circular(
                                            i ==
                                                    Core
                                                            .tarefasHabitosController
                                                            .tarefasHabitosList[index]
                                                            .tarefasHabitosQtd
                                                            .length -
                                                        1
                                                ? 20
                                                : 0,
                                          ),
                                        ),
                                      ),
                                  ),
                                ),
                              );
                            }

                            final cardWidget = Stack(
                              children: [
                                Row(children: children),
                                Card(
                                  clipBehavior: Clip.hardEdge,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      Routefly.pushNavigate(
                                        routePaths
                                            .capacitacao
                                            .criarEditarHabitoTarefa,
                                        arguments: {
                                          'lastRoute': Routefly.currentUri.path,
                                          'tarefaHabito': Core
                                              .tarefasHabitosController
                                              .tarefasHabitosList[index],
                                        },
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceAround,
                                              children: [
                                                Text(
                                                  Core
                                                      .tarefasHabitosController
                                                      .tarefasHabitosList[index]
                                                      .nome,
                                                ),
                                                Text(
                                                  '${Core.tarefasHabitosController.tarefasHabitosList[index].tarefasHabitosQtd.firstOrNull?.vezesPraticado.roundDouble(2) ?? 0} vezes',
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () {
                                              Core.tarefasHabitosController
                                                  .incrementQtdHabito(
                                                    Core
                                                        .tarefasHabitosController
                                                        .tarefasHabitosList[index]
                                                        .id,
                                                  );
                                            },
                                            icon: const Icon(Icons.add_circle),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );

                        if (showAnimation) {
                          return cardWidget
                              .animate(
                                onPlay: (controller) =>
                                    controller.repeat(reverse: true),
                              )
                              .fade(
                                begin: 1.0,
                                end: 0.1,
                                duration:
                                    Duration(milliseconds: animDurationMs),
                              );
                        } else {
                          return cardWidget;
                        }
                          },
                        );
                      },
                    );
                  },
                ),
              );
            },
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}
