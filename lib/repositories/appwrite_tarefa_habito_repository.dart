import 'dart:developer';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:ppvdigital/app/capacitacao/tarefas_habitos/historico_controller.dart';
import 'package:ppvdigital/app/capacitacao/tarefas_habitos/tarefas_habitos_controller.dart';
import 'package:ppvdigital/core.dart';
import 'package:ppvdigital/models/historico_item_model.dart';
import 'package:ppvdigital/models/tarefas_habitos_model.dart';
import 'package:ppvdigital/repositories/tarefa_habito_repository.dart';

class AppwriteTarefaHabitoRepository implements TarefaHabitoRepository {
  AppwriteTarefaHabitoRepository(this.databases);
  final Databases databases;

  @override
  Future<List<TarefaHabitoModel>> getTarefasEHabitos({
    required String usuarioId,
    bool forceLocal = false,
  }) async {
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
        Query.equal('usuario', usuarioId),
        Query.limit(5000),
      ],
    );
    return await tarefasHabitosDocs.rows.toTarefaHabitoModelList(
      databases,
      usuarioId,
    );
  }

  @override
  Future<List<HistoricoItemModel>> getHistorico({
    required String usuarioId,
    bool forceLocal = false,
  }) async {
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
    return res.rows.toHistoricoModelList();
  }

  @override
  Future<void> recordHistorico({
    required String foundId,
    required String usuarioId,
  }) async {
    final TablesDB tablesDB = TablesDB(databases.client);
    await tablesDB.createRow(
      databaseId: Core.databaseId,
      tableId: Core.tableHistoricoTarefasHabitos,
      rowId: ID.unique(),
      data: {'tarefasEHabitos': foundId, 'usuario': usuarioId},
    );
  }

  @override
  Future<void> updateConcluida({
    required String documentId,
    required bool concluida,
  }) async {
    final TablesDB tablesDB = TablesDB(databases.client);
    await tablesDB.updateRow(
      databaseId: Core.databaseId,
      tableId: Core.tableTarefasEHabitos,
      rowId: documentId,
      data: {'concluida': concluida},
    );
  }

  @override
  Future<bool> createTarefaHabito({
    required String nome,
    required String tipo,
    required List<Map<String, dynamic>> metas,
    DateTime? agendamento,
    int? duration,
    required String usuarioId,
  }) async {
    final TablesDB tablesDB = TablesDB(databases.client);
    const String qtdCollectionId = Core.tableTarefasHabitosQtds;

    final List<String> qtdRowIds = [];

    for (final meta in metas) {
      final Row qtdRow = await tablesDB.createRow(
        databaseId: Core.databaseId,
        tableId: qtdCollectionId,
        rowId: ID.unique(),
        data: {
          'metaVezes': meta['metaVezes'],
          'usuario': usuarioId,
          'categoriasTarefasHabitos': meta['categoriaId'],
          'valor': meta['valor'],
          'reiniciaEmQtd': meta['reiniciaEmQtd'],
          'reiniciaEmTipo': meta['reiniciaEmTipo'],
          'vezesPraticado': 0,
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
        'usuario': usuarioId,
        'concluida': false,
        'agendamento': agendamento?.toIso8601String(),
        'tarefasHabitosQtds': qtdRowIds,
        'duration': duration,
      },
    );

    return true;
  }

  @override
  Future<bool> updateTarefaHabito({
    required String id,
    required String nome,
    required String tipo,
    required List<Map<String, dynamic>> metas,
    required List<String> allExistingQtdRowIds,
    DateTime? agendamento,
    int? duration,
    required String usuarioId,
  }) async {
    final TablesDB tablesDB = TablesDB(databases.client);
    const String qtdCollectionId = Core.tableTarefasHabitosQtds;

    final List<String> savedQtdRowIds = [];
    final List<String> finalQtdRowIds = [];

    for (final meta in metas) {
      final String? metaId = meta['id'] as String?;
      if (metaId == null) {
        final Row qtdRow = await tablesDB.createRow(
          databaseId: Core.databaseId,
          tableId: qtdCollectionId,
          rowId: ID.unique(),
          data: {
            'metaVezes': meta['metaVezes'],
            'usuario': usuarioId,
            'categoriasTarefasHabitos': meta['categoriaId'],
            'valor': meta['valor'],
            'reiniciaEmQtd': meta['reiniciaEmQtd'],
            'reiniciaEmTipo': meta['reiniciaEmTipo'],
            'vezesPraticado': 0,
          },
        );
        savedQtdRowIds.add(qtdRow.$id);
        finalQtdRowIds.add(qtdRow.$id);
      } else {
        await tablesDB.updateRow(
          databaseId: Core.databaseId,
          tableId: qtdCollectionId,
          rowId: metaId,
          data: {
            'metaVezes': meta['metaVezes'],
            'usuario': usuarioId,
            'categoriasTarefasHabitos': meta['categoriaId'],
            'valor': meta['valor'],
            'reiniciaEmQtd': meta['reiniciaEmQtd'],
            'reiniciaEmTipo': meta['reiniciaEmTipo'],
          },
        );
        savedQtdRowIds.add(metaId);
        finalQtdRowIds.add(metaId);
      }
    }

    await tablesDB.updateRow(
      databaseId: Core.databaseId,
      tableId: Core.tableTarefasEHabitos,
      rowId: id,
      data: {
        'nome': nome,
        'tipo': tipo,
        'usuario': usuarioId,
        'agendamento': agendamento?.toIso8601String(),
        'tarefasHabitosQtds': finalQtdRowIds,
        'duration': duration,
      },
    );

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

    return true;
  }

  @override
  Future<bool> deleteTarefaHabito({
    required String id,
    required List<String> qtdRowIds,
  }) async {
    final TablesDB tablesDB = TablesDB(databases.client);
    const String qtdCollectionId = Core.tableTarefasHabitosQtds;

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

    return true;
  }

  @override
  Future<bool> deleteHistoricoItem({required String id}) async {
    final TablesDB tablesDB = TablesDB(databases.client);
    await tablesDB.deleteRow(
      databaseId: Core.databaseId,
      tableId: Core.tableHistoricoTarefasHabitos,
      rowId: id,
    );
    return true;
  }

  @override
  Stream<List<TarefaHabitoModel>> watchTarefasEHabitos({
    required String usuarioId,
  }) {
    return const Stream.empty();
  }
}
