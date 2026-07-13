import 'dart:convert';
import 'dart:developer';
import 'dart:ui' show Color;

import 'package:appwrite/appwrite.dart';
import 'package:drift/drift.dart';
import 'package:ppvdigital/models/categorias_tarefas_habitos_model.dart';
import 'package:ppvdigital/models/historico_item_model.dart';
import 'package:ppvdigital/models/local/app_database.dart';
import 'package:ppvdigital/models/tarefas_habitos_model.dart';
import 'package:ppvdigital/models/tarefas_habitos_qtd_model.dart';
import 'package:ppvdigital/repositories/tarefa_habito_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DriftTarefaHabitoRepository implements TarefaHabitoRepository {
  DriftTarefaHabitoRepository({
    required this.database,
    required this.remoteRepository,
  });
  final AppDatabase database;
  final TarefaHabitoRepository remoteRepository;

  TarefaHabitosCompanion toCompanion(TarefaHabitoModel model) {
    return TarefaHabitosCompanion.insert(
      remoteId: model.id,
      nome: model.nome,
      tipo: model.tipo,
      usuario: model.usuario,
      concluida: model.concluida,
      agendamento: Value(model.agendamento),
      duration: Value(model.duration),
      metas: model.tarefasHabitosQtd,
    );
  }

  TarefaHabitoModel toDomain(TarefaHabito row) {
    return TarefaHabitoModel(
      id: row.remoteId,
      nome: row.nome,
      tipo: row.tipo,
      usuario: row.usuario,
      concluida: row.concluida,
      agendamento: row.agendamento,
      duration: row.duration,
      tarefasHabitosQtd: row.metas,
    );
  }

  HistoricoItemModel toHistoricoDomain(
    HistoricoTarefasHabito row,
    Map<String, TarefaHabitoModel> habitsMap,
  ) {
    final habit =
        habitsMap[row.tarefaHabitoId] ??
        TarefaHabitoModel(
          id: row.tarefaHabitoId,
          nome: '',
          tipo: 'habito',
          usuario: row.usuario,
          concluida: false,
          agendamento: null,
          tarefasHabitosQtd: [],
        );
    return HistoricoItemModel(
      id: row.remoteId,
      usuario: row.usuario,
      createdAt: row.createdAt,
      tarefasEHabitos: habit,
    );
  }

  Future<List<Map<String, dynamic>>> _getPendingSyncs() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('pending_tarefas_habitos_syncs') ?? [];
    return list
        .map((item) => json.decode(item) as Map<String, dynamic>)
        .toList();
  }

  Future<void> _savePendingSyncs(List<Map<String, dynamic>> syncs) async {
    final prefs = await SharedPreferences.getInstance();
    final list = syncs.map((item) => json.encode(item)).toList();
    await prefs.setStringList('pending_tarefas_habitos_syncs', list);
  }

  Future<void> _addPendingSync(Map<String, dynamic> syncItem) async {
    final syncs = await _getPendingSyncs();
    syncs.add(syncItem);
    await _savePendingSyncs(syncs);
  }

  Future<void> flushPendingSyncs() async {
    final syncs = await _getPendingSyncs();
    if (syncs.isEmpty) return;

    log(
      'Flushing ${syncs.length} pending offline syncs for Tarefas/Habitos...',
    );
    final remainingSyncs = List<Map<String, dynamic>>.from(syncs);

    for (final item in syncs) {
      final actionType = item['actionType'] as String;

      try {
        if (actionType == 'recordHistorico') {
          final docId = item['documentId'] as String;
          final userId = item['usuarioId'] as String;
          await remoteRepository.recordHistorico(
            foundId: docId,
            usuarioId: userId,
          );
        } else if (actionType == 'updateConcluida') {
          final docId = item['documentId'] as String;
          final concluida = item['concluida'] as bool;
          await remoteRepository.updateConcluida(
            documentId: docId,
            concluida: concluida,
          );
        } else if (actionType == 'createTarefaHabito') {
          final agendamentoStr = item['agendamento'] as String?;
          await remoteRepository.createTarefaHabito(
            nome: item['nome'] as String,
            tipo: item['tipo'] as String,
            metas: List<Map<String, dynamic>>.from(item['metas'] as List),
            agendamento: agendamentoStr != null
                ? DateTime.parse(agendamentoStr)
                : null,
            duration: item['duration'] as int?,
            usuarioId: item['usuarioId'] as String,
          );
        } else if (actionType == 'updateTarefaHabito') {
          final agendamentoStr = item['agendamento'] as String?;
          await remoteRepository.updateTarefaHabito(
            id: item['id'] as String,
            nome: item['nome'] as String,
            tipo: item['tipo'] as String,
            metas: List<Map<String, dynamic>>.from(item['metas'] as List),
            allExistingQtdRowIds: List<String>.from(
              item['allExistingQtdRowIds'] as List,
            ),
            agendamento: agendamentoStr != null
                ? DateTime.parse(agendamentoStr)
                : null,
            duration: item['duration'] as int?,
            usuarioId: item['usuarioId'] as String,
          );
        } else if (actionType == 'deleteTarefaHabito') {
          await remoteRepository.deleteTarefaHabito(
            id: item['id'] as String,
            qtdRowIds: List<String>.from(item['qtdRowIds'] as List),
          );
        } else if (actionType == 'deleteHistoricoItem') {
          await remoteRepository.deleteHistoricoItem(id: item['id'] as String);
        }
        remainingSyncs.remove(item);
      } catch (e) {
        log('Failed to sync offline action $item: $e. Will retry later.');
        if (e is AppwriteException && (e.code == 404 || e.code == 400)) {
          log('Permanent error. Removing action from queue: $item');
          remainingSyncs.remove(item);
        }
      }
    }

    await _savePendingSyncs(remainingSyncs);
  }

  @override
  Future<List<TarefaHabitoModel>> getTarefasEHabitos({
    required String usuarioId,
    bool forceLocal = false,
  }) async {
    // 1. Fetch cached data from Drift
    final localQuery = database.select(database.tarefaHabitos)
      ..where((t) => t.usuario.equals(usuarioId));
    final localDocs = await localQuery.get();
    final localList = localDocs.map(toDomain).toList();

    if (forceLocal) {
      return localList;
    }

    // Flush pending sync queue first!
    await flushPendingSyncs();

    // 2. Fetch fresh data from Appwrite and update cache in background
    try {
      final remoteDocs = await remoteRepository.getTarefasEHabitos(
        usuarioId: usuarioId,
      );

      await database.transaction(() async {
        // Delete old cache
        final deleteQuery = database.delete(database.tarefaHabitos)
          ..where((t) => t.usuario.equals(usuarioId));
        await deleteQuery.go();

        // Insert new cache
        for (final doc in remoteDocs) {
          await database.into(database.tarefaHabitos).insert(toCompanion(doc));
        }
      });

      return remoteDocs;
    } catch (e) {
      log(
        'Appwrite offline or failed to fetch: $e. Returning cached local data.',
      );
      return localDocs.map(toDomain).toList();
    }
  }

  @override
  Future<List<HistoricoItemModel>> getHistorico({
    required String usuarioId,
    bool forceLocal = false,
  }) async {
    final localQuery = database.select(database.historicoTarefasHabitos)
      ..where((h) => h.usuario.equals(usuarioId))
      ..orderBy([(h) => OrderingTerm.desc(h.createdAt)]);
    final localRows = await localQuery.get();

    final localHabits = await database.select(database.tarefaHabitos).get();
    final habitsMap = {for (final h in localHabits) h.remoteId: toDomain(h)};

    final localList = localRows
        .map((r) => toHistoricoDomain(r, habitsMap))
        .toList();

    if (forceLocal) {
      return localList;
    }

    await flushPendingSyncs();

    try {
      final remoteList = await remoteRepository.getHistorico(
        usuarioId: usuarioId,
      );

      await database.transaction(() async {
        // Delete all local history cache first
        final deleteQuery = database.delete(database.historicoTarefasHabitos)
          ..where((h) => h.usuario.equals(usuarioId));
        await deleteQuery.go();

        // Insert new cache
        for (final item in remoteList) {
          await database
              .into(database.historicoTarefasHabitos)
              .insert(
                HistoricoTarefasHabitosCompanion.insert(
                  remoteId: item.id,
                  usuario: item.usuario.isNotEmpty ? item.usuario : usuarioId,
                  tarefaHabitoId: item.tarefasEHabitos.id,
                  createdAt: item.createdAt,
                ),
                mode: InsertMode.insertOrReplace,
              );
        }
      });

      final List<HistoricoItemModel> updatedRemoteList = [];
      for (final item in remoteList) {
        final correctHabit =
            habitsMap[item.tarefasEHabitos.id] ?? item.tarefasEHabitos;
        updatedRemoteList.add(item.copyWith(tarefasEHabitos: correctHabit));
      }

      return updatedRemoteList;
    } catch (e) {
      log('Appwrite offline: $e. Returning cached local history.');
      return localList;
    }
  }

  @override
  Future<void> recordHistorico({
    required String foundId,
    required String usuarioId,
  }) async {
    // 1. Optimistic Update: Increment locally in Drift first
    final localQuery = database.select(database.tarefaHabitos)
      ..where((t) => t.remoteId.equals(foundId));
    final localDoc = await localQuery.getSingleOrNull();

    if (localDoc != null) {
      final updatedMetas = localDoc.metas.map((meta) {
        return meta.copyWith(vezesPraticado: meta.vezesPraticado + meta.valor);
      }).toList();

      final updatedCompanion = TarefaHabitosCompanion(
        metas: Value(updatedMetas),
      );

      final updateQuery = database.update(database.tarefaHabitos)
        ..where((t) => t.remoteId.equals(foundId));
      await updateQuery.write(updatedCompanion);
    }

    // 1.1 Optimistic Update: Insert new history record locally into SQLite
    final tempHistoryId = ID.unique();
    await database
        .into(database.historicoTarefasHabitos)
        .insert(
          HistoricoTarefasHabitosCompanion.insert(
            remoteId: tempHistoryId,
            usuario: usuarioId,
            tarefaHabitoId: foundId,
            createdAt: DateTime.now(),
          ),
        );

    // 2. Add to pending sync queue
    final syncItem = {
      'actionType': 'recordHistorico',
      'tempHistoryId': tempHistoryId,
      'documentId': foundId,
      'usuarioId': usuarioId,
    };
    await _addPendingSync(syncItem);

    // 3. Attempt to upload immediately
    try {
      await remoteRepository.recordHistorico(
        foundId: foundId,
        usuarioId: usuarioId,
      );
      // Success: remove from pending queue
      final syncs = await _getPendingSyncs();
      syncs.removeWhere(
        (item) =>
            item['actionType'] == 'recordHistorico' &&
            item['tempHistoryId'] == tempHistoryId,
      );
      await _savePendingSyncs(syncs);
    } catch (e) {
      log('Failed to upload history: $e. Saved to offline queue.');
    }
  }

  @override
  Future<bool> deleteHistoricoItem({required String id}) async {
    // 1. Find the history item to know which habit it is related to
    final query = database.select(database.historicoTarefasHabitos)
      ..where((h) => h.remoteId.equals(id));
    final historyRow = await query.getSingleOrNull();

    if (historyRow != null) {
      final habitId = historyRow.tarefaHabitoId;

      // Decrement locally in SQLite first
      final habitQuery = database.select(database.tarefaHabitos)
        ..where((t) => t.remoteId.equals(habitId));
      final localDoc = await habitQuery.getSingleOrNull();

      if (localDoc != null) {
        final updatedMetas = localDoc.metas.map((meta) {
          final newCount = meta.vezesPraticado - meta.valor;
          return meta.copyWith(vezesPraticado: newCount >= 0 ? newCount : 0);
        }).toList();

        final updatedCompanion = TarefaHabitosCompanion(
          metas: Value(updatedMetas),
        );

        final updateQuery = database.update(database.tarefaHabitos)
          ..where((t) => t.remoteId.equals(habitId));
        await updateQuery.write(updatedCompanion);
      }

      // Delete history item locally
      final deleteQuery = database.delete(database.historicoTarefasHabitos)
        ..where((h) => h.remoteId.equals(id));
      await deleteQuery.go();
    }

    await _addPendingSync({'actionType': 'deleteHistoricoItem', 'id': id});

    try {
      await remoteRepository.deleteHistoricoItem(id: id);
      final syncs = await _getPendingSyncs();
      syncs.removeWhere(
        (item) =>
            item['actionType'] == 'deleteHistoricoItem' && item['id'] == id,
      );
      await _savePendingSyncs(syncs);
      return true;
    } catch (e) {
      log(
        'Failed to delete history item remotely: $e. Saved to offline queue.',
      );
      return true;
    }
  }

  @override
  Future<void> updateConcluida({
    required String documentId,
    required bool concluida,
  }) async {
    // 1. Optimistic Update: Set locally in Drift first
    final localQuery = database.select(database.tarefaHabitos)
      ..where((t) => t.remoteId.equals(documentId));
    final localDoc = await localQuery.getSingleOrNull();

    if (localDoc != null) {
      final updateQuery = database.update(database.tarefaHabitos)
        ..where((t) => t.remoteId.equals(documentId));
      await updateQuery.write(
        TarefaHabitosCompanion(concluida: Value(concluida)),
      );
    }

    // 2. Add to pending sync queue
    final syncItem = {
      'actionType': 'updateConcluida',
      'documentId': documentId,
      'concluida': concluida,
    };
    await _addPendingSync(syncItem);

    // 3. Attempt to upload immediately
    try {
      await remoteRepository.updateConcluida(
        documentId: documentId,
        concluida: concluida,
      );
      // Success: remove from pending queue
      final syncs = await _getPendingSyncs();
      syncs.removeWhere(
        (item) =>
            item['actionType'] == 'updateConcluida' &&
            item['documentId'] == documentId &&
            item['concluida'] == concluida,
      );
      await _savePendingSyncs(syncs);
    } catch (e) {
      log(
        'Failed to update remote concluida state: $e. Saved to offline queue.',
      );
    }
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
    final tempId = ID.unique();
    final List<TarefaHabitoQtdModel> metaModels = metas.map((m) {
      return TarefaHabitoQtdModel(
        id: ID.unique(),
        metaVezes: m['metaVezes'] as int,
        usuario: usuarioId,
        categoriasTarefasHabitos: m['categoriaId'] != null
            ? CategoriasTarefasHabitosModel(
                id: m['categoriaId'] as String,
                nome: '',
                cor: const Color(0x00000000),
                usuario: usuarioId,
              )
            : null,
        valor: (m['valor'] as num).toInt(),
        reiniciaEmQtd: m['reiniciaEmQtd'] as int,
        reiniciaEmTipo: m['reiniciaEmTipo'] as String,
        vezesPraticado: 0,
        createdAt: DateTime.now(),
      );
    }).toList();

    final companion = TarefaHabitosCompanion.insert(
      remoteId: tempId,
      nome: nome,
      tipo: tipo,
      usuario: usuarioId,
      concluida: false,
      agendamento: Value(agendamento),
      duration: Value(duration),
      metas: metaModels,
    );
    await database.into(database.tarefaHabitos).insert(companion);

    await _addPendingSync({
      'actionType': 'createTarefaHabito',
      'tempId': tempId,
      'nome': nome,
      'tipo': tipo,
      'metas': metas,
      'agendamento': agendamento?.toIso8601String(),
      'duration': duration,
      'usuarioId': usuarioId,
    });

    try {
      await remoteRepository.createTarefaHabito(
        nome: nome,
        tipo: tipo,
        metas: metas,
        agendamento: agendamento,
        duration: duration,
        usuarioId: usuarioId,
      );
      final syncs = await _getPendingSyncs();
      syncs.removeWhere(
        (item) =>
            item['actionType'] == 'createTarefaHabito' &&
            item['tempId'] == tempId,
      );
      await _savePendingSyncs(syncs);
      return true;
    } catch (e) {
      log('Failed to create remotely: $e. Saved to offline queue.');
      return true;
    }
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
    final List<TarefaHabitoQtdModel> metaModels = metas.map((m) {
      return TarefaHabitoQtdModel(
        id: m['id'] as String? ?? ID.unique(),
        metaVezes: m['metaVezes'] as int,
        usuario: usuarioId,
        categoriasTarefasHabitos: m['categoriaId'] != null
            ? CategoriasTarefasHabitosModel(
                id: m['categoriaId'] as String,
                nome: '',
                cor: const Color(0x00000000),
                usuario: usuarioId,
              )
            : null,
        valor: (m['valor'] as num).toInt(),
        reiniciaEmQtd: m['reiniciaEmQtd'] as int,
        reiniciaEmTipo: m['reiniciaEmTipo'] as String,
        vezesPraticado: m['vezesPraticado'] as int? ?? 0,
        createdAt: DateTime.now(),
      );
    }).toList();

    final updateQuery = database.update(database.tarefaHabitos)
      ..where((t) => t.remoteId.equals(id));
    await updateQuery.write(
      TarefaHabitosCompanion(
        nome: Value(nome),
        tipo: Value(tipo),
        agendamento: Value(agendamento),
        duration: Value(duration),
        metas: Value(metaModels),
      ),
    );

    await _addPendingSync({
      'actionType': 'updateTarefaHabito',
      'id': id,
      'nome': nome,
      'tipo': tipo,
      'metas': metas,
      'allExistingQtdRowIds': allExistingQtdRowIds,
      'agendamento': agendamento?.toIso8601String(),
      'duration': duration,
      'usuarioId': usuarioId,
    });

    try {
      await remoteRepository.updateTarefaHabito(
        id: id,
        nome: nome,
        tipo: tipo,
        metas: metas,
        allExistingQtdRowIds: allExistingQtdRowIds,
        agendamento: agendamento,
        duration: duration,
        usuarioId: usuarioId,
      );
      final syncs = await _getPendingSyncs();
      syncs.removeWhere(
        (item) =>
            item['actionType'] == 'updateTarefaHabito' && item['id'] == id,
      );
      await _savePendingSyncs(syncs);
      return true;
    } catch (e) {
      log('Failed to update remotely: $e. Saved to offline queue.');
      return true;
    }
  }

  @override
  Future<bool> deleteTarefaHabito({
    required String id,
    required List<String> qtdRowIds,
  }) async {
    final localQuery = database.select(database.tarefaHabitos)
      ..where((t) => t.remoteId.equals(id));
    final localDoc = await localQuery.getSingleOrNull();

    if (localDoc != null) {
      final deleteQuery = database.delete(database.tarefaHabitos)
        ..where((t) => t.remoteId.equals(id));
      await deleteQuery.go();
    }

    await _addPendingSync({
      'actionType': 'deleteTarefaHabito',
      'id': id,
      'qtdRowIds': qtdRowIds,
    });

    try {
      await remoteRepository.deleteTarefaHabito(id: id, qtdRowIds: qtdRowIds);
      final syncs = await _getPendingSyncs();
      syncs.removeWhere(
        (item) =>
            item['actionType'] == 'deleteTarefaHabito' && item['id'] == id,
      );
      await _savePendingSyncs(syncs);
      return true;
    } catch (e) {
      log('Failed to delete remotely: $e. Saved to offline queue.');
      return true;
    }
  }

  @override
  Stream<List<TarefaHabitoModel>> watchTarefasEHabitos({
    required String usuarioId,
  }) {
    final query = database.select(database.tarefaHabitos)
      ..where((t) => t.usuario.equals(usuarioId));
    return query.watch().map((rows) => rows.map(toDomain).toList());
  }
}
