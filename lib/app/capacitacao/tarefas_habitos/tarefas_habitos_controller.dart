import 'dart:async';
import 'dart:developer';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:drift/drift.dart' hide Column, Query;
import 'package:flutter/material.dart' hide Row;
import 'package:mobx/mobx.dart' as mobx;
import 'package:ppvdigital/app/capacitacao/tarefas_habitos/historico_controller.dart';
import 'package:ppvdigital/core.dart';
import 'package:ppvdigital/models/categorias_tarefas_habitos_model.dart';
import 'package:ppvdigital/models/historico_item_model.dart';
import 'package:ppvdigital/models/local/app_database.dart';
import 'package:ppvdigital/models/tarefas_habitos_model.dart';
import 'package:ppvdigital/models/tarefas_habitos_qtd_model.dart';
import 'package:ppvdigital/repositories/tarefa_habito_repository.dart';

extension TarefasHabitosTransformList on List<dynamic>? {
  List<TarefaHabitoQtdModel> toTarefaHabitoQtdModelList([
    List<HistoricoItemModel>? tarefaHabitoHistoricoList,
  ]) {
    return this?.map<TarefaHabitoQtdModel>((e2) {
          final Map<String, dynamic> e2Map = e2 is Map
              ? Map<String, dynamic>.from(e2)
              : <String, dynamic>{};
          List<HistoricoItemModel> withPeriodFilter = [];
          final rawCreatedAt =
              e2Map[r'$createdAt'] ??
              e2Map['createdAt'] ??
              e2Map['dataCriacao'];
          DateTime parsedBeginning = DateTime.now();
          if (rawCreatedAt is String) {
            parsedBeginning =
                DateTime.tryParse(rawCreatedAt)?.toLocal() ?? DateTime.now();
          } else if (rawCreatedAt is int) {
            parsedBeginning = DateTime.fromMillisecondsSinceEpoch(
              rawCreatedAt,
            ).toLocal();
          }
          DateTime beginning = DateTime(
            parsedBeginning.year,
            parsedBeginning.month,
            parsedBeginning.day,
          );
          final String reiniciaEmTipo =
              (e2Map['reiniciaEmTipo'] as String?) ?? 'dias';
          final int reiniciaEmQtd = (e2Map['reiniciaEmQtd'] as int?) ?? 1;
          final DateTime nowToday = DateTime.now();
          final DateTime now = DateTime(
            nowToday.year,
            nowToday.month,
            nowToday.day,
          );

          if (tarefaHabitoHistoricoList != null &&
              tarefaHabitoHistoricoList.isNotEmpty) {
            final Duration beginningNowDiff = now.difference(beginning);
            late DateTime startPeriod;

            switch (reiniciaEmTipo) {
              case 'dias':
                final Duration durationToStartPeriod = Duration(
                  days: beginningNowDiff.inDays ~/ reiniciaEmQtd,
                );
                beginning = DateTime(
                  beginning.year,
                  beginning.month,
                  beginning.day,
                );
                startPeriod = beginning.add(durationToStartPeriod);
              case 'semanas':
                final Duration durationToStartPeriod = Duration(
                  days:
                      (beginningNowDiff.inDays ~/ (7 * reiniciaEmQtd)) * 7 -
                      (beginning.weekday - 1),
                );
                beginning = DateTime(
                  beginning.year,
                  beginning.month,
                  beginning.day,
                );
                startPeriod = beginning.add(durationToStartPeriod);
              case 'meses':
                final int monthDiff =
                    (now.year - beginning.year) * 12 +
                    (now.month - beginning.month);
                startPeriod = DateTime(
                  beginning.year,
                  now.month - (monthDiff % reiniciaEmQtd),
                );
              case 'anos':
                final int yearDiff = now.year - beginning.year;
                startPeriod = DateTime(now.year - (yearDiff % reiniciaEmQtd));
              default:
                final Duration durationToStartPeriod = Duration(
                  days: beginningNowDiff.inDays ~/ reiniciaEmQtd,
                );
                beginning = DateTime(
                  beginning.year,
                  beginning.month,
                  beginning.day,
                );
                startPeriod = beginning.add(durationToStartPeriod);
            }

            withPeriodFilter = tarefaHabitoHistoricoList.where((el) {
              final DateTime elDate = DateTime(
                el.createdAt.year,
                el.createdAt.month,
                el.createdAt.day,
              );
              return elDate.isAtSameMomentAs(startPeriod) ||
                  elDate.isAfter(startPeriod);
            }).toList();
          }

          final String? collectionId = e2Map[r'$collectionId'] as String?;
          if (collectionId != null) {
            TarefasHabitosController.tarefasHabitosQtdCollectionId =
                collectionId;
          }

          final Map<String, dynamic>? rawCategoryMap =
              e2Map['categoriasTarefasHabitos'] is Map
              ? Map<String, dynamic>.from(
                  e2Map['categoriasTarefasHabitos'] as Map,
                )
              : null;

          return TarefaHabitoQtdModel(
            id: (e2Map[r'$id'] ?? e2Map['id'] ?? '') as String,
            usuario: (e2Map['usuario'] as String?) ?? '',
            metaVezes: (e2Map['metaVezes'] as int?) ?? 1,
            categoriasTarefasHabitos:
                TarefasHabitosTransformDocumentList.toCategoriasTarefasHabitosModelList(
                  rawCategoryMap,
                ),
            valor: (e2Map['valor'] as num?) ?? 1.0,
            reiniciaEmQtd: reiniciaEmQtd,
            reiniciaEmTipo: reiniciaEmTipo,
            vezesPraticado:
                withPeriodFilter.length * ((e2Map['valor'] as num?) ?? 1.0),
            createdAt: beginning,
          );
        }).toList() ??
        [];
  }
}

