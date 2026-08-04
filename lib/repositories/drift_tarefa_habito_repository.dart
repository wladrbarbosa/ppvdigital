import 'dart:convert';
import 'dart:developer';
import 'dart:ui' show Color;

import 'package:appwrite/appwrite.dart';
import 'package:drift/drift.dart';
import 'package:ppvdigital/core.dart';
import 'package:ppvdigital/models/categorias_tarefas_habitos_model.dart';
import 'package:ppvdigital/models/historico_item_model.dart';
import 'package:ppvdigital/models/local/app_database.dart';
import 'package:ppvdigital/models/tarefas_habitos_model.dart';
import 'package:ppvdigital/models/tarefas_habitos_qtd_model.dart';
import 'package:ppvdigital/repositories/tarefa_habito_repository.dart';

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
    final str = await database.getSetting('pending_tarefas_habitos_syncs');
    if (str == null || str.isEmpty) return [];
    final list = json.decode(str) as List;
    return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<void> _savePendingSyncs(List<Map<String, dynamic>> syncs) async {
    final str = json.encode(syncs);
    await database.setSetting('pending_tarefas_habitos_syncs', str);
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
    DateTime? lastSyncedAt,
  }) async {
    // 1. Fetch cached data from Drift
    final localQuery = database.select(database.tarefaHabitos)
      ..where((t) => t.usuario.equals(usuarioId));
    final localDocs = await localQuery.get();
    final localList = localDocs.map(toDomain).toList();

    if (forceLocal) {
      return await _populatePeriodVezesPraticado(localList, usuarioId);
    }

    // Flush pending sync queue first!
    await flushPendingSyncs();

    // 2. Fetch fresh data from Appwrite and update cache in background
    try {
      final remoteDocs = await remoteRepository.getTarefasEHabitos(
        usuarioId: usuarioId,
        lastSyncedAt: lastSyncedAt,
      );

      if (remoteDocs.isNotEmpty || lastSyncedAt == null) {
        await database.transaction(() async {
          if (lastSyncedAt == null) {
            final deleteQuery = database.delete(database.tarefaHabitos)
              ..where((t) => t.usuario.equals(usuarioId));
            await deleteQuery.go();
          }

          for (final doc in remoteDocs) {
            await _upsertTarefaHabito(doc);
          }
        });
      }

      if (lastSyncedAt != null) {
        final fullRemote =
            await remoteRepository.getTarefasEHabitos(usuarioId: usuarioId);
        final remoteIds = fullRemote.map((t) => t.id).toSet();
        final pendingIds = await _getPendingIds();
        final localRows = await localQuery.get();
        for (final row in localRows) {
          if (!remoteIds.contains(row.remoteId) &&
              !pendingIds.contains(row.remoteId)) {
            await (database.delete(database.tarefaHabitos)
                  ..where((t) => t.remoteId.equals(row.remoteId)))
                .go();
          }
        }
      }

      final updatedLocalDocs = await localQuery.get();
      return await _populatePeriodVezesPraticado(
        updatedLocalDocs.map(toDomain).toList(),
        usuarioId,
      );
    } catch (e) {
      log(
        'Appwrite offline or failed to fetch: $e. Returning cached local data.',
      );
      return await _populatePeriodVezesPraticado(localList, usuarioId);
    }
  }

  @override
  Future<List<HistoricoItemModel>> getHistorico({
    required String usuarioId,
    bool forceLocal = false,
    DateTime? lastSyncedAt,
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
        lastSyncedAt: lastSyncedAt,
      );

      if (remoteList.isNotEmpty || lastSyncedAt == null) {
        await database.transaction(() async {
          if (lastSyncedAt == null) {
            final deleteQuery = database.delete(database.historicoTarefasHabitos)
              ..where((h) => h.usuario.equals(usuarioId));
            await deleteQuery.go();
          }

          for (final item in remoteList) {
            await _upsertHistoricoItem(item);
          }
        });
      }

      if (lastSyncedAt != null) {
        final fullRemote =
            await remoteRepository.getHistorico(usuarioId: usuarioId);
        final remoteIds = fullRemote.map((h) => h.id).toSet();
        final pendingIds = await _getPendingIds();
        final localRows = await localQuery.get();
        for (final row in localRows) {
          if (!remoteIds.contains(row.remoteId) &&
              !pendingIds.contains(row.remoteId)) {
            await (database.delete(database.historicoTarefasHabitos)
                  ..where((h) => h.remoteId.equals(row.remoteId)))
                .go();
          }
        }
      }

      final updatedLocalRows = await localQuery.get();
      return updatedLocalRows
          .map((r) => toHistoricoDomain(r, habitsMap))
          .toList();
    } catch (e) {
      log('Appwrite offline or failed to fetch history: $e');
      return localList;
    }
  }

  @override
  Future<void> recordHistorico({
    required String foundId,
    required String usuarioId,
  }) async {
    // 1. Insert new history record locally into SQLite
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
    // 1. Find the history item to delete locally first
    final query = database.delete(database.historicoTarefasHabitos)
      ..where((h) => h.remoteId.equals(id));
    await query.go();

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
    return database
        .customSelect(
          'SELECT 1',
          readsFrom: {database.tarefaHabitos, database.historicoTarefasHabitos},
        )
        .watch()
        .asyncMap(
          (_) => getTarefasEHabitos(usuarioId: usuarioId, forceLocal: true),
        );
  }

  Future<List<TarefaHabitoModel>> _populatePeriodVezesPraticado(
    List<TarefaHabitoModel> items,
    String usuarioId,
  ) async {
    final historyQuery = database.select(database.historicoTarefasHabitos)
      ..where((h) => h.usuario.equals(usuarioId));
    final historyRows = await historyQuery.get();

    final Map<String, List<DateTime>> habitHistoryDates = {};
    for (final row in historyRows) {
      habitHistoryDates
          .putIfAbsent(row.tarefaHabitoId, () => [])
          .add(row.createdAt);
    }

    return items.map((habit) {
      if (habit.tipo != 'habito' || habit.tarefasHabitosQtd.isEmpty) {
        return habit;
      }

      final dates = habitHistoryDates[habit.id] ?? [];

      final updatedMetas = habit.tarefasHabitosQtd.map((meta) {
        final startPeriod = _calculateStartPeriod(
          createdAt: meta.createdAt,
          reiniciaEmTipo: meta.reiniciaEmTipo,
          reiniciaEmQtd: meta.reiniciaEmQtd,
        );

        final periodCount = dates.where((d) {
          final dDate = DateTime(d.year, d.month, d.day);
          return dDate.isAtSameMomentAs(startPeriod) ||
              dDate.isAfter(startPeriod);
        }).length;

        final calculatedVezes = periodCount * meta.valor;
        return meta.copyWith(vezesPraticado: calculatedVezes);
      }).toList();

      return habit.copyWith(tarefaHabitoQtd: updatedMetas);
    }).toList();
  }

  DateTime _calculateStartPeriod({
    required DateTime createdAt,
    required String reiniciaEmTipo,
    required int reiniciaEmQtd,
  }) {
    return TarefaHabitoQtdModel.calculateStartPeriod(
      createdAt: createdAt,
      reiniciaEmTipo: reiniciaEmTipo,
      reiniciaEmQtd: reiniciaEmQtd,
    );
  }


  Future<Set<String>> _getPendingIds() async {
    final syncs = await _getPendingSyncs();
    final Set<String> ids = {};
    for (final item in syncs) {
      final rowId = item['id'] as String? ?? item['rowId'] as String?;
      if (rowId != null && rowId.isNotEmpty) ids.add(rowId);
    }
    return ids;
  }

  Future<void> _upsertTarefaHabito(TarefaHabitoModel model) async {
    final existing = await (database.select(database.tarefaHabitos)
          ..where((t) => t.remoteId.equals(model.id)))
        .getSingleOrNull();
    if (existing != null) {
      await (database.update(database.tarefaHabitos)
            ..where((t) => t.remoteId.equals(model.id)))
          .write(toCompanion(model));
    } else {
      await database.into(database.tarefaHabitos).insert(toCompanion(model));
    }
  }

  Future<void> _upsertHistoricoItem(HistoricoItemModel model) async {
    final existing = await (database.select(database.historicoTarefasHabitos)
          ..where((h) => h.remoteId.equals(model.id)))
        .getSingleOrNull();
    if (existing != null) {
      await (database.update(database.historicoTarefasHabitos)
            ..where((h) => h.remoteId.equals(model.id)))
          .write(
            HistoricoTarefasHabitosCompanion(
              remoteId: Value(model.id),
              usuario: Value(model.usuario),
              createdAt: Value(model.createdAt),
              tarefaHabitoId: Value(model.tarefasEHabitos.id),
            ),
          );
    } else {
      await database.into(database.historicoTarefasHabitos).insert(
            HistoricoTarefasHabitosCompanion.insert(
              remoteId: model.id,
              usuario: model.usuario,
              createdAt: model.createdAt,
              tarefaHabitoId: model.tarefasEHabitos.id,
            ),
          );
    }
  }

  Future<void> _upsertHistoricoPayload(Map<String, dynamic> payload) async {
    final String rowId =
        payload[r'$id'] as String? ?? payload['id'] as String? ?? '';
    if (rowId.isEmpty) return;

    final String usuario = payload['usuario'] as String? ?? '';
    final String createdAtStr =
        payload[r'$createdAt'] as String? ?? payload['createdAt'] as String? ?? '';
    final DateTime createdAt =
        DateTime.tryParse(createdAtStr) ?? DateTime.now();

    final dynamic rawTarefa = payload['tarefasEHabitos'];
    String tarefaId = '';
    if (rawTarefa is Map) {
      tarefaId = (rawTarefa[r'$id'] ?? rawTarefa['id'] ?? '') as String;
    } else if (rawTarefa is String) {
      tarefaId = rawTarefa;
    }

    final existing = await (database.select(database.historicoTarefasHabitos)
          ..where((h) => h.remoteId.equals(rowId)))
        .getSingleOrNull();

    if (existing != null) {
      await (database.update(database.historicoTarefasHabitos)
            ..where((h) => h.remoteId.equals(rowId)))
          .write(
            HistoricoTarefasHabitosCompanion(
              remoteId: Value(rowId),
              usuario: Value(usuario),
              createdAt: Value(createdAt),
              tarefaHabitoId: Value(tarefaId),
            ),
          );
    } else {
      await database.into(database.historicoTarefasHabitos).insert(
            HistoricoTarefasHabitosCompanion.insert(
              remoteId: rowId,
              usuario: usuario,
              createdAt: createdAt,
              tarefaHabitoId: tarefaId,
            ),
          );
    }
  }

  Future<void> handleRealtimeEvent({
    required String tableId,
    required String action,
    required Map<String, dynamic> payload,
  }) async {
    final String rowId =
        payload[r'$id'] as String? ?? payload['id'] as String? ?? '';
    if (rowId.isEmpty) return;

    await database.transaction(() async {
      if (action == 'delete') {
        if (tableId == Core.tableTarefasEHabitos) {
          await (database.delete(database.tarefaHabitos)
                ..where((t) => t.remoteId.equals(rowId)))
              .go();
        } else if (tableId == Core.tableHistoricoTarefasHabitos) {
          await (database.delete(database.historicoTarefasHabitos)
                ..where((h) => h.remoteId.equals(rowId)))
              .go();
        }
      } else if (action == 'create' || action == 'update') {
        if (tableId == Core.tableTarefasEHabitos) {
          final model = TarefaHabitoModel.fromMap(payload);
          await _upsertTarefaHabito(model);
        } else if (tableId == Core.tableHistoricoTarefasHabitos) {
          await _upsertHistoricoPayload(payload);
        }
      }
    });
  }
}
