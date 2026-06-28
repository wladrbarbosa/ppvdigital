import 'dart:async';
import 'dart:developer';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:mobx/mobx.dart' as mobx;
import 'package:ppvdigital/app/capacitacao/tarefas_habitos/historico_controller.dart';
import 'package:ppvdigital/app/capacitacao/tarefas_habitos/lista_habitos_tarefas_page.dart';
import 'package:ppvdigital/core.dart';
import 'package:ppvdigital/models/categorias_tarefas_habitos_model.dart';
import 'package:ppvdigital/models/historico_item_model.dart';
import 'package:ppvdigital/models/tarefas_habitos_model.dart';
import 'package:ppvdigital/models/tarefas_habitos_qtd_model.dart';

extension TarefasHabitosTransformList on List<dynamic>? {
  List<TarefaHabitoQtdModel> toTarefaHabitoQtdModelList([
    List<HistoricoItemModel>? tarefaHabitoHistoricoList,
  ]) {
    return this?.map<TarefaHabitoQtdModel>((e2) {
          List<HistoricoItemModel> withPeriodFilter = [];
          DateTime beginning = DateTime.parse(
            ((e2 as Map<String, dynamic>)[r'$createdAt'] as String?) ?? '',
          );
          final String reiniciaEmTipo = e2['reiniciaEmTipo'] as String;
          final int reiniciaEmQtd = e2['reiniciaEmQtd'] as int;
          final DateTime now = DateTime.now();

          if (tarefaHabitoHistoricoList != null &&
              tarefaHabitoHistoricoList.isNotEmpty) {
            final Duration beginningNowDiff = DateTime.now().difference(
              beginning,
            );
            late DateTime startPeriod;

            switch (reiniciaEmTipo) {
              case 'dias':
                final Duration durationToStartPeriod = Duration(
                  days: (beginningNowDiff.inDays ~/ reiniciaEmQtd) + 1,
                );
                beginning = DateTime.utc(
                  beginning.year,
                  beginning.month,
                  beginning.day,
                );
                startPeriod = beginning.add(durationToStartPeriod);
              case 'semanas':
                final Duration durationToStartPeriod = Duration(
                  days:
                      (beginningNowDiff.inDays ~/ (7 * reiniciaEmQtd)) -
                      (beginning.weekday - 1),
                );
                beginning = DateTime.utc(
                  beginning.year,
                  beginning.month,
                  beginning.day,
                );
                startPeriod = beginning.add(durationToStartPeriod);
              case 'meses':
                final int monthDiff = now.month - beginning.month;
                startPeriod = DateTime.utc(
                  beginning.year,
                  now.month - (monthDiff % reiniciaEmQtd),
                );
              case 'anos':
                final int yearDiff = now.year - beginning.year;
                startPeriod = DateTime.utc(
                  now.year - (yearDiff % reiniciaEmQtd),
                );
              default:
                final Duration durationToStartPeriod = Duration(
                  hours: beginningNowDiff.inHours % reiniciaEmQtd,
                );
                beginning = DateTime.utc(
                  beginning.year,
                  beginning.month,
                  beginning.day,
                  beginning.hour,
                );
                startPeriod = beginning.add(durationToStartPeriod);
            }

            withPeriodFilter = tarefaHabitoHistoricoList.where((el) {
              return el.createdAt.isAtSameMomentAs(startPeriod) ||
                  el.createdAt.isAfter(startPeriod);
            }).toList();
          }

          final String? collectionId =
              e2[r'$collectionId'] as String?;
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

    await Future.forEach(this, (e1) async {
      final RowList historicoTarefasHabitos = await tablesDB.listRows(
        databaseId: '671f6e1600022832cba5',
        tableId: '6741f10d000d985e4af9',
        queries: [
          Query.equal('usuario', Core.loginController.currentUser?.$id ?? ''),
          Query.equal('tarefasEHabitos', e1.$id),
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

      final List<HistoricoItemModel> tarefaHabitoQtdList =
          historicoTarefasHabitos.rows.toHistoricoModelList();

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
    });

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
  }

  static String? tarefasHabitosQtdCollectionId;

  late final Databases databases;
  final mobx.ObservableList<TarefaHabitoModel> _tarefasHabitosList =
      mobx.ObservableList<TarefaHabitoModel>(name: 'tarefasHabitosList');
  List<TarefaHabitoModel> get tarefasHabitosList =>
      _tarefasHabitosList.toList();
  static Future<void>? tarefasHabitosFuture;

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
          databaseId: '671f6e1600022832cba5',
          tableId: '671f864f0023d1c27de8',
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
        ListaHabitosTarefasPageState.qtdItems =
            Core.tarefasHabitosController.tarefasHabitosList.length;
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
          databaseId: '671f6e1600022832cba5',
          tableId: '6741f10d000d985e4af9',
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

  Future<bool> createTarefaHabito({
    required String nome,
    required String tipo,
    required int metaVezes,
    required String? categoriaId,
    required num valor,
    required int reiniciaEmQtd,
    required String reiniciaEmTipo,
    DateTime? agendamento,
  }) async {
    try {
      if (Core.loginController.currentUser == null) {
        await Core.loginController.loadUser();
      }
      final String user = Core.loginController.currentUser?.$id ?? '';
      final TablesDB tablesDB = TablesDB(databases.client);

      final String qtdCollectionId =
          tarefasHabitosQtdCollectionId ?? '671f86820005de9756b1';

      final Row qtdRow = await tablesDB.createRow(
        databaseId: '671f6e1600022832cba5',
        tableId: qtdCollectionId,
        rowId: ID.unique(),
        data: {
          'metaVezes': metaVezes,
          'usuario': user,
          'categoriasTarefasHabitos': categoriaId,
          'valor': valor,
          'reiniciaEmQtd': reiniciaEmQtd,
          'reiniciaEmTipo': reiniciaEmTipo,
          'dataCriacao': DateTime.now().millisecondsSinceEpoch,
        },
      );

      await tablesDB.createRow(
        databaseId: '671f6e1600022832cba5',
        tableId: '671f864f0023d1c27de8',
        rowId: ID.unique(),
        data: {
          'nome': nome,
          'tipo': tipo,
          'usuario': user,
          'concluida': false,
          'agendamento': agendamento?.toIso8601String(),
          'tarefasHabitosQtds': [qtdRow.$id],
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
    required int metaVezes,
    required String? categoriaId,
    required num valor,
    required int reiniciaEmQtd,
    required String reiniciaEmTipo,
    DateTime? agendamento,
    required String qtdRowId,
  }) async {
    try {
      if (Core.loginController.currentUser == null) {
        await Core.loginController.loadUser();
      }
      final String user = Core.loginController.currentUser?.$id ?? '';
      final TablesDB tablesDB = TablesDB(databases.client);

      final String qtdCollectionId =
          tarefasHabitosQtdCollectionId ?? '671f86820005de9756b1';

      await tablesDB.updateRow(
        databaseId: '671f6e1600022832cba5',
        tableId: qtdCollectionId,
        rowId: qtdRowId,
        data: {
          'metaVezes': metaVezes,
          'usuario': user,
          'categoriasTarefasHabitos': categoriaId,
          'valor': valor,
          'reiniciaEmQtd': reiniciaEmQtd,
          'reiniciaEmTipo': reiniciaEmTipo,
        },
      );

      await tablesDB.updateRow(
        databaseId: '671f6e1600022832cba5',
        tableId: '671f864f0023d1c27de8',
        rowId: id,
        data: {
          'nome': nome,
          'tipo': tipo,
          'usuario': user,
          'agendamento': agendamento?.toIso8601String(),
        },
      );

      await loadDocuments();
      return true;
    } catch (e) {
      log('Error updating task/habit: $e');
      return false;
    }
  }

  Future<bool> deleteTarefaHabito(String id, String qtdRowId) async {
    try {
      final TablesDB tablesDB = TablesDB(databases.client);

      final String qtdCollectionId =
          tarefasHabitosQtdCollectionId ?? '671f86820005de9756b1';

      await tablesDB.deleteRow(
        databaseId: '671f6e1600022832cba5',
        tableId: qtdCollectionId,
        rowId: qtdRowId,
      );

      await tablesDB.deleteRow(
        databaseId: '671f6e1600022832cba5',
        tableId: '671f864f0023d1c27de8',
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
