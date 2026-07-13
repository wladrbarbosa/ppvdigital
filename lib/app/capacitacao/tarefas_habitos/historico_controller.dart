import 'dart:async';
import 'dart:developer';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:mobx/mobx.dart' as mobx;
import 'package:ppvdigital/app/capacitacao/tarefas_habitos/tarefas_habitos_controller.dart';
import 'package:ppvdigital/core.dart';
import 'package:ppvdigital/models/historico_item_model.dart';
import 'package:ppvdigital/models/tarefas_habitos_model.dart';

extension HistoricoTransformMap on Map<String, dynamic> {
  TarefaHabitoModel toTarefasHabitosModel() {
    return TarefaHabitoModel(
      id: (this[r'$id'] ?? this['id'] ?? '') as String,
      nome: (this['nome'] as String?) ?? '',
      usuario: (this['usuario'] as String?) ?? '',
      tipo: (this['tipo'] as String?) ?? '',
      agendamento: DateTime.tryParse((this['agendamento'] as String?) ?? ''),
      concluida: (this['concluida'] as bool?) ?? false,
      tarefasHabitosQtd: (this['tarefasHabitosQtds'] as List<dynamic>?)
          .toTarefaHabitoQtdModelList(),
      duration: this['duration'] is num
          ? (this['duration'] as num).toInt()
          : null,
    );
  }
}

extension HistoricoTransformDocumentList on List<Row> {
  List<HistoricoItemModel> toHistoricoModelList() {
    final List<HistoricoItemModel> temp = [];

    for (final e1 in this) {
      try {
        final rawTarefaMap = e1.data['tarefasEHabitos'];
        if (rawTarefaMap == null) {
          continue;
        }

        String tarefaId = '';
        if (rawTarefaMap is String) {
          tarefaId = rawTarefaMap;
        } else if (rawTarefaMap is Map) {
          tarefaId =
              (rawTarefaMap[r'$id'] ?? rawTarefaMap['id'] ?? '') as String;
        }

        if (tarefaId.isEmpty) {
          continue;
        }

        final cachedTarefa = Core.tarefasHabitosController.tarefasHabitosList
            .cast<TarefaHabitoModel?>()
            .firstWhere((el) => el?.id == tarefaId, orElse: () => null);

        final String createdAtStr = e1.$createdAt;
        final DateTime parsedCreatedAt =
            DateTime.tryParse(createdAtStr)?.toLocal() ?? DateTime.now();

        final String userFallback =
            (e1.data['usuario'] as String?) ??
            Core.loginController.currentUser?.$id ??
            '';

        temp.add(
          HistoricoItemModel(
            id: e1.$id,
            usuario: userFallback,
            createdAt: parsedCreatedAt,
            tarefasEHabitos:
                cachedTarefa ??
                (rawTarefaMap is Map
                    ? (rawTarefaMap as Map<String, dynamic>)
                          .toTarefasHabitosModel()
                    : TarefaHabitoModel(
                        id: tarefaId,
                        nome: '',
                        tipo: 'habito',
                        usuario: userFallback,
                        concluida: false,
                        agendamento: null,
                        tarefasHabitosQtd: [],
                      )),
          ),
        );
      } catch (e) {
        log('Error parsing history item ${e1.$id}: $e');
      }
    }

    return temp;
  }
}

class HistoricoController {
  // Constructor
  HistoricoController() {
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

        final String userId = Core.loginController.currentUser?.$id ?? '';
        final List<HistoricoItemModel> items = await Core.tarefaHabitoRepository
            .getHistorico(usuarioId: userId);

        _historicoList.clear();
        _historicoList.addAll(items);
        return true;
      } on Exception catch (e) {
        log(e.toString());
        return false;
      }
    }, name: 'loadDocuments');
  }

  void reset() {
    mobx.runInAction(() {
      _historicoList.clear();
    });
  }

  Future<void> updateQtdHabito(String documentId, int newQtd) async {
    log('updateQtdHabito called, not implemented or used');
  }

  Future<bool> deleteHistoricoItem(String documentId) async {
    try {
      final success = await Core.tarefaHabitoRepository.deleteHistoricoItem(
        id: documentId,
      );

      if (success) {
        mobx.runInAction(() {
          _historicoList.removeWhere((el) => el.id == documentId);
        });

        // Reload main tasks/habits count dynamically
        await Core.tarefasHabitosController.loadDocuments();
      }
      return success;
    } catch (e) {
      log(e.toString());
      return false;
    }
  }
}
