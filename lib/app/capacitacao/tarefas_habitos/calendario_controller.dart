import 'dart:async';
import 'dart:developer';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:mobx/mobx.dart' as mobx;
import 'package:ppvdigital/app/capacitacao/tarefas_habitos/lista_habitos_tarefas_page.dart';
import 'package:ppvdigital/app/capacitacao/tarefas_habitos/tarefas_habitos_controller.dart';
import 'package:ppvdigital/core.dart';
import 'package:ppvdigital/models/historico_item_model.dart';
import 'package:ppvdigital/models/tarefas_habitos_model.dart';

extension CalendarioTransformMap on Map<String, dynamic> {
  TarefaHabitoModel toTarefasHabitosModel() {
    return TarefaHabitoModel(
      id: this[r'$id'] as String,
      nome: this['nome'] as String,
      usuario: this['usuario'] as String,
      tipo: this['tipo'] as String,
      agendamento: DateTime.tryParse((this['agendamento'] as String?) ?? ''),
      concluida: this['concluida'] as bool,
      tarefasHabitosQtd:
          (this['tarefasHabitosQtds'] as List<dynamic>?)
              .toTarefaHabitoQtdModelList(),
    );
  }
}

extension CalendarioTransformRowList on List<Row> {
  List<HistoricoItemModel> toHistoricoModelList() {
    final List<HistoricoItemModel> temp = [];

    void addToList(Row e1) {
      final Map<String, dynamic> rawTarefaMap =
          e1.data['tarefasEHabitos'] as Map<String, dynamic>;
      final String tarefaId = rawTarefaMap[r'$id'] as String;

      final cachedTarefa = Core.tarefasHabitosController.tarefasHabitosList
          .cast<TarefaHabitoModel?>()
          .firstWhere(
            (el) => el?.id == tarefaId,
            orElse: () => null,
          );

      temp.add(
        HistoricoItemModel(
          id: e1.$id,
          usuario: e1.data['usuario'] as String,
          createdAt: DateTime.parse((e1.data[r'$createdAt'] as String?) ?? ''),
          tarefasEHabitos: cachedTarefa ?? rawTarefaMap.toTarefasHabitosModel(),
        ),
      );
    }

    forEach(addToList);

    return temp;
  }
}

class CalendarioController {
  // Constructor
  CalendarioController() {
    init();
  }

  late final Databases databases;
  final mobx.ObservableList<HistoricoItemModel> _historicoList =
      mobx.ObservableList<HistoricoItemModel>(name: 'tarefasHabitosList');
  List<HistoricoItemModel> get historicoList => _historicoList.toList();
  static Future<void>? historicoFuture;

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

        if (Core.tarefasHabitosController.tarefasHabitosList.isEmpty) {
          await Core.tarefasHabitosController.loadDocuments();
        }

        final TablesDB tablesDB = TablesDB(databases.client);
        final RowList historicoDocs = await tablesDB.listRows(
          databaseId: '671f6e1600022832cba5',
          tableId: '6741f10d000d985e4af9',
          queries: [
            Query.equal('usuario', [
              Core.loginController.currentUser?.$id ?? '',
            ]),
            Query.limit(5000),
          ],
        );

        _historicoList.clear();
        _historicoList.addAll(historicoDocs.rows.toHistoricoModelList());
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

  Future<void> updateQtdHabito(String documentId, int newQtd) async {
    log('Começo');
    try {
      mobx.runInAction(() {
        final List<HistoricoItemModel> temp = List<HistoricoItemModel>.from(
          _historicoList.toList(),
        );
        final HistoricoItemModel found = temp.singleWhere(
          (el) => el.id == documentId,
        );
        _historicoList.setAll(0, temp);
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
}
