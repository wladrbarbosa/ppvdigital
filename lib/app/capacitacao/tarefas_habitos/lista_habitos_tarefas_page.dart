import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:liquid_progress_indicator_v2/liquid_progress_indicator.dart';
import 'package:ppvdigital/app/capacitacao/tarefas_habitos/tarefas_habitos_controller.dart';
import 'package:ppvdigital/core.dart';
import 'package:ppvdigital/models/tarefas_habitos_model.dart';
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
  final double width = 260.0;
  final double height = 120.0;
  static int? qtdItems;

  @override
  void initState() {
    super.initState();
    TarefasHabitosController.tarefasHabitosFuture = Core
        .tarefasHabitosController
        .loadDocuments();
  }

  double _calculateCycleProgress(TarefaHabitoQtdModel qtd) {
    final DateTime now = DateTime.now();
    final DateTime origBeginning = qtd.createdAt.toLocal();
    final DateTime beginning = DateTime(
      origBeginning.year,
      origBeginning.month,
      origBeginning.day,
    );
    final String reiniciaEmTipo = qtd.reiniciaEmTipo;
    final int reiniciaEmQtd = qtd.reiniciaEmQtd;

    final Duration beginningNowDiff = now.difference(beginning);
    DateTime startPeriod = beginning;
    DateTime endPeriod = beginning;

    switch (reiniciaEmTipo) {
      case 'dias':
        final int blocks = beginningNowDiff.inDays ~/ reiniciaEmQtd;
        startPeriod = beginning.add(Duration(days: blocks * reiniciaEmQtd));
        endPeriod = startPeriod.add(Duration(days: reiniciaEmQtd));
        break;
      case 'semanas':
        final int blocks = beginningNowDiff.inDays ~/ (7 * reiniciaEmQtd);
        startPeriod = beginning.add(Duration(days: blocks * 7 * reiniciaEmQtd));
        endPeriod = startPeriod.add(Duration(days: 7 * reiniciaEmQtd));
        break;
      case 'meses':
        final int monthDiff =
            (now.year - beginning.year) * 12 + (now.month - beginning.month);
        final int blocks = monthDiff ~/ reiniciaEmQtd;
        startPeriod = DateTime(
          beginning.year,
          beginning.month + (blocks * reiniciaEmQtd),
          beginning.day,
        );
        endPeriod = DateTime(
          startPeriod.year,
          startPeriod.month + reiniciaEmQtd,
          startPeriod.day,
        );
        break;
      case 'anos':
        final int yearDiff = now.year - beginning.year;
        final int blocks = yearDiff ~/ reiniciaEmQtd;
        startPeriod = DateTime(
          beginning.year + (blocks * reiniciaEmQtd),
          beginning.month,
          beginning.day,
        );
        endPeriod = DateTime(
          startPeriod.year + reiniciaEmQtd,
          startPeriod.month,
          startPeriod.day,
        );
        break;
      default:
        final int blocks = beginningNowDiff.inDays ~/ reiniciaEmQtd;
        startPeriod = beginning.add(Duration(days: blocks * reiniciaEmQtd));
        endPeriod = startPeriod.add(Duration(days: reiniciaEmQtd));
        break;
    }

    final int totalMs = endPeriod.difference(startPeriod).inMilliseconds;
    if (totalMs <= 0) return 0.0;
    final int elapsedMs = now.difference(startPeriod).inMilliseconds;
    final double progress = (elapsedMs / totalMs).clamp(0.0, 1.0);
    return progress;
  }

  String _getProgressText(TarefaHabitoModel item) {
    if (item.tarefasHabitosQtd.isEmpty) return 'Sem metas';
    if (item.tarefasHabitosQtd.length == 1) {
      final qtd = item.tarefasHabitosQtd.first;
      return '${qtd.vezesPraticado.roundDouble(1)} / ${qtd.metaVezes} vezes';
    }
    final completedCount = item.tarefasHabitosQtd
        .where((el) => el.vezesPraticado >= el.metaVezes)
        .length;
    return '$completedCount / ${item.tarefasHabitosQtd.length} metas';
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
                    final double progress = qtd != null
                        ? _calculateCycleProgress(qtd)
                        : 0.0;
                    final int animDurationMs = (3000 * (1.0 - progress))
                        .clamp(300, 3000)
                        .toInt();

                    final bool metaBatida =
                        item.tarefasHabitosQtd.isNotEmpty &&
                        item.tarefasHabitosQtd.every(
                          (el) => el.vezesPraticado >= el.metaVezes,
                        );
                    final bool showAnimation = progress >= 0.25 && !metaBatida;

                    return LayoutBuilder(
                      builder: (BuildContext layoutContext, BoxConstraints constraints) {
                        return Observer(
                          warnWhenNoObservables: true,
                          name: 'tarefas_habitos',
                          builder: (observerContext) {
                            final List<Widget> children = [];
                            final Color habitColor =
                                Core.tarefasHabitosController.habitColor.value;
                            final Color taskColor =
                                Core.tarefasHabitosController.taskColor.value;

                            for (
                              int i = 0;
                              i < item.tarefasHabitosQtd.length;
                              i++
                            ) {
                              final int greaterMeta = item.tarefasHabitosQtd
                                  .fold(
                                    0,
                                    (previousValue, el) =>
                                        el.metaVezes > previousValue
                                        ? el.metaVezes
                                        : previousValue,
                                  );
                              final Color? liquidColor =
                                  item.tarefasHabitosQtd.isNotEmpty
                                  ? item
                                        .tarefasHabitosQtd[i]
                                        .categoriasTarefasHabitos
                                        ?.cor
                                  : null;

                              final Color indicatorBgColor =
                                  item.tipo == 'habito'
                                  ? habitColor.withOpacity(0.08)
                                  : taskColor.withOpacity(0.08);

                              children.add(
                                Expanded(
                                  child: LiquidCustomProgressIndicator(
                                    value:
                                        item
                                            .tarefasHabitosQtd[i]
                                            .vezesPraticado *
                                        1.05 /
                                        greaterMeta,
                                    backgroundColor: indicatorBgColor,
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
                                                item.tarefasHabitosQtd.length),
                                            constraints.maxHeight - 10,
                                          ),
                                          topLeft: Radius.circular(
                                            i == 0 ? 20 : 0,
                                          ),
                                          topRight: Radius.circular(
                                            i ==
                                                    item
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
                                                    item
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
                                    side: BorderSide(
                                      color: item.tipo == 'habito'
                                          ? habitColor.withOpacity(0.4)
                                          : taskColor.withOpacity(0.4),
                                      width: 1.5,
                                    ),
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
                                          'tarefaHabito': item,
                                        },
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12.0,
                                        vertical: 10.0,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        item.nome,
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 13.0,
                                                        ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4.0),
                                                    // Subtle Type Badge
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 6.0,
                                                            vertical: 2.0,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            (item.tipo ==
                                                                        'habito'
                                                                    ? habitColor
                                                                    : taskColor)
                                                                .withOpacity(
                                                                  0.2,
                                                                ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8.0,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        item.tipo == 'habito'
                                                            ? 'Hábito'
                                                            : 'Tarefa',
                                                        style: TextStyle(
                                                          fontSize: 8.5,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color:
                                                              item.tipo ==
                                                                  'habito'
                                                              ? habitColor
                                                              : taskColor,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 2.0),
                                                if (item.tipo == 'tarefa' &&
                                                    item.agendamento !=
                                                        null) ...[
                                                  Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.calendar_today,
                                                        size: 11.0,
                                                        color: Colors.black54,
                                                      ),
                                                      const SizedBox(
                                                        width: 4.0,
                                                      ),
                                                      Text(
                                                        '${item.agendamento!.day.toString().padLeft(2, '0')}/${item.agendamento!.month.toString().padLeft(2, '0')} ${item.agendamento!.hour.toString().padLeft(2, '0')}:${item.agendamento!.minute.toString().padLeft(2, '0')}',
                                                        style: const TextStyle(
                                                          fontSize: 10.0,
                                                          color: Colors.white54,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                                const SizedBox(height: 2.0),
                                                if (item.tipo == 'habito')
                                                  Text(
                                                    _getProgressText(item),
                                                    style: const TextStyle(
                                                      fontSize: 11.5,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Colors.white70,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 4.0),
                                          IconButton(
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () {
                                              Core.tarefasHabitosController
                                                  .incrementQtdHabito(item.id);
                                            },
                                            icon: Icon(
                                              Icons.add_circle,
                                              size: 32.0,
                                              color: item.tipo == 'habito'
                                                  ? habitColor
                                                  : taskColor,
                                            ),
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
                                    duration: Duration(
                                      milliseconds: animDurationMs,
                                    ),
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
