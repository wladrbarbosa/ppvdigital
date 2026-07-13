import 'dart:math';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:liquid_progress_indicator_v2/liquid_progress_indicator.dart';
import 'package:ppvdigital/app/capacitacao/tarefas_habitos/tarefas_habitos_controller.dart';
import 'package:ppvdigital/core.dart';
import 'package:ppvdigital/models/local/app_database.dart';
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

enum TarefaHabitoSortField {
  nome,
  agendamento,
  categoria,
  valor,
  meta,
  progresso,
  proximidadeFimCiclo,
  duracao,
}

class ListaHabitosTarefasWidget extends StatefulWidget {
  const ListaHabitosTarefasWidget({super.key, this.onlyTipo});

  final String? onlyTipo;

  @override
  State<ListaHabitosTarefasWidget> createState() =>
      ListaHabitosTarefasWidgetState();
}

class ListaHabitosTarefasWidgetState extends State<ListaHabitosTarefasWidget> {
  TarefaHabitoSortField _sortField = TarefaHabitoSortField.nome;
  bool _sortAscending = true;

  Duration _getCycleRemainingDuration(TarefaHabitoQtdModel qtd) {
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
    DateTime endPeriod = beginning;

    switch (reiniciaEmTipo) {
      case 'dias':
        final int blocks = beginningNowDiff.inDays ~/ reiniciaEmQtd;
        final startPeriod = beginning.add(
          Duration(days: blocks * reiniciaEmQtd),
        );
        endPeriod = startPeriod.add(Duration(days: reiniciaEmQtd));
      case 'semanas':
        final int blocks = beginningNowDiff.inDays ~/ (7 * reiniciaEmQtd);
        final startPeriod = beginning.add(
          Duration(days: blocks * 7 * reiniciaEmQtd),
        );
        endPeriod = startPeriod.add(Duration(days: 7 * reiniciaEmQtd));
      case 'meses':
        final int monthDiff =
            (now.year - beginning.year) * 12 + (now.month - beginning.month);
        final int blocks = monthDiff ~/ reiniciaEmQtd;
        final startPeriod = DateTime(
          beginning.year,
          beginning.month + (blocks * reiniciaEmQtd),
          beginning.day,
        );
        endPeriod = DateTime(
          startPeriod.year,
          startPeriod.month + reiniciaEmQtd,
          startPeriod.day,
        );
      case 'anos':
        final int yearDiff = now.year - beginning.year;
        final int blocks = yearDiff ~/ reiniciaEmQtd;
        final startPeriod = DateTime(
          beginning.year + (blocks * reiniciaEmQtd),
          beginning.month,
          beginning.day,
        );
        endPeriod = DateTime(
          startPeriod.year + reiniciaEmQtd,
          startPeriod.month,
          startPeriod.day,
        );
      default:
        final int blocks = beginningNowDiff.inDays ~/ reiniciaEmQtd;
        final startPeriod = beginning.add(
          Duration(days: blocks * reiniciaEmQtd),
        );
        endPeriod = startPeriod.add(Duration(days: reiniciaEmQtd));
    }

    return endPeriod.difference(now);
  }