extension TarefasHabitosTransformDocumentList on List<Row> {
  Future<List<TarefaHabitoModel>> toTarefaHabitoModelList(
    Databases databases,
    String usuarioId,
  ) async {
    final List<TarefaHabitoModel> temp = [];
    final TablesDB tablesDB = TablesDB(databases.client);

    final RowList res = await tablesDB.listRows(
      databaseId: Core.databaseId,
      tableId: Core.tableHistoricoTarefasHabitos,
      queries: [
        Query.equal('usuario', usuarioId),
        Query.orderDesc(r'$createdAt'),
        Query.limit(5000),
      ],
    );

    final List<HistoricoItemModel> allHistoryItems = res.rows
        .toHistoricoModelList();

    for (final e1 in this) {
      final List<HistoricoItemModel> tarefaHabitoQtdList = allHistoryItems
          .where((item) => item.tarefasEHabitos.id == e1.$id)
          .toList();

      temp.add(
        TarefaHabitoModel(
          id: e1.$id,
          nome: (e1.data['nome'] as String?) ?? '',
          usuario: (e1.data['usuario'] as String?) ?? '',
          tipo: (e1.data['tipo'] as String?) ?? '',
          agendamento: DateTime.tryParse(
            (e1.data['agendamento'] as String?) ?? '',
          ),
          concluida: (e1.data['concluida'] as bool?) ?? false,
          tarefasHabitosQtd: (e1.data['tarefasHabitosQtds'] as List<dynamic>?)
              .toTarefaHabitoQtdModelList(tarefaHabitoQtdList),
          duration: e1.data['duration'] is num
              ? (e1.data['duration'] as num).toInt()
              : null,
        ),
      );
    }

    return temp;
  }

  static CategoriasTarefasHabitosModel? toCategoriasTarefasHabitosModelList(
    Map<String, dynamic>? map,
  ) {
    return map != null
        ? CategoriasTarefasHabitosModel(
            id: (map[r'$id'] ?? map['id'] ?? '') as String,
            usuario: (map['usuario'] as String?) ?? '',
            nome: (map['nome'] as String?) ?? '',
            cor: HexColor.fromHex((map['cor'] as String?) ?? '#000000'),
            pai: map['pai'] as String?,
          )
        : null;
  }
}

class TarefasHabitosController {
  // Constructor
  TarefasHabitosController(this.repository) {
    loadConfiguredColors();
  }
  final TarefaHabitoRepository repository;

  static String? tarefasHabitosQtdCollectionId;
  static Future<void>? tarefasHabitosFuture;

  final mobx.ObservableList<TarefaHabitoModel> _tarefasHabitosList =
      mobx.ObservableList<TarefaHabitoModel>(name: 'tarefasHabitosList');
  List<TarefaHabitoModel> get tarefasHabitosList =>
      _tarefasHabitosList.toList();

