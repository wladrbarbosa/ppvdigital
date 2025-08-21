import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ppvdigital/app/capacitacao/tarefas_habitos/historico_controller.dart';
import 'package:ppvdigital/core.dart';
import 'package:timeline_tile/timeline_tile.dart';

class HistoricoPage extends StatefulWidget {
  const HistoricoPage({
    super.key,
  });

  @override
  State<HistoricoPage> createState() => _HistoricoPageState();
}

class _HistoricoPageState extends State<HistoricoPage> {
  int? _selectedItem;
  List<Step> steps = [];

  @override
  void initState() {
    super.initState();
    HistoricoController.historicoFuture = Core.historicoController.loadDocuments();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: HistoricoController.historicoFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.connectionState == ConnectionState.done) {
          steps = List<Step>.generate(Core.historicoController.historicoList.length, (index) {
            return Step(
              step: index + 1,
              title: Core.historicoController.historicoList[index].tarefasEHabitos?.nome ?? '',
              message: DateFormat('dd/MM/yyyy HH:mm:ss').format(Core.historicoController.historicoList[index].createdAt.toLocal()),
            );
          },);
          steps.sort((a, b) => b.step.compareTo(a.step),);

          return Container(
            padding: const EdgeInsets.symmetric(
              vertical: 16.0,
              horizontal: 64.0
            ),
            child: CustomScrollView(
              slivers: [
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      final int itemIndex = index ~/ 2;

                      final Color color = Core.historicoController.historicoList[itemIndex].tarefasEHabitos?.tarefasHabitosQtd.isNotEmpty ?? false
                        ? Core.historicoController.historicoList[itemIndex].tarefasEHabitos?.tarefasHabitosQtd.reduce((value, element) => value.metaVezes > element.metaVezes ? value : element,).categoriasTarefasHabitos?.cor ?? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onPrimary;

                      if (index.isOdd) {
                        return TimelineDivider(
                          color: color,
                          thickness: 5,
                          begin: 0.1,
                          end: 0.9,
                        );
                      }
                
                      final Step step = steps[itemIndex];
                      final bool isLeftAlign = itemIndex.isEven;
                
                      final child = _TimelineStepsChild(
                        title: step.title,
                        subtitle: step.message,
                        isLeftAlign: isLeftAlign,
                      );
                
                      final isFirst = itemIndex == 0;
                      final isLast = itemIndex == steps.length - 1;
                      double indicatorY;
                      if (isFirst) {
                        indicatorY = 0.2;
                      } else if (isLast) {
                        indicatorY = 0.8;
                      } else {
                        indicatorY = 0.5;
                      }
                
                      return TimelineTile(
                        alignment: TimelineAlign.manual,
                        endChild: isLeftAlign ? child : null,
                        startChild: isLeftAlign ? null : child,
                        lineXY: isLeftAlign ? 0.1 : 0.9,
                        isFirst: isFirst,
                        isLast: isLast,
                        indicatorStyle: IndicatorStyle(
                          width: 40,
                          height: 40,
                          indicatorXY: indicatorY,
                          indicator: _TimelineStepIndicator(
                            step: '${step.step}',
                            color: color,
                          ),
                        ),
                        beforeLineStyle: LineStyle(
                          color: color,
                          thickness: 5,
                        ),
                      );
                    },
                    childCount: max(0, steps.length * 2 - 1),
                  ),
                ),
              ]
            ),
          );
        }
        else {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }
}

class _TimelineStepIndicator extends StatelessWidget {
  const _TimelineStepIndicator({
    required this.step,
    required this.color,
  });

  final String step;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
      child: Center(
        child: Text(
          step,
        ),
      ),
    );
  }
}

class _TimelineStepsChild extends StatelessWidget {
  const _TimelineStepsChild({
    required this.title,
    required this.subtitle,
    required this.isLeftAlign,
  });

  final String title;
  final String subtitle;
  final bool isLeftAlign;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: isLeftAlign
          ? const EdgeInsets.only(right: 32, top: 16, bottom: 16, left: 10)
          : const EdgeInsets.only(left: 32, top: 16, bottom: 16, right: 10),
      child: Column(
        crossAxisAlignment:
            !isLeftAlign ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            title,
            textAlign: isLeftAlign ? TextAlign.right : TextAlign.left,
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            textAlign: isLeftAlign ? TextAlign.right : TextAlign.left,
          ),
        ],
      ),
    );
  }
}

class Step {
  const Step({
    required this.step,
    required this.title,
    required this.message,
  });

  final int step;
  final String title;
  final String message;
}