  void _sortList(List<TarefaHabitoModel> list) {
    list.sort((a, b) {
      int cmp = 0;
      switch (_sortField) {
        case TarefaHabitoSortField.nome:
          cmp = a.nome.toLowerCase().compareTo(b.nome.toLowerCase());
        case TarefaHabitoSortField.agendamento:
          final aDate = a.agendamento ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = b.agendamento ?? DateTime.fromMillisecondsSinceEpoch(0);
          cmp = aDate.compareTo(bDate);
        case TarefaHabitoSortField.categoria:
          final aCat =
              a.tarefasHabitosQtd.firstOrNull?.categoriasTarefasHabitos?.nome ??
              '';
          final bCat =
              b.tarefasHabitosQtd.firstOrNull?.categoriasTarefasHabitos?.nome ??
              '';
          cmp = aCat.toLowerCase().compareTo(bCat.toLowerCase());
        case TarefaHabitoSortField.valor:
          final aVal = a.tarefasHabitosQtd.firstOrNull?.valor ?? 0.0;
          final bVal = b.tarefasHabitosQtd.firstOrNull?.valor ?? 0.0;
          cmp = aVal.compareTo(bVal);
        case TarefaHabitoSortField.meta:
          final aMeta = a.tarefasHabitosQtd.firstOrNull?.metaVezes ?? 0;
          final bMeta = b.tarefasHabitosQtd.firstOrNull?.metaVezes ?? 0;
          cmp = aMeta.compareTo(bMeta);
        case TarefaHabitoSortField.progresso:
          final aQtd = a.tarefasHabitosQtd.firstOrNull;
          final bQtd = b.tarefasHabitosQtd.firstOrNull;
          final aProg = aQtd != null && aQtd.metaVezes > 0
              ? (aQtd.vezesPraticado / aQtd.metaVezes)
              : 0.0;
          final bProg = bQtd != null && bQtd.metaVezes > 0
              ? (bQtd.vezesPraticado / bQtd.metaVezes)
              : 0.0;
          cmp = aProg.compareTo(bProg);
        case TarefaHabitoSortField.proximidadeFimCiclo:
          final aQtd = a.tarefasHabitosQtd.firstOrNull;
          final bQtd = b.tarefasHabitosQtd.firstOrNull;
          final aDur = aQtd != null
              ? _getCycleRemainingDuration(aQtd)
              : const Duration(days: 999999);
          final bDur = bQtd != null
              ? _getCycleRemainingDuration(bQtd)
              : const Duration(days: 999999);
          cmp = aDur.compareTo(bDur);
        case TarefaHabitoSortField.duracao:
          final aDur = a.duration ?? 0;
          final bDur = b.duration ?? 0;
          cmp = aDur.compareTo(bDur);
      }
      return _sortAscending ? cmp : -cmp;
    });
  }