  final mobx.Observable<Color> habitColor = mobx.Observable<Color>(
    Colors.tealAccent,
    name: 'habitColor',
  );
  final mobx.Observable<Color> taskColor = mobx.Observable<Color>(
    Colors.blueAccent,
    name: 'taskColor',
  );

  Future<void> loadConfiguredColors() async {
    final habitSetting = await (Core.database.select(
      Core.database.appSettings,
    )..where((t) => t.key.equals('pref_habit_color'))).getSingleOrNull();
    final taskSetting = await (Core.database.select(
      Core.database.appSettings,
    )..where((t) => t.key.equals('pref_task_color'))).getSingleOrNull();

    mobx.runInAction(() {
      if (habitSetting != null) {
        habitColor.value = Color(int.parse(habitSetting.value, radix: 16));
      }
      if (taskSetting != null) {
        taskColor.value = Color(int.parse(taskSetting.value, radix: 16));
      }
    });
  }

  Future<void> setHabitColor(Color color) async {
    mobx.runInAction(() {
      habitColor.value = color;
    });
    try {
      final value = color.toARGB32().toRadixString(16);
      await Core.database
          .into(Core.database.appSettings)
          .insert(
            AppSettingsCompanion.insert(key: 'pref_habit_color', value: value),
            mode: InsertMode.insertOrReplace,
          );
    } catch (e) {
      log('Error saving habit color: $e');
    }
  }

  Future<void> setTaskColor(Color color) async {
    mobx.runInAction(() {
      taskColor.value = color;
    });
    try {
      final value = color.toARGB32().toRadixString(16);
      await Core.database
          .into(Core.database.appSettings)
          .insert(
            AppSettingsCompanion.insert(key: 'pref_task_color', value: value),
            mode: InsertMode.insertOrReplace,
          );
    } catch (e) {
      log('Error saving task color: $e');
    }
  }

  StreamSubscription? _tarefasHabitosSub;

  Future<bool> loadDocuments() async {
    return await mobx.runInAction(() async {
      try {
        if (Core.loginController.currentUser == null) {
          await Core.loginController.loadUser();
        }
        final String userId = Core.loginController.currentUser?.$id ?? '';

        // 1. Subscribe to Drift streams reactively
        _tarefasHabitosSub?.cancel();
        final stream = repository.watchTarefasEHabitos(usuarioId: userId);
        try {
          final firstData = await stream.first;
          mobx.runInAction(() {
            _tarefasHabitosList.clear();
            _tarefasHabitosList.addAll(firstData);
          });
        } catch (_) {}
        _tarefasHabitosSub = stream.listen((data) {
          mobx.runInAction(() {
            _tarefasHabitosList.clear();
            _tarefasHabitosList.addAll(data);
          });
        });

        // 2. Start remote sync in background (non-blocking)
        _syncRemoteDataInBackground(userId);

        return true;
      } on Exception catch (e) {
        log(e.toString());
        return false;
      }
    }, name: 'loadDocuments');
  }

  DateTime? _lastSyncTime;

  Future<void> _syncRemoteDataInBackground(String userId) async {
    final now = DateTime.now();
    if (_lastSyncTime != null &&
        now.difference(_lastSyncTime!) < const Duration(minutes: 3)) {
      return;
    }
    try {
      final String? lastSyncStr = await Core.database.getSetting('last_tarefas_habitos_sync_time');
      final DateTime? lastSyncedAt = lastSyncStr != null ? DateTime.tryParse(lastSyncStr) : null;

      await repository.getTarefasEHabitos(
        usuarioId: userId,
        lastSyncedAt: lastSyncedAt,
      );
      await repository.getHistorico(
        usuarioId: userId,
        lastSyncedAt: lastSyncedAt,
      );

      _lastSyncTime = now;
      await Core.database.setSetting('last_tarefas_habitos_sync_time', now.toIso8601String());
    } catch (e) {
      log('Background sync of habits failed: $e');
    }
  }

  void reset() {
    _tarefasHabitosSub?.cancel();
    mobx.runInAction(() {
      _tarefasHabitosList.clear();
    });
  }

