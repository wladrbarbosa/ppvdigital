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
  List<TarefaHabitoQtdModel> toTarefaHabitoQtdModelList([List<HistoricoItemModel>? tarefaHabitoHistoricoList]) {
    return this?.map<TarefaHabitoQtdModel>((e2) {
      List<HistoricoItemModel> withPeriodFilter = [];
      DateTime beginning = DateTime.parse(((e2 as Map<String, dynamic>)[r'$createdAt'] as String?) ?? '');
      final String reiniciaEmTipo = e2['reiniciaEmTipo'] as String;
      final int reiniciaEmQtd = e2['reiniciaEmQtd'] as int;
      final DateTime now = DateTime.now();

      if (tarefaHabitoHistoricoList != null && tarefaHabitoHistoricoList.isNotEmpty) {
        final Duration beginningNowDiff = DateTime.now().difference(beginning);
        late DateTime startPeriod;

        switch (reiniciaEmTipo) {
          case 'dias':
            final Duration durationToStartPeriod = Duration(days: (beginningNowDiff.inDays ~/ reiniciaEmQtd) + 1);
            beginning = DateTime.utc(beginning.year, beginning.month, beginning.day);
            startPeriod = beginning.add(durationToStartPeriod);
          case 'semanas':
            final Duration durationToStartPeriod = Duration(days: (beginningNowDiff.inDays ~/ (7 * reiniciaEmQtd)) - (beginning.weekday - 1));
            beginning = DateTime.utc(beginning.year, beginning.month, beginning.day);
            startPeriod = beginning.add(durationToStartPeriod);
          case 'meses':
            final int monthDiff = now.month - beginning.month;
            startPeriod = DateTime.utc(beginning.year, now.month - (monthDiff % reiniciaEmQtd));
          case 'anos':
            final int yearDiff = now.year - beginning.year;
            startPeriod = DateTime.utc(now.year - (yearDiff % reiniciaEmQtd));
          default:
            final Duration durationToStartPeriod = Duration(hours: beginningNowDiff.inHours % reiniciaEmQtd);
            beginning = DateTime.utc(beginning.year, beginning.month, beginning.day, beginning.hour);
            startPeriod = beginning.add(durationToStartPeriod);
        }
        

        withPeriodFilter = tarefaHabitoHistoricoList.where((el) {
          return el.createdAt.isAtSameMomentAs(startPeriod) || el.createdAt.isAfter(startPeriod);
        },).toList();
      }

      return TarefaHabitoQtdModel(
        id: e2[r'$id'] as String,
        usuario: e2['usuario'] as String,
        metaVezes: e2['metaVezes'] as int,
        categoriasTarefasHabitos: TarefasHabitosTransformDocumentList.toCategoriasTarefasHabitosModelList(e2['categoriasTarefasHabitos'] as Map<String, dynamic>?),
        valor: e2['valor'] as num,
        reiniciaEmQtd: reiniciaEmQtd,
        reiniciaEmTipo: reiniciaEmTipo,
        vezesPraticado: withPeriodFilter.length * (e2['valor'] as num),
        createdAt: beginning,
      );
    },).toList() ?? [];
  }
}

extension TarefasHabitosTransformDocumentList on List<Document> {
  Future<List<TarefaHabitoModel>> toTarefaHabitoModelList(Databases databases) async {
    final List<TarefaHabitoModel> temp = [];

    await Future.forEach(this, (e1) async {
      final DocumentList historicoTarefasHabitos = await databases.listDocuments(
        databaseId: '671f6e1600022832cba5',
        collectionId: '6741f10d000d985e4af9',
        queries: [
          Query.equal('usuario', Core.loginController.currentUser?.$id ?? ''),
          Query.equal('tarefasEHabitos', e1.$id),
          Query.orderDesc(r'$createdAt'),
          Query.limit(5000),
        ],
      );

      final List<HistoricoItemModel> tarefaHabitoQtdList = historicoTarefasHabitos.documents.toHistoricoModelList();

      temp.add(TarefaHabitoModel(
        id: e1.$id,
        nome: e1.data['nome'] as String,
        usuario: e1.data['usuario'] as String,
        tipo: e1.data['tipo'] as String,
        agendamento: DateTime.tryParse((e1.data['agendamento'] as String?) ?? ''),
        concluida: e1.data['concluida'] as bool,
        tarefasHabitosQtd: (e1.data['tarefasHabitosQtds'] as List<dynamic>?).toTarefaHabitoQtdModelList(tarefaHabitoQtdList),
      ),);
    },);

    return temp;
  }

  static CategoriasTarefasHabitosModel? toCategoriasTarefasHabitosModelList(Map<String, dynamic>? map) {
    return map != null ? CategoriasTarefasHabitosModel(
      id: map['\$id'] as String,
      usuario: map['usuario'] as String,
      nome: map['nome'] as String,
      cor: HexColor.fromHex(map['cor'] as String),
      pai: map['pai'] as String?,
    ) : null;
  }
}

class TarefasHabitosController {
  // Constructor
  TarefasHabitosController() {
    init();
  }

  late final Databases databases;
  final mobx.ObservableList<TarefaHabitoModel> _tarefasHabitosList = mobx.ObservableList<TarefaHabitoModel>(name: 'tarefasHabitosList');
  List<TarefaHabitoModel> get tarefasHabitosList => _tarefasHabitosList.toList();
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

        final DocumentList tarefasHabitosDocs = await databases.listDocuments(
          databaseId: '671f6e1600022832cba5',
          collectionId: '671f864f0023d1c27de8',
          queries: [
            Query.equal('usuario', [Core.loginController.currentUser?.$id ?? '']),
          ],
        );

        _tarefasHabitosList.clear();
        _tarefasHabitosList.addAll(await tarefasHabitosDocs.documents.toTarefaHabitoModelList(databases));
        ListaHabitosTarefasPageState.qtdItems = Core.tarefasHabitosController.tarefasHabitosList.length;
        return true;
      } on AppwriteException catch(e) {
        log(e.toString());
        return false;
      }
    },
    name: 'loadDocuments',);
  }

  Future<void> incrementQtdHabito(String documentId) async {
    log('Começo');
    try {
      mobx.runInAction(() async {
        final List<TarefaHabitoModel> temp = List<TarefaHabitoModel>.from(_tarefasHabitosList.toList());
        final TarefaHabitoModel found = temp.singleWhere((el) => el.id == documentId,);
        found.tarefasHabitosQtd.forEach((element) {
          element.vezesPraticado += element.valor;
        },);
        _tarefasHabitosList.setAll(0, temp);
        databases.createDocument(
          databaseId: '671f6e1600022832cba5',
          collectionId: '6741f10d000d985e4af9',
          documentId: ID.unique(),
          data: {
            'tarefasEHabitos': found.id,
            'usuario': Core.loginController.currentUser?.$id ?? '',
          },
        );
      },
      name: 'addQtdHabito',);
    } on AppwriteException catch(e) {
      log(e.toString());
    }
  }
}