  Widget _buildSortHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String fieldLabel = '';
    switch (_sortField) {
      case TarefaHabitoSortField.nome:
        fieldLabel = 'Nome';
      case TarefaHabitoSortField.agendamento:
        fieldLabel = 'Data de Agendamento';
      case TarefaHabitoSortField.categoria:
        fieldLabel = 'Categoria';
      case TarefaHabitoSortField.valor:
        fieldLabel = 'Valor';
      case TarefaHabitoSortField.meta:
        fieldLabel = 'Meta';
      case TarefaHabitoSortField.progresso:
        fieldLabel = 'Progresso';
      case TarefaHabitoSortField.proximidadeFimCiclo:
        fieldLabel = 'Fim do Ciclo';
      case TarefaHabitoSortField.duracao:
        fieldLabel = 'Duração';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            widget.onlyTipo == 'tarefa'
                ? 'Minhas Tarefas'
                : widget.onlyTipo == 'habito'
                ? 'Meus Hábitos'
                : 'Tarefas e Hábitos',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ord.: $fieldLabel',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              PopupMenuButton<TarefaHabitoSortField>(
                icon: const Icon(Icons.sort, size: 20),
                tooltip: 'Escolher campo de ordenação',
                onSelected: (field) {
                  setState(() {
                    _sortField = field;
                  });
                  _savePreferences();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: TarefaHabitoSortField.nome,
                    child: Text('Nome'),
                  ),
                  const PopupMenuItem(
                    value: TarefaHabitoSortField.agendamento,
                    child: Text('Data de Agendamento'),
                  ),
                  const PopupMenuItem(
                    value: TarefaHabitoSortField.categoria,
                    child: Text('Categoria'),
                  ),
                  const PopupMenuItem(
                    value: TarefaHabitoSortField.valor,
                    child: Text('Valor'),
                  ),
                  const PopupMenuItem(
                    value: TarefaHabitoSortField.meta,
                    child: Text('Meta de Vezes'),
                  ),
                  const PopupMenuItem(
                    value: TarefaHabitoSortField.progresso,
                    child: Text('Progresso'),
                  ),
                  const PopupMenuItem(
                    value: TarefaHabitoSortField.proximidadeFimCiclo,
                    child: Text('Proximidade do Fim de Ciclo'),
                  ),
                  const PopupMenuItem(
                    value: TarefaHabitoSortField.duracao,
                    child: Text('Duração'),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(
                  _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 18,
                ),
                tooltip: _sortAscending
                    ? 'Ordem Crescente'
                    : 'Ordem Decrescente',
                onPressed: () {
                  setState(() {
                    _sortAscending = !_sortAscending;
                  });
                  _savePreferences();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _loadPreferences() async {
    try {
      final keySuffix = widget.onlyTipo ?? 'all';

      final savedFieldIndexStrSetting =
          await (Core.database.select(Core.database.appSettings)..where(
                (t) => t.key.equals(
                  'pref_tarefa_habito_sort_field_index_str_$keySuffix',
                ),
              ))
              .getSingleOrNull();
      final savedFieldIndexStr = savedFieldIndexStrSetting?.value;

      final savedFieldStrSetting =
          await (Core.database.select(Core.database.appSettings)..where(
                (t) => t.key.equals('pref_tarefa_habito_sort_field_$keySuffix'),
              ))
              .getSingleOrNull();
      final savedFieldStr = savedFieldStrSetting?.value;

      final savedAscendingStrSetting =
          await (Core.database.select(Core.database.appSettings)..where(
                (t) => t.key.equals(
                  'pref_tarefa_habito_sort_ascending_str_$keySuffix',
                ),
              ))
              .getSingleOrNull();
      final savedAscendingStr = savedAscendingStrSetting?.value;

      debugPrint(
        'SORT PERSISTENCE: Loaded raw values - savedFieldIndexStr: $savedFieldIndexStr, savedFieldStr: $savedFieldStr, savedAscendingStr: $savedAscendingStr',
      );

      if (!mounted) return;

      setState(() {
        if (savedFieldIndexStr != null) {
          final index = int.tryParse(savedFieldIndexStr);
          if (index != null &&
              index >= 0 &&
              index < TarefaHabitoSortField.values.length) {
            _sortField = TarefaHabitoSortField.values[index];
          }
        } else if (savedFieldStr != null) {
          _sortField = TarefaHabitoSortField.values.firstWhere(
            (e) => e.toString() == savedFieldStr,
            orElse: () => TarefaHabitoSortField.nome,
          );
        }

        if (savedAscendingStr != null) {
          _sortAscending = savedAscendingStr == 'true';
        }
      });
      debugPrint(
        'SORT PERSISTENCE: Set state applied - field: $_sortField, ascending: $_sortAscending',
      );
    } catch (e) {
      debugPrint('SORT PERSISTENCE: Error loading preferences: $e');
    }
  }

  Future<void> _savePreferences() async {
    try {
      final keySuffix = widget.onlyTipo ?? 'all';

      debugPrint(
        'SORT PERSISTENCE: Saving preferences. Current values - field: $_sortField (index: ${_sortField.index}), ascending: $_sortAscending',
      );

      final indexSetting = AppSettingsCompanion.insert(
        key: 'pref_tarefa_habito_sort_field_index_str_$keySuffix',
        value: _sortField.index.toString(),
      );

      final ascSetting = AppSettingsCompanion.insert(
        key: 'pref_tarefa_habito_sort_ascending_str_$keySuffix',
        value: _sortAscending.toString(),
      );

      final legacyIndexSetting = AppSettingsCompanion.insert(
        key: 'pref_tarefa_habito_sort_field_index_$keySuffix',
        value: _sortField.index.toString(),
      );

      final legacyFieldSetting = AppSettingsCompanion.insert(
        key: 'pref_tarefa_habito_sort_field_$keySuffix',
        value: _sortField.toString(),
      );

      final legacyAscSetting = AppSettingsCompanion.insert(
        key: 'pref_tarefa_habito_sort_ascending_$keySuffix',
        value: _sortAscending.toString(),
      );

      await Core.database.transaction(() async {
        await Core.database
            .into(Core.database.appSettings)
            .insert(indexSetting, mode: InsertMode.insertOrReplace);
        await Core.database
            .into(Core.database.appSettings)
            .insert(ascSetting, mode: InsertMode.insertOrReplace);
        await Core.database
            .into(Core.database.appSettings)
            .insert(legacyIndexSetting, mode: InsertMode.insertOrReplace);
        await Core.database
            .into(Core.database.appSettings)
            .insert(legacyFieldSetting, mode: InsertMode.insertOrReplace);
        await Core.database
            .into(Core.database.appSettings)
            .insert(legacyAscSetting, mode: InsertMode.insertOrReplace);
      });

      debugPrint('SORT PERSISTENCE: Preferences saved successfully.');
    } catch (e) {
      debugPrint('SORT PERSISTENCE: Error saving preferences: $e');
    }
  }

  final double width = 260.0;
  final double height = 120.0;
  static int? qtdItems;

  final Set<String> _animatingCompletedTaskIds = {};

  @override
  void initState() {
    super.initState();
    TarefasHabitosController.tarefasHabitosFuture = Core
        .tarefasHabitosController
        .loadDocuments();
    _loadPreferences();
  }

  @override
  void didUpdateWidget(covariant ListaHabitosTarefasWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.onlyTipo != widget.onlyTipo) {
      _loadPreferences();
    }
  }

  void _completeTask(String taskId) {
    setState(() {
      _animatingCompletedTaskIds.add(taskId);
    });

    // Delay database/MobX update by 500ms to allow fade-out animation to complete
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Core.tarefasHabitosController.completeTarefa(taskId);
        setState(() {
          _animatingCompletedTaskIds.remove(taskId);
        });
      }
    });
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
      case 'semanas':
        final int blocks = beginningNowDiff.inDays ~/ (7 * reiniciaEmQtd);
        startPeriod = beginning.add(Duration(days: blocks * 7 * reiniciaEmQtd));
        endPeriod = startPeriod.add(Duration(days: 7 * reiniciaEmQtd));
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
      default:
        final int blocks = beginningNowDiff.inDays ~/ reiniciaEmQtd;
        startPeriod = beginning.add(Duration(days: blocks * reiniciaEmQtd));
        endPeriod = startPeriod.add(Duration(days: reiniciaEmQtd));
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