  Future<void> incrementQtdHabito(String documentId) async {
    log('Começo');
    try {
      mobx.runInAction(() {
        final List<TarefaHabitoModel> temp = List<TarefaHabitoModel>.from(
          _tarefasHabitosList.toList(),
        );
        final TarefaHabitoModel found = temp.singleWhere(
          (el) => el.id == documentId,
        );
        for (final element in found.tarefasHabitosQtd) {
          element.vezesPraticado += element.valor;
        }
        _tarefasHabitosList.setAll(0, temp);

        repository.recordHistorico(
          foundId: found.id,
          usuarioId: Core.loginController.currentUser?.$id ?? '',
        );
      }, name: 'addQtdHabito');
    } on Exception catch (e) {
      log(e.toString());
    }
  }

  Future<void> completeTarefa(String documentId) async {
    try {
      mobx.runInAction(() {
        final List<TarefaHabitoModel> temp = List<TarefaHabitoModel>.from(
          _tarefasHabitosList.toList(),
        );
        final int index = temp.indexWhere((el) => el.id == documentId);
        if (index != -1) {
          final found = temp[index];
          for (final element in found.tarefasHabitosQtd) {
            element.vezesPraticado += element.valor;
          }
          temp[index] = found.copyWith(concluida: true);
          _tarefasHabitosList.clear();
          _tarefasHabitosList.addAll(temp);
        }

        final String userId = Core.loginController.currentUser?.$id ?? '';
        repository.recordHistorico(foundId: documentId, usuarioId: userId);
        repository.updateConcluida(documentId: documentId, concluida: true);
      }, name: 'completeTarefa');
    } on Exception catch (e) {
      log(e.toString());
    }
  }

  Future<bool> createTarefaHabito({
    required String nome,
    required String tipo,
    required List<Map<String, dynamic>> metas,
    DateTime? agendamento,
    int? duration,
  }) async {
    try {
      if (Core.loginController.currentUser == null) {
        await Core.loginController.loadUser();
      }
      final String user = Core.loginController.currentUser?.$id ?? '';

      final List<Map<String, dynamic>> metaDataList = metas
          .map(
            (meta) => {
              'metaVezes': meta['metaVezes'] as int,
              'categoriaId': meta['categoriaId'] as String?,
              'valor': meta['valor'] as num,
              'reiniciaEmQtd': meta['reiniciaEmQtd'] as int,
              'reiniciaEmTipo': meta['reiniciaEmTipo'] as String,
            },
          )
          .toList();

      await repository.createTarefaHabito(
        nome: nome,
        tipo: tipo,
        metas: metaDataList,
        agendamento: agendamento,
        duration: duration,
        usuarioId: user,
      );

      await loadDocuments();
      return true;
    } catch (e) {
      log('Error creating task/habit: $e');
      return false;
    }
  }

  Future<bool> updateTarefaHabito({
    required String id,
    required String nome,
    required String tipo,
    required List<Map<String, dynamic>> metas,
    required List<String> allExistingQtdRowIds,
    DateTime? agendamento,
    int? duration,
  }) async {
    try {
      if (Core.loginController.currentUser == null) {
        await Core.loginController.loadUser();
      }
      final String user = Core.loginController.currentUser?.$id ?? '';

      final List<Map<String, dynamic>> metaDataList = metas
          .map(
            (meta) => {
              'id': meta['id'] as String?,
              'metaVezes': meta['metaVezes'] as int,
              'categoriaId': meta['categoriaId'] as String?,
              'valor': meta['valor'] as num,
              'reiniciaEmQtd': meta['reiniciaEmQtd'] as int,
              'reiniciaEmTipo': meta['reiniciaEmTipo'] as String,
            },
          )
          .toList();

      await repository.updateTarefaHabito(
        id: id,
        nome: nome,
        tipo: tipo,
        metas: metaDataList,
        allExistingQtdRowIds: allExistingQtdRowIds,
        agendamento: agendamento,
        duration: duration,
        usuarioId: user,
      );

      await loadDocuments();
      return true;
    } catch (e) {
      log('Error updating task/habit: $e');
      return false;
    }
  }

  Future<bool> deleteTarefaHabito(String id, List<String> qtdRowIds) async {
    try {
      await repository.deleteTarefaHabito(id: id, qtdRowIds: qtdRowIds);

      await loadDocuments();
      return true;
    } catch (e) {
      log('Error deleting task/habit: $e');
      return false;
    }
  }
}
