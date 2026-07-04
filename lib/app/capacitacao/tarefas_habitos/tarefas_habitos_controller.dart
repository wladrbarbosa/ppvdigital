import 'dart:async';
import 'dart:developer';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter/material.dart' hide Row;
import 'package:mobx/mobx.dart' as mobx;
import 'package:ppvdigital/app/capacitacao/tarefas_habitos/historico_controller.dart';
import 'package:ppvdigital/core.dart';
import 'package:ppvdigital/models/categorias_tarefas_habitos_model.dart';
import 'package:ppvdigital/models/historico_item_model.dart';
import 'package:ppvdigital/models/tarefas_habitos_model.dart';
import 'package:ppvdigital/models/tarefas_habitos_qtd_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

extension TarefasHabitosTransformList on List<dynamic>? {
  List<TarefaHabitoQtdModel> toTarefaHabitoQtdModelList([
    List<HistoricoItemModel>? tarefaHabitoHistoricoList,
  ]) {
    return this?.map<TarefaHabitoQtdModel>((e2) {
          List<HistoricoItemModel> withPeriodFilter = [];
          DateTime parsedBeginning = DateTime.parse(
            ((e2 as Map<String, dynamic>)[r'$createdAt'] as String?) ?? '',
          ).toLocal();
          DateTime beginning = DateTime(
            parsedBeginning.year,
            parsedBeginning.month,
            parsedBeginning.day,
          );
          final String reiniciaEmTipo = e2['reiniciaEmTipo'] as String;
          final int reiniciaEmQtd = e2['reiniciaEmQtd'] as int;
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
                  days: (beginningNowDiff.inDays ~/ reiniciaEmQtd),
                );
                beginning = DateTime(
                  beginning.year,
                  beginning.month,
                  beginning.day,
                );
                startPeriod = beginning.add(durationToStartPeriod);
                break;
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
                break;
              case 'meses':
                final int monthDiff =
                    (now.year - beginning.year) * 12 +
                    (now.month - beginning.month);
                startPeriod = DateTime(
                  beginning.year,
                  now.month - (monthDiff % reiniciaEmQtd),
                  1,
                );
                break;
              case 'anos':
                final int yearDiff = now.year - beginning.year;
                startPeriod = DateTime(
                  now.year - (yearDiff % reiniciaEmQtd),
                  1,
                  1,
                );
                break;
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
                break;
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

          final String? collectionId = e2[r'$collectionId'] as String?;
          if (collectionId != null) {
            TarefasHabitosController.tarefasHabitosQtdCollectionId =
                collectionId;
          }

          return TarefaHabitoQtdModel(
            id: e2[r'$id'] as String,
            usuario: e2['usuario'] as String,
            metaVezes: e2['metaVezes'] as int,
            categoriasTarefasHabitos:
                TarefasHabitosTransformDocumentList.toCategoriasTarefasHabitosModelList(
                  e2['categoriasTarefasHabitos'] as Map<String, dynamic>?,
                ),
            valor: e2['valor'] as num,
            reiniciaEmQtd: reiniciaEmQtd,
            reiniciaEmTipo: reiniciaEmTipo,
            vezesPraticado: withPeriodFilter.length * (e2['valor'] as num),
            createdAt: beginning,
          );
        }).toList() ??
        [];
  }
}

extension TarefasHabitosTransformDocumentList on List<Row> {
  Future<List<TarefaHabitoModel>> toTarefaHabitoModelList(
    Databases databases,
  ) async {
    final List<TarefaHabitoModel> temp = [];
    final TablesDB tablesDB = TablesDB(databases.client);

    final RowList res = await tablesDB.listRows(
      databaseId: Core.databaseId,
      tableId: Core.tableHistoricoTarefasHabitos,
      queries: [
        Query.equal('usuario', Core.loginController.currentUser?.$id ?? ''),
        Query.select([
          '*',
          'tarefasEHabitos.*',
          'tarefasEHabitos.tarefasHabitosQtds.*',
          'tarefasEHabitos.tarefasHabitosQtds.categoriasTarefasHabitos.*',
        ]),
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
          nome: e1.data['nome'] as String,
          usuario: e1.data['usuario'] as String,
          tipo: e1.data['tipo'] as String,
          agendamento: DateTime.tryParse(
            (e1.data['agendamento'] as String?) ?? '',
          ),
          concluida: e1.data['concluida'] as bool,
          tarefasHabitosQtd: (e1.data['tarefasHabitosQtds'] as List<dynamic>?)
              .toTarefaHabitoQtdModelList(tarefaHabitoQtdList),
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
            id: map['\$id'] as String,
            usuario: map['usuario'] as String,
            nome: map['nome'] as String,
            cor: HexColor.fromHex(map['cor'] as String),
            pai: map['pai'] as String?,
          )
        : null;
  }
}

class TarefasHabitosController {
  // Constructor
  TarefasHabitosController() {
    init();
    loadConfiguredColors();
  }