  String _formatDuration(int? minutes) {
    if (minutes == null || minutes <= 0) return '';
    final int hours = minutes ~/ 60;
    final int mins = minutes % 60;
    if (hours > 0) {
      if (mins > 0) {
        return '${hours}h${mins}m';
      } else {
        return '${hours}h';
      }
    }
    return '${mins}m';
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
              final rawList = Core.tarefasHabitosController.tarefasHabitosList;

              // Filter list based on onlyTipo parameter
              final list = rawList.where((item) {
                if (widget.onlyTipo != null && item.tipo != widget.onlyTipo) {
                  return false;
                }
                if (item.tipo == 'tarefa') {
                  // Show tasks only if they are not completed OR are currently animating out
                  return !item.concluida ||
                      _animatingCompletedTaskIds.contains(item.id);
                }
                return true;
              }).toList();

              if (list.isEmpty) {
                return Column(
                  children: [
                    _buildSortHeader(),
                    Expanded(
                      child: Center(
                        child: Text(
                          widget.onlyTipo == 'tarefa'
                              ? 'Nenhuma tarefa pendente.'
                              : widget.onlyTipo == 'habito'
                              ? 'Nenhum hábito cadastrado.'
                              : 'Nenhuma tarefa ou hábito cadastrado.',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }

              _sortList(list);

              return Column(
                children: [
                  _buildSortHeader(),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      child: GridView.builder(
                        gridDelegate: MediaQuery.of(context).size.width < 600
                            ? SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 1,
                                mainAxisExtent: height,
                                mainAxisSpacing: 10.0,
                                crossAxisSpacing: 10.0,
                              )
                            : SliverGridDelegateWithMaxCrossAxisExtent(
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
                          final bool showAnimation =
                              progress >= 0.25 &&
                              !metaBatida &&
                              item.tipo == 'habito';
                          final bool isAnimatingOut = _animatingCompletedTaskIds
                              .contains(item.id);

                          return LayoutBuilder(
                            builder:
                                (
                                  BuildContext layoutContext,
                                  BoxConstraints constraints,
                                ) {
                                  return Observer(
                                    warnWhenNoObservables: true,
                                    name: 'tarefas_habitos',
                                    builder: (observerContext) {
                                      final List<Widget> children = [];
                                      final Color habitColor = Core
                                          .tarefasHabitosController
                                          .habitColor
                                          .value;
                                      final Color taskColor = Core
                                          .tarefasHabitosController
                                          .taskColor
                                          .value;
                                      final categoria = item
                                          .tarefasHabitosQtd
                                          .firstOrNull
                                          ?.categoriasTarefasHabitos;

                                      for (
                                        int i = 0;
                                        i < item.tarefasHabitosQtd.length;
                                        i++
                                      ) {
                                        final int greaterMeta = item
                                            .tarefasHabitosQtd
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
                                            ? habitColor.withValues(alpha: 0.08)
                                            : taskColor.withValues(alpha: 0.08);

                                        // Para tarefas, não preencher com cor (manter progresso em 0.0)
                                        if (item.tipo == 'habito') {
                                          children.add(
                                            Expanded(
                                              child: LiquidCustomProgressIndicator(
                                                value:
                                                    item
                                                        .tarefasHabitosQtd[i]
                                                        .vezesPraticado *
                                                    1.05 /
                                                    greaterMeta,
                                                backgroundColor:
                                                    indicatorBgColor,
                                                valueColor: liquidColor != null
                                                    ? AlwaysStoppedAnimation(
                                                        liquidColor,
                                                      )
                                                    : null,
                                                direction: Axis.vertical,
                                                shapePath: Path()
                                                  ..addRRect(
                                                    RRect.fromRectAndCorners(
                                                      Rect.fromLTWH(
                                                        i == 0 ? 5 : 0,
                                                        5,
                                                        ((constraints.maxWidth -
                                                                10) /
                                                            item
                                                                .tarefasHabitosQtd
                                                                .length),
                                                        constraints.maxHeight -
                                                            10,
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
                                                      bottomLeft:
                                                          Radius.circular(
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
                                      }

                                      final cardWidget = Stack(
                                        children: [
                                          Row(children: children),
                                          Card(
                                            clipBehavior: Clip.hardEdge,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(22),
                                              side: BorderSide(
                                                color: item.tipo == 'habito'
                                                    ? habitColor.withValues(
                                                        alpha: 0.4,
                                                      )
                                                    : taskColor.withValues(
                                                        alpha: 0.4,
                                                      ),
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
                                                    'lastRoute': Routefly
                                                        .currentUri
                                                        .path,
                                                    'tarefaHabito': item,
                                                  },
                                                );
                                              },
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12.0,
                                                      vertical: 10.0,
                                                    ),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
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
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize:
                                                                        13.0,
                                                                  ),
                                                                  maxLines: 2,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                width: 4.0,
                                                              ),
                                                              // Subtle Type Badge replaced by Duration Chip
                                                              if (item.duration !=
                                                                      null &&
                                                                  item.duration! >
                                                                      0) ...[
                                                                Container(
                                                                  padding:
                                                                      const EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            6.0,
                                                                        vertical:
                                                                            2.0,
                                                                      ),
                                                                  decoration: BoxDecoration(
                                                                    color:
                                                                        (item.tipo ==
                                                                                    'habito'
                                                                                ? habitColor
                                                                                : taskColor)
                                                                            .withValues(
                                                                              alpha: 0.2,
                                                                            ),
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          8.0,
                                                                        ),
                                                                  ),
                                                                  child: Row(
                                                                    mainAxisSize:
                                                                        MainAxisSize
                                                                            .min,
                                                                    children: [
                                                                      Icon(
                                                                        Icons
                                                                            .access_time,
                                                                        size:
                                                                            10.0,
                                                                        color:
                                                                            item.tipo ==
                                                                                'habito'
                                                                            ? habitColor
                                                                            : taskColor,
                                                                      ),
                                                                      const SizedBox(
                                                                        width:
                                                                            3.0,
                                                                      ),
                                                                      Text(
                                                                        _formatDuration(
                                                                          item.duration,
                                                                        ),
                                                                        style: TextStyle(
                                                                          fontSize:
                                                                              9.0,
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                          color:
                                                                              item.tipo ==
                                                                                  'habito'
                                                                              ? habitColor
                                                                              : taskColor,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ],
                                                            ],
                                                          ),
                                                          if (item.tipo ==
                                                                  'tarefa' &&
                                                              categoria !=
                                                                  null) ...[
                                                            const SizedBox(
                                                              height: 4.0,
                                                            ),
                                                            Row(
                                                              children: [
                                                                Container(
                                                                  padding:
                                                                      const EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            6.0,
                                                                        vertical:
                                                                            2.0,
                                                                      ),
                                                                  decoration: BoxDecoration(
                                                                    color: categoria
                                                                        .cor
                                                                        .withValues(
                                                                          alpha:
                                                                              0.15,
                                                                        ),
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          6.0,
                                                                        ),
                                                                    border: Border.all(
                                                                      color: categoria
                                                                          .cor
                                                                          .withValues(
                                                                            alpha:
                                                                                0.5,
                                                                          ),
                                                                    ),
                                                                  ),
                                                                  child: Text(
                                                                    categoria
                                                                        .nome,
                                                                    style: TextStyle(
                                                                      fontSize:
                                                                          10.0,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: categoria
                                                                          .cor,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ],
                                                          const SizedBox(
                                                            height: 2.0,
                                                          ),
                                                          if (item.tipo ==
                                                                  'tarefa' &&
                                                              item.agendamento !=
                                                                  null) ...[
                                                            Row(
                                                              children: [
                                                                const Icon(
                                                                  Icons
                                                                      .calendar_today,
                                                                  size: 11.0,
                                                                  color: Colors
                                                                      .black54,
                                                                ),
                                                                const SizedBox(
                                                                  width: 4.0,
                                                                ),
                                                                Text(
                                                                  '${item.agendamento!.day.toString().padLeft(2, '0')}/${item.agendamento!.month.toString().padLeft(2, '0')} ${item.agendamento!.hour.toString().padLeft(2, '0')}:${item.agendamento!.minute.toString().padLeft(2, '0')}',
                                                                  style: const TextStyle(
                                                                    fontSize:
                                                                        10.0,
                                                                    color: Colors
                                                                        .white54,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ],
                                                          const SizedBox(
                                                            height: 2.0,
                                                          ),
                                                          if (item.tipo ==
                                                              'habito')
                                                            Text(
                                                              _getProgressText(
                                                                item,
                                                              ),
                                                              style: const TextStyle(
                                                                fontSize: 11.5,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                color: Colors
                                                                    .white70,
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4.0),
                                                    IconButton(
                                                      padding: EdgeInsets.zero,
                                                      constraints:
                                                          const BoxConstraints(),
                                                      onPressed: () {
                                                        if (item.tipo ==
                                                            'tarefa') {
                                                          _completeTask(
                                                            item.id,
                                                          );
                                                        } else {
                                                          Core.tarefasHabitosController
                                                              .incrementQtdHabito(
                                                                item.id,
                                                              );
                                                        }
                                                      },
                                                      icon: Icon(
                                                        item.tipo == 'tarefa'
                                                            ? Icons
                                                                  .check_circle_outline
                                                            : Icons.add_circle,
                                                        size: 32.0,
                                                        color:
                                                            item.tipo ==
                                                                'habito'
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

                                      if (isAnimatingOut) {
                                        return cardWidget.animate().fade(
                                          begin: 1.0,
                                          end: 0.0,
                                          duration: const Duration(
                                            milliseconds: 500,
                                          ),
                                        );
                                      } else if (showAnimation) {
                                        return cardWidget
                                            .animate(
                                              onPlay: (controller) => controller
                                                  .repeat(reverse: true),
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
                    ),
                  ),
                ],
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