  static String? tarefasHabitosQtdCollectionId;

  late final Databases databases;
  final mobx.ObservableList<TarefaHabitoModel> _tarefasHabitosList =
      mobx.ObservableList<TarefaHabitoModel>(name: 'tarefasHabitosList');
  List<TarefaHabitoModel> get tarefasHabitosList =>
      _tarefasHabitosList.toList();
  static Future<void>? tarefasHabitosFuture;

  final mobx.Observable<Color> habitColor = mobx.Observable<Color>(
    Colors.tealAccent,
    name: 'habitColor',
  );
  final mobx.Observable<Color> taskColor = mobx.Observable<Color>(
    Colors.blueAccent,
    name: 'taskColor',
  );

  Future<void> loadConfiguredColors() async {
    final prefs = await SharedPreferences.getInstance();
    final habitColorHex = prefs.getString('pref_habit_color');
    final taskColorHex = prefs.getString('pref_task_color');

    mobx.runInAction(() {
      if (habitColorHex != null) {
        habitColor.value = Color(int.parse(habitColorHex, radix: 16));
      }
      if (taskColorHex != null) {
        taskColor.value = Color(int.parse(taskColorHex, radix: 16));
      }
    });
  }

  Future<void> setHabitColor(Color color) async {
    mobx.runInAction(() {
      habitColor.value = color;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pref_habit_color', color.value.toRadixString(16));
    } catch (e) {
      log('Error saving habit color: $e');
    }
  }

  Future<void> setTaskColor(Color color) async {
    mobx.runInAction(() {
      taskColor.value = color;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pref_task_color', color.value.toRadixString(16));
    } catch (e) {
      log('Error saving task color: $e');
    }
  }

  // Initialize the Appwrite client
  void init() {
    databases = Databases(Core.client);
  }

  Future<bool> loadDocuments() async {
    return await mobx.runInAction(() async {
      try {
        if (Core.loginController.currentUser == null) {
          await Core.loginController.loadUser();
        }
        final TablesDB tablesDB = TablesDB(databases.client);
        final RowList tarefasHabitosDocs = await tablesDB.listRows(
          databaseId: Core.databaseId,
          tableId: Core.tableTarefasEHabitos,
          queries: [
            Query.select([
              '*',
              'tarefasHabitosQtds.*',
              'tarefasHabitosQtds.categoriasTarefasHabitos.*',
            ]),
            Query.equal('usuario', [
              Core.loginController.currentUser?.$id ?? '',
            ]),
          ],
        );

        _tarefasHabitosList.clear();
        _tarefasHabitosList.addAll(
          await tarefasHabitosDocs.rows.toTarefaHabitoModelList(databases),
        );
        return true;
      } on AppwriteException catch (e) {
        log(e.toString());
        return false;
      } on Exception catch (e) {
        log(e.toString());
        return false;
      }
    }, name: 'loadDocuments');
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
        final TablesDB tablesDB = TablesDB(databases.client);
        tablesDB.createRow(
          databaseId: Core.databaseId,
          tableId: Core.tableHistoricoTarefasHabitos,
          rowId: ID.unique(),
          data: {
            'tarefasEHabitos': found.id,
            'usuario': Core.loginController.currentUser?.$id ?? '',
          },
        );
      }, name: 'addQtdHabito');
    } on AppwriteException catch (e) {
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

        final TablesDB tablesDB = TablesDB(databases.client);
        tablesDB.createRow(
          databaseId: Core.databaseId,
          tableId: Core.tableHistoricoTarefasHabitos,
          rowId: ID.unique(),
          data: {
            'tarefasEHabitos': documentId,
            'usuario': Core.loginController.currentUser?.$id ?? '',
          },
        );

        tablesDB.updateRow(
          databaseId: Core.databaseId,
          tableId: Core.tableTarefasEHabitos,
          rowId: documentId,
          data: {
            'concluida': true,
          },
        );
      }, name: 'completeTarefa');
    } on AppwriteException catch (e) {
      log(e.toString());
    }
  }

  Future<bool> createTarefaHabito({
    required String nome,
    required String tipo,
    required List<Map<String, dynamic>> metas,
    DateTime? agendamento,
  }) async {
    try {
      if (Core.loginController.currentUser == null) {
        await Core.loginController.loadUser();
      }
      final String user = Core.loginController.currentUser?.$id ?? '';
      final TablesDB tablesDB = TablesDB(databases.client);

      final String qtdCollectionId =
          tarefasHabitosQtdCollectionId ?? Core.tableTarefasHabitosQtds;

      final List<String> qtdRowIds = [];

      for (final meta in metas) {
        final Row qtdRow = await tablesDB.createRow(
          databaseId: Core.databaseId,
          tableId: qtdCollectionId,
          rowId: ID.unique(),
          data: {
            'metaVezes': meta['metaVezes'] as int,
            'usuario': user,
            'categoriasTarefasHabitos': meta['categoriaId'] as String?,
            'valor': meta['valor'] as num,
            'reiniciaEmQtd': meta['reiniciaEmQtd'] as int,
            'reiniciaEmTipo': meta['reiniciaEmTipo'] as String,
          },
        );
        qtdRowIds.add(qtdRow.$id);
      }

      await tablesDB.createRow(
        databaseId: Core.databaseId,
        tableId: Core.tableTarefasEHabitos,
        rowId: ID.unique(),
        data: {
          'nome': nome,
          'tipo': tipo,
          'usuario': user,
          'concluida': false,
          'agendamento': agendamento?.toIso8601String(),
          'tarefasHabitosQtds': qtdRowIds,
        },
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
  }) async {
    try {
      if (Core.loginController.currentUser == null) {
        await Core.loginController.loadUser();
      }
      final String user = Core.loginController.currentUser?.$id ?? '';
      final TablesDB tablesDB = TablesDB(databases.client);

      final String qtdCollectionId =
          tarefasHabitosQtdCollectionId ?? Core.tableTarefasHabitosQtds;

      final List<String> finalQtdRowIds = [];
      final List<String> savedQtdRowIds = [];

      for (final meta in metas) {
        final String? metaId = meta['id'] as String?;
        if (metaId != null && metaId.isNotEmpty) {
          // Update existing meta
          await tablesDB.updateRow(
            databaseId: Core.databaseId,
            tableId: qtdCollectionId,
            rowId: metaId,
            data: {
              'metaVezes': meta['metaVezes'] as int,
              'usuario': user,
              'categoriasTarefasHabitos': meta['categoriaId'] as String?,
              'valor': meta['valor'] as num,
              'reiniciaEmQtd': meta['reiniciaEmQtd'] as int,
              'reiniciaEmTipo': meta['reiniciaEmTipo'] as String,
            },
          );
          finalQtdRowIds.add(metaId);
          savedQtdRowIds.add(metaId);
        } else {
          // Create new meta
          final Row qtdRow = await tablesDB.createRow(
            databaseId: Core.databaseId,
            tableId: qtdCollectionId,
            rowId: ID.unique(),
            data: {
              'metaVezes': meta['metaVezes'] as int,
              'usuario': user,
              'categoriasTarefasHabitos': meta['categoriaId'] as String?,
              'valor': meta['valor'] as num,
              'reiniciaEmQtd': meta['reiniciaEmQtd'] as int,
              'reiniciaEmTipo': meta['reiniciaEmTipo'] as String,
            },
          );
          finalQtdRowIds.add(qtdRow.$id);
        }
      }

      await tablesDB.updateRow(
        databaseId: Core.databaseId,
        tableId: Core.tableTarefasEHabitos,
        rowId: id,
        data: {
          'nome': nome,
          'tipo': tipo,
          'usuario': user,
          'agendamento': agendamento?.toIso8601String(),
          'tarefasHabitosQtds': finalQtdRowIds,
        },
      );

      // Delete any existing metas that were removed in the UI
      for (final existingId in allExistingQtdRowIds) {
        if (!savedQtdRowIds.contains(existingId)) {
          try {
            await tablesDB.deleteRow(
              databaseId: Core.databaseId,
              tableId: qtdCollectionId,
              rowId: existingId,
            );
          } catch (e) {
            log('Error deleting obsolete meta row $existingId: $e');
          }
        }
      }

      await loadDocuments();
      return true;
    } catch (e) {
      log('Error updating task/habit: $e');
      return false;
    }
  }

  Future<bool> deleteTarefaHabito(String id, List<String> qtdRowIds) async {
    try {
      final TablesDB tablesDB = TablesDB(databases.client);

      final String qtdCollectionId =
          tarefasHabitosQtdCollectionId ?? Core.tableTarefasHabitosQtds;

      for (final qtdRowId in qtdRowIds) {
        try {
          await tablesDB.deleteRow(
            databaseId: Core.databaseId,
            tableId: qtdCollectionId,
            rowId: qtdRowId,
          );
        } catch (e) {
          log('Error deleting meta row $qtdRowId: $e');
        }
      }

      await tablesDB.deleteRow(
        databaseId: Core.databaseId,
        tableId: Core.tableTarefasEHabitos,
        rowId: id,
      );

      await loadDocuments();
      return true;
    } catch (e) {
      log('Error deleting task/habit: $e');
      return false;
    }
  }
}
