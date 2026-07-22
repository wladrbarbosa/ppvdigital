import 'dart:convert';
import 'dart:developer';

import 'package:appwrite/appwrite.dart';
import 'package:drift/drift.dart';
import 'package:ppvdigital/core.dart';
import 'package:ppvdigital/models/categoria_transacao_model.dart';
import 'package:ppvdigital/models/conta_model.dart';
import 'package:ppvdigital/models/contato_model.dart';
import 'package:ppvdigital/models/divisao_transacao_model.dart';
import 'package:ppvdigital/models/local/app_database.dart';
import 'package:ppvdigital/models/transacao_model.dart';
import 'package:ppvdigital/models/transacao_recorrencia_model.dart';
import 'package:ppvdigital/repositories/financas_repository.dart';

class DriftFinancasRepository implements FinancasRepository {
  DriftFinancasRepository({
    required this.database,
    required this.remoteRepository,
  });
  final AppDatabase database;
  final FinancasRepository remoteRepository;

  Contato toContatoRow(ContatoModel model) {
    return Contato(
      id: 0,
      remoteId: model.id,
      ownerId: model.ownerId,
      nome: model.nome,
      telefone: model.telefone,
      email: model.email,
      userId: model.userId,
    );
  }

  ContatosCompanion toContatoCompanion(ContatoModel model) {
    return ContatosCompanion.insert(
      remoteId: model.id,
      ownerId: model.ownerId,
      nome: model.nome,
      telefone: Value(model.telefone),
      email: Value(model.email),
      userId: Value(model.userId),
    );
  }

  ContatoModel toContatoDomain(Contato row) {
    return ContatoModel(
      id: row.remoteId,
      ownerId: row.ownerId,
      nome: row.nome,
      telefone: row.telefone,
      email: row.email,
      userId: row.userId,
    );
  }

  Conta toContaRow(ContaModel model) {
    return Conta(
      id: 0,
      remoteId: model.id,
      name: model.name,
      userId: model.userId,
      saldoAtual: model.saldoAtual,
    );
  }

  ContasCompanion toContaCompanion(ContaModel model) {
    return ContasCompanion.insert(
      remoteId: model.id,
      name: model.name,
      userId: model.userId,
      saldoAtual: model.saldoAtual,
    );
  }

  ContaModel toContaDomain(Conta row) {
    return ContaModel(
      id: row.remoteId,
      name: row.name,
      userId: row.userId,
      saldoAtual: row.saldoAtual,
    );
  }

  CategoriaTransacoe toCategoriaRow(CategoriaTransacaoModel model) {
    return CategoriaTransacoe(
      id: 0,
      remoteId: model.id,
      nome: model.name,
      corHex: model.cor?.toHex() ?? '#ffffff',
      userId: model.userId,
    );
  }

  CategoriaTransacoesCompanion toCategoriaCompanion(
    CategoriaTransacaoModel model,
  ) {
    return CategoriaTransacoesCompanion.insert(
      remoteId: model.id,
      nome: model.name,
      corHex: model.cor?.toHex() ?? '#ffffff',
      userId: model.userId,
    );
  }

  CategoriaTransacaoModel toCategoriaDomain(CategoriaTransacoe row) {
    return CategoriaTransacaoModel(
      id: row.remoteId,
      name: row.nome,
      cor: HexColor.fromHex(row.corHex),
      userId: row.userId,
    );
  }

  TransacaosCompanion toTransacaoCompanion(TransacaoModel model) {
    return TransacaosCompanion.insert(
      remoteId: model.id,
      descricao: model.descricao,
      valor: model.valor,
      tipo: model.tipo,
      dataCompetencia: model.dataCompetencia,
      consolidada: model.consolidada,
      contaId: Value(model.conta?.id),
      contaDestinoId: Value(model.contaDestino?.id),
      categoriaId: Value(model.categoria?.id),
      devedorContatoId: Value(model.devedorContato?.id),
      credorContatoId: Value(model.credorContato?.id),
      divisoes: model.divisoes,
      recorrencia: Value(model.recorrencia),
    );
  }

  TransacaoModel toTransacaoDomain(
    Transacao row, {
    required Map<String, ContaModel> contasMap,
    required Map<String, ContatoModel> contatosMap,
    required Map<String, CategoriaTransacaoModel> categoriasMap,
  }) {
    return TransacaoModel(
      id: row.remoteId,
      descricao: row.descricao,
      valor: row.valor,
      tipo: row.tipo,
      dataCompetencia: row.dataCompetencia,
      consolidada: row.consolidada,
      conta: row.contaId != null ? contasMap[row.contaId] : null,
      contaDestino: row.contaDestinoId != null
          ? contasMap[row.contaDestinoId]
          : null,
      categoria: row.categoriaId != null
          ? categoriasMap[row.categoriaId]
          : null,
      devedorContato: row.devedorContatoId != null
          ? contatosMap[row.devedorContatoId]
          : null,
      credorContato: row.credorContatoId != null
          ? contatosMap[row.credorContatoId]
          : null,
      recorrencia: row.recorrencia,
      divisoes: row.divisoes
          .map((d) => d.copyWith(transacaoId: row.remoteId))
          .toList(),
    );
  }

  @override
  Future<List<ContatoModel>> getContatos({
    required String usuarioId,
    bool forceLocal = false,
    DateTime? lastSyncedAt,
  }) async {
    final localQuery = database.select(database.contatos)
      ..where((c) => c.ownerId.equals(usuarioId));
    final local = await localQuery.get();
    final localList = local.map(toContatoDomain).toList();

    if (forceLocal) {
      return localList;
    }

    await flushPendingSyncs();

    try {
      final remote = await remoteRepository.getContatos(
        usuarioId: usuarioId,
        lastSyncedAt: lastSyncedAt,
      );
      if (remote.isNotEmpty || lastSyncedAt == null) {
        await database.transaction(() async {
          if (lastSyncedAt == null) {
            final deleteQuery = database.delete(database.contatos)
              ..where((c) => c.ownerId.equals(usuarioId));
            await deleteQuery.go();
          }

          for (final item in remote) {
            await database
                .into(database.contatos)
                .insertOnConflictUpdate(toContatoCompanion(item));
          }
        });
      }
      return (await localQuery.get()).map(toContatoDomain).toList();
    } catch (e) {
      log('Offline contatos load fallback: $e');
      return local.map(toContatoDomain).toList();
    }
  }

  @override
  Future<ContatoModel> createContato({
    required String ownerId,
    required String nome,
    String? email,
    String? userId,
  }) async {
    final result = await remoteRepository.createContato(
      ownerId: ownerId,
      nome: nome,
      email: email,
      userId: userId,
    );
    await database.into(database.contatos).insert(toContatoCompanion(result));
    return result;
  }

  @override
  Future<List<ContaModel>> getContas({
    required String usuarioId,
    bool forceLocal = false,
    DateTime? lastSyncedAt,
  }) async {
    final localQuery = database.select(database.contas)
      ..where((c) => c.userId.equals(usuarioId));
    final local = await localQuery.get();
    final localList = local.map(toContaDomain).toList();

    if (forceLocal) {
      return localList;
    }

    await flushPendingSyncs();

    try {
      final remote = await remoteRepository.getContas(
        usuarioId: usuarioId,
        lastSyncedAt: lastSyncedAt,
      );
      if (remote.isNotEmpty || lastSyncedAt == null) {
        await database.transaction(() async {
          if (lastSyncedAt == null) {
            final deleteQuery = database.delete(database.contas)
              ..where((c) => c.userId.equals(usuarioId));
            await deleteQuery.go();
          }

          for (final item in remote) {
            await database.into(database.contas).insertOnConflictUpdate(toContaCompanion(item));
          }
        });
      }
      return (await localQuery.get()).map(toContaDomain).toList();
    } catch (e) {
      log('Offline contas load fallback: $e');
      return local.map(toContaDomain).toList();
    }
  }

  @override
  Future<bool> createConta({
    required String name,
    required double saldoInicial,
    required String usuarioId,
  }) async {
    final success = await remoteRepository.createConta(
      name: name,
      saldoInicial: saldoInicial,
      usuarioId: usuarioId,
    );
    return success;
  }

  @override
  Future<bool> updateConta({
    required String id,
    required String name,
    required double saldoAtual,
  }) async {
    final localQuery = database.select(database.contas)
      ..where((c) => c.remoteId.equals(id));
    final local = await localQuery.getSingleOrNull();

    if (local != null) {
      final updateQuery = database.update(database.contas)
        ..where((c) => c.remoteId.equals(id));
      await updateQuery.write(
        ContasCompanion(name: Value(name), saldoAtual: Value(saldoAtual)),
      );
    }

    await _addPendingSync({
      'actionType': 'updateConta',
      'id': id,
      'name': name,
      'saldoAtual': saldoAtual,
    });

    try {
      await remoteRepository.updateConta(
        id: id,
        name: name,
        saldoAtual: saldoAtual,
      );
      final syncs = await _getPendingSyncs();
      syncs.removeWhere(
        (item) =>
            item['actionType'] == 'updateConta' &&
            item['id'] == id &&
            item['name'] == name &&
            item['saldoAtual'] == saldoAtual,
      );
      await _savePendingSyncs(syncs);
      return true;
    } catch (e) {
      log('Remote update account failed: $e. Saved to offline queue.');
      return true;
    }
  }

  @override
  Future<bool> deleteConta({required String id}) async {
    final localQuery = database.select(database.contas)
      ..where((c) => c.remoteId.equals(id));
    final local = await localQuery.getSingleOrNull();

    if (local != null) {
      final deleteQuery = database.delete(database.contas)
        ..where((c) => c.remoteId.equals(id));
      await deleteQuery.go();
    }

    try {
      return await remoteRepository.deleteConta(id: id);
    } catch (e) {
      log('Remote delete account failed: $e');
      rethrow;
    }
  }

  @override
  Future<List<CategoriaTransacaoModel>> getCategorias({
    required String usuarioId,
    bool forceLocal = false,
    DateTime? lastSyncedAt,
  }) async {
    final localQuery = database.select(database.categoriaTransacoes)
      ..where((c) => c.userId.equals(usuarioId));
    final local = await localQuery.get();
    final localList = local.map(toCategoriaDomain).toList();

    if (forceLocal) {
      return localList;
    }

    await flushPendingSyncs();

    try {
      final remote = await remoteRepository.getCategorias(
        usuarioId: usuarioId,
        lastSyncedAt: lastSyncedAt,
      );
      if (remote.isNotEmpty || lastSyncedAt == null) {
        await database.transaction(() async {
          if (lastSyncedAt == null) {
            final deleteQuery = database.delete(database.categoriaTransacoes)
              ..where((c) => c.userId.equals(usuarioId));
            await deleteQuery.go();
          }

          for (final item in remote) {
            await database
                .into(database.categoriaTransacoes)
                .insertOnConflictUpdate(toCategoriaCompanion(item));
          }
        });
      }
      return (await localQuery.get()).map(toCategoriaDomain).toList();
    } catch (e) {
      log('Offline categorias load fallback: $e');
      return local.map(toCategoriaDomain).toList();
    }
  }

  @override
  Future<bool> createCategoria({
    required String name,
    String? icone,
    required String hexColor,
    required String usuarioId,
  }) async {
    return await remoteRepository.createCategoria(
      name: name,
      icone: icone,
      hexColor: hexColor,
      usuarioId: usuarioId,
    );
  }

  @override
  Future<bool> updateCategoria({
    required String id,
    required String name,
    String? icone,
    required String hexColor,
  }) async {
    final localQuery = database.select(database.categoriaTransacoes)
      ..where((c) => c.remoteId.equals(id));
    final local = await localQuery.getSingleOrNull();

    if (local != null) {
      final updateQuery = database.update(database.categoriaTransacoes)
        ..where((c) => c.remoteId.equals(id));
      await updateQuery.write(
        CategoriaTransacoesCompanion(
          nome: Value(name),
          corHex: Value(hexColor),
        ),
      );
    }

    try {
      return await remoteRepository.updateCategoria(
        id: id,
        name: name,
        icone: icone,
        hexColor: hexColor,
      );
    } catch (e) {
      log('Remote update category failed: $e');
      rethrow;
    }
  }

  @override
  Future<bool> deleteCategoria({required String id}) async {
    final localQuery = database.select(database.categoriaTransacoes)
      ..where((c) => c.remoteId.equals(id));
    final local = await localQuery.getSingleOrNull();

    if (local != null) {
      final deleteQuery = database.delete(database.categoriaTransacoes)
        ..where((c) => c.remoteId.equals(id));
      await deleteQuery.go();
    }

    try {
      return await remoteRepository.deleteCategoria(id: id);
    } catch (e) {
      log('Remote delete category failed: $e');
      rethrow;
    }
  }

  @override
  Future<List<TransacaoModel>> getTransacoes({
    required String usuarioId,
    required List<String> contaIds,
    DateTime? targetMonth,
    DateTime? beforeDate,
    bool lightweight = false,
    bool forceLocal = false,
    DateTime? lastSyncedAt,
  }) async {
    final localContas = await database.select(database.contas).get();
    final localContatos = await database.select(database.contatos).get();
    final localCategorias = await database
        .select(database.categoriaTransacoes)
        .get();

    final contasMap = {
      for (final c in localContas) c.remoteId: toContaDomain(c),
    };
    final contatosMap = {
      for (final c in localContatos) c.remoteId: toContatoDomain(c),
    };
    final categoriasMap = {
      for (final c in localCategorias) c.remoteId: toCategoriaDomain(c),
    };

    final localQuery = database.select(database.transacaos);

    if (targetMonth != null) {
      final firstDayOfMonth = DateTime(targetMonth.year, targetMonth.month);
      final lastDayOfMonth = DateTime(
        targetMonth.year,
        targetMonth.month + 1,
      ).subtract(const Duration(milliseconds: 1));
      localQuery.where(
        (t) =>
            t.dataCompetencia.isBiggerThanValue(
              firstDayOfMonth.subtract(const Duration(seconds: 1)),
            ) &
            t.dataCompetencia.isSmallerThanValue(
              lastDayOfMonth.add(const Duration(seconds: 1)),
            ),
      );
    } else if (beforeDate != null) {
      localQuery.where((t) => t.dataCompetencia.isSmallerThanValue(beforeDate));
    }

    final localTrans = await localQuery.get();
    final localList = localTrans
        .map(
          (t) => toTransacaoDomain(
            t,
            contasMap: contasMap,
            contatosMap: contatosMap,
            categoriasMap: categoriasMap,
          ),
        )
        .toList();

    if (forceLocal) {
      return localList;
    }

    await flushPendingSyncs();

    try {
      final remote = await remoteRepository.getTransacoes(
        usuarioId: usuarioId,
        contaIds: contaIds,
        targetMonth: targetMonth,
        beforeDate: beforeDate,
        lightweight: lightweight,
        lastSyncedAt: lastSyncedAt,
      );

      if (!lightweight && (remote.isNotEmpty || lastSyncedAt == null)) {
        await database.transaction(() async {
          if (lastSyncedAt == null) {
            final deleteQuery = database.delete(database.transacaos);
            if (targetMonth != null) {
              final firstDayOfMonth = DateTime(
                targetMonth.year,
                targetMonth.month,
              );
              final lastDayOfMonth = DateTime(
                targetMonth.year,
                targetMonth.month + 1,
              ).subtract(const Duration(milliseconds: 1));
              deleteQuery.where(
                (t) =>
                    t.dataCompetencia.isBiggerThanValue(
                      firstDayOfMonth.subtract(const Duration(seconds: 1)),
                    ) &
                    t.dataCompetencia.isSmallerThanValue(
                      lastDayOfMonth.add(const Duration(seconds: 1)),
                    ),
              );
            } else if (beforeDate != null) {
              deleteQuery.where(
                (t) => t.dataCompetencia.isSmallerThanValue(beforeDate),
              );
            }
            await deleteQuery.go();
          }

          for (final item in remote) {
            await database
                .into(database.transacaos)
                .insertOnConflictUpdate(toTransacaoCompanion(item));
          }
        });
      }

      final updatedLocalTrans = await localQuery.get();
      return updatedLocalTrans
          .map(
            (t) => toTransacaoDomain(
              t,
              contasMap: contasMap,
              contatosMap: contatosMap,
              categoriasMap: categoriasMap,
            ),
          )
          .toList();
    } catch (e) {
      log('Offline transactions load fallback: $e');
      return localList;
    }
  }

  @override
  Future<List<TransacaoModel>> getRecurrenceSeries({
    required String recurrenceId,
  }) async {
    try {
      return await remoteRepository.getRecurrenceSeries(
        recurrenceId: recurrenceId,
      );
    } catch (e) {
      log('Offline recurrence series load fallback: $e');
      final localContas = await database.select(database.contas).get();
      final localContatos = await database.select(database.contatos).get();
      final localCategorias = await database
          .select(database.categoriaTransacoes)
          .get();

      final contasMap = {
        for (final c in localContas) c.remoteId: toContaDomain(c),
      };
      final contatosMap = {
        for (final c in localContatos) c.remoteId: toContatoDomain(c),
      };
      final categoriasMap = {
        for (final c in localCategorias) c.remoteId: toCategoriaDomain(c),
      };

      final allTrans = await database.select(database.transacaos).get();
      final localTrans = allTrans
          .where((t) => t.recorrencia?.id == recurrenceId)
          .toList();

      return localTrans
          .map(
            (t) => toTransacaoDomain(
              t,
              contasMap: contasMap,
              contatosMap: contatosMap,
              categoriasMap: categoriasMap,
            ),
          )
          .toList();
    }
  }

  @override
  Future<List<DivisaoTransacaoModel>> getDivisoes({
    required List<String> contatoResponsavelIds,
    bool forceLocal = false,
  }) async {
    if (forceLocal) {
      return [];
    }
    try {
      return await remoteRepository.getDivisoes(
        contatoResponsavelIds: contatoResponsavelIds,
      );
    } catch (e) {
      log('Offline divisions fetch: $e');
      return [];
    }
  }

  @override
  Future<String> createRecorrenciaRow({
    required String tipoRecorrencia,
    required int frequencia,
    int? totalParcelas,
    int? parcelaInicio,
    DateTime? fimRecorrencia,
  }) async {
    return await remoteRepository.createRecorrenciaRow(
      tipoRecorrencia: tipoRecorrencia,
      frequencia: frequencia,
      totalParcelas: totalParcelas,
      parcelaInicio: parcelaInicio,
      fimRecorrencia: fimRecorrencia,
    );
  }

  @override
  Future<void> updateAccountBalance({
    required String contaId,
    required double newSaldo,
  }) async {
    final localQuery = database.select(database.contas)
      ..where((c) => c.remoteId.equals(contaId));
    final local = await localQuery.getSingleOrNull();

    if (local != null) {
      final updateQuery = database.update(database.contas)
        ..where((c) => c.remoteId.equals(contaId));
      await updateQuery.write(ContasCompanion(saldoAtual: Value(newSaldo)));
    }

    await _addPendingSync({
      'actionType': 'updateAccountBalance',
      'contaId': contaId,
      'newSaldo': newSaldo,
    });

    try {
      await remoteRepository.updateAccountBalance(
        contaId: contaId,
        newSaldo: newSaldo,
      );
      final syncs = await _getPendingSyncs();
      syncs.removeWhere(
        (item) =>
            item['actionType'] == 'updateAccountBalance' &&
            item['contaId'] == contaId &&
            item['newSaldo'] == newSaldo,
      );
      await _savePendingSyncs(syncs);
    } catch (e) {
      log('Remote update account balance failed: $e. Saved to offline queue.');
    }
  }

  @override
  Future<void> deleteRow({
    required String tableId,
    required String rowId,
  }) async {
    // Delete locally if it is transaction
    if (tableId == Core.tableTransacoes) {
      final deleteQuery = database.delete(database.transacaos)
        ..where((t) => t.remoteId.equals(rowId));
      await deleteQuery.go();
    }

    await _addPendingSync({
      'actionType': 'deleteRow',
      'tableId': tableId,
      'rowId': rowId,
    });

    try {
      await remoteRepository.deleteRow(tableId: tableId, rowId: rowId);
      final syncs = await _getPendingSyncs();
      syncs.removeWhere(
        (item) =>
            item['actionType'] == 'deleteRow' &&
            item['tableId'] == tableId &&
            item['rowId'] == rowId,
      );
      await _savePendingSyncs(syncs);
    } catch (e) {
      log('Remote delete row failed: $e. Saved to offline queue.');
    }
  }

  @override
  Future<void> updateRow({
    required String tableId,
    required String rowId,
    required Map<String, dynamic> data,
  }) async {
    if (tableId == Core.tableContatos) {
      final updateQuery = database.update(database.contatos)
        ..where((c) => c.remoteId.equals(rowId));
      await updateQuery.write(
        ContatosCompanion(
          nome: data['nome'] != null
              ? Value(data['nome'] as String)
              : const Value.absent(),
          email: data['email'] != null
              ? Value(data['email'] as String?)
              : const Value.absent(),
          telefone: data['telefone'] != null
              ? Value(data['telefone'] as String?)
              : const Value.absent(),
        ),
      );
    }

    await _addPendingSync({
      'actionType': 'updateRow',
      'tableId': tableId,
      'rowId': rowId,
      'data': json.encode(data),
    });

    try {
      await remoteRepository.updateRow(
        tableId: tableId,
        rowId: rowId,
        data: data,
      );
      final syncs = await _getPendingSyncs();
      syncs.removeWhere(
        (item) =>
            item['actionType'] == 'updateRow' &&
            item['tableId'] == tableId &&
            item['rowId'] == rowId &&
            item['data'] == json.encode(data),
      );
      await _savePendingSyncs(syncs);
    } catch (e) {
      log('Remote update row failed: $e. Saved to offline queue.');
    }
  }

  @override
  Future<void> executeBatchOperations(
    List<Map<String, dynamic>> operations,
  ) async {
    await _applyBatchLocally(operations);

    await _addPendingSync({
      'actionType': 'executeBatchOperations',
      'operations': json.encode(operations),
    });

    try {
      await remoteRepository.executeBatchOperations(operations);
      final syncs = await _getPendingSyncs();
      syncs.removeWhere(
        (item) =>
            item['actionType'] == 'executeBatchOperations' &&
            item['operations'] == json.encode(operations),
      );
      await _savePendingSyncs(syncs);
    } catch (e) {
      log(
        'Remote execute batch operations failed: $e. Saved to offline queue.',
      );
    }
  }

  @override
  Stream<List<ContatoModel>> watchContatos({required String usuarioId}) {
    final query = database.select(database.contatos)
      ..where((c) => c.ownerId.equals(usuarioId));
    return query.watch().map((rows) => rows.map(toContatoDomain).toList());
  }

  @override
  Stream<List<ContaModel>> watchContas({required String usuarioId}) {
    final query = database.select(database.contas)
      ..where((c) => c.userId.equals(usuarioId));
    return query.watch().map((rows) => rows.map(toContaDomain).toList());
  }

  @override
  Stream<List<CategoriaTransacaoModel>> watchCategorias({
    required String usuarioId,
  }) {
    final query = database.select(database.categoriaTransacoes)
      ..where((c) => c.userId.equals(usuarioId));
    return query.watch().map((rows) => rows.map(toCategoriaDomain).toList());
  }

  @override
  Stream<List<TransacaoModel>> watchTransacoes({
    required String usuarioId,
    required List<String> contaIds,
    DateTime? targetMonth,
  }) {
    final stream = database.select(database.transacaos).watch();
    return stream.asyncMap((localTrans) async {
      final localContas = await database.select(database.contas).get();
      final localContatos = await database.select(database.contatos).get();
      final localCategorias = await database
          .select(database.categoriaTransacoes)
          .get();

      final contasMap = {
        for (final c in localContas) c.remoteId: toContaDomain(c),
      };
      final contatosMap = {
        for (final c in localContatos) c.remoteId: toContatoDomain(c),
      };
      final categoriasMap = {
        for (final c in localCategorias) c.remoteId: toCategoriaDomain(c),
      };

      Iterable<Transacao> filtered = localTrans;
      if (targetMonth != null) {
        final firstDayOfMonth = DateTime(targetMonth.year, targetMonth.month);
        final lastDayOfMonth = DateTime(
          targetMonth.year,
          targetMonth.month + 1,
        ).subtract(const Duration(milliseconds: 1));

        filtered = localTrans.where(
          (t) =>
              t.dataCompetencia.isAfter(
                firstDayOfMonth.subtract(const Duration(seconds: 1)),
              ) &&
              t.dataCompetencia.isBefore(
                lastDayOfMonth.add(const Duration(seconds: 1)),
              ),
        );
      }

      return filtered
          .map(
            (t) => toTransacaoDomain(
              t,
              contasMap: contasMap,
              contatosMap: contatosMap,
              categoriasMap: categoriasMap,
            ),
          )
          .toList();
    });
  }

  Future<List<Map<String, dynamic>>> _getPendingSyncs() async {
    final str = await database.getSetting('pending_financas_syncs');
    if (str == null || str.isEmpty) return [];
    final list = json.decode(str) as List;
    return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<void> _savePendingSyncs(List<Map<String, dynamic>> syncs) async {
    final str = json.encode(syncs);
    await database.setSetting('pending_financas_syncs', str);
  }

  Future<void> _addPendingSync(Map<String, dynamic> syncItem) async {
    final syncs = await _getPendingSyncs();
    syncs.add(syncItem);
    await _savePendingSyncs(syncs);
  }

  Future<void> flushPendingSyncs() async {
    final syncs = await _getPendingSyncs();
    if (syncs.isEmpty) return;

    log('Flushing ${syncs.length} pending offline syncs for Financas...');
    final remainingSyncs = List<Map<String, dynamic>>.from(syncs);

    for (final item in syncs) {
      final actionType = item['actionType'] as String;
      try {
        if (actionType == 'executeBatchOperations') {
          final ops = List<Map<String, dynamic>>.from(
            json.decode(item['operations'] as String) as List,
          );
          await remoteRepository.executeBatchOperations(ops);
        } else if (actionType == 'updateAccountBalance') {
          final contaId = item['contaId'] as String;
          final newSaldo = item['newSaldo'] as double;
          await remoteRepository.updateAccountBalance(
            contaId: contaId,
            newSaldo: newSaldo,
          );
        } else if (actionType == 'deleteRow') {
          final tableId = item['tableId'] as String;
          final rowId = item['rowId'] as String;
          await remoteRepository.deleteRow(tableId: tableId, rowId: rowId);
        } else if (actionType == 'updateRow') {
          final tableId = item['tableId'] as String;
          final rowId = item['rowId'] as String;
          final data =
              json.decode(item['data'] as String) as Map<String, dynamic>;
          await remoteRepository.updateRow(
            tableId: tableId,
            rowId: rowId,
            data: data,
          );
        } else if (actionType == 'updateConta') {
          final id = item['id'] as String;
          final name = item['name'] as String;
          final saldoAtual = item['saldoAtual'] as double;
          await remoteRepository.updateConta(
            id: id,
            name: name,
            saldoAtual: saldoAtual,
          );
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

  Future<void> _applyBatchLocally(List<Map<String, dynamic>> operations) async {
    await database.transaction(() async {
      for (final op in operations) {
        final action = op['action'] as String;
        final tableId = op['tableId'] as String;
        final rowId = op['rowId'] as String;
        final data = op['data'] as Map<String, dynamic>?;

        if (tableId == Core.tableTransacoes) {
          if (action == 'delete') {
            final deleteQuery = database.delete(database.transacaos)
              ..where((t) => t.remoteId.equals(rowId));
            await deleteQuery.go();
          } else if (action == 'create' && data != null) {
            final model = _parseTransacaoModelFromData(rowId, data);
            await database
                .into(database.transacaos)
                .insert(
                  toTransacaoCompanion(model),
                  mode: InsertMode.insertOrReplace,
                );
          } else if (action == 'update' && data != null) {
            final companion = _mapDataToTransacaoCompanion(data);
            final updateQuery = database.update(database.transacaos)
              ..where((t) => t.remoteId.equals(rowId));
            await updateQuery.write(companion);
          }
        } else if (tableId == Core.tableDivisaoTransacoes) {
          if (action == 'create' && data != null) {
            final transId = data['transacao'] as String;
            final query = database.select(database.transacaos)
              ..where((t) => t.remoteId.equals(transId));
            final row = await query.getSingleOrNull();
            if (row != null) {
              final newDiv = DivisaoTransacaoModel(
                id: rowId,
                transacaoId: transId,
                contatoResponsavel: data['contatoResponsavel'] as String? ?? '',
                peso: (data['peso'] as num).toDouble(),
              );
              final List<DivisaoTransacaoModel> updatedDivs = List.from(
                row.divisoes,
              )..add(newDiv);
              final updateQuery = database.update(database.transacaos)
                ..where((t) => t.remoteId.equals(transId));
              await updateQuery.write(
                TransacaosCompanion(divisoes: Value(updatedDivs)),
              );
            }
          } else if (action == 'delete') {
            final allTx = await database.select(database.transacaos).get();
            for (final tx in allTx) {
              if (tx.divisoes.any((d) => d.id == rowId)) {
                final List<DivisaoTransacaoModel> updatedDivs = List.from(
                  tx.divisoes,
                )..removeWhere((d) => d.id == rowId);
                final updateQuery = database.update(database.transacaos)
                  ..where((t) => t.remoteId.equals(tx.remoteId));
                await updateQuery.write(
                  TransacaosCompanion(divisoes: Value(updatedDivs)),
                );
                break;
              }
            }
          }
        }
      }
    });
  }

  TransacaosCompanion _mapDataToTransacaoCompanion(Map<String, dynamic> data) {
    return TransacaosCompanion(
      descricao: data.containsKey('descricao')
          ? Value(data['descricao'] as String)
          : const Value.absent(),
      valor: data.containsKey('valor')
          ? Value((data['valor'] as num).toDouble())
          : const Value.absent(),
      tipo: data.containsKey('tipo')
          ? Value(data['tipo'] as String)
          : const Value.absent(),
      dataCompetencia: data.containsKey('dataCompetencia')
          ? Value(TransacaoModel.parseDateCompetencia(data['dataCompetencia'] as String))
          : const Value.absent(),
      consolidada: data.containsKey('consolidada')
          ? Value(data['consolidada'] as bool)
          : const Value.absent(),
      contaId: data.containsKey('conta')
          ? Value(data['conta'] as String?)
          : const Value.absent(),
      contaDestinoId: data.containsKey('contaDestino')
          ? Value(data['contaDestino'] as String?)
          : const Value.absent(),
      categoriaId: data.containsKey('categoria')
          ? Value(data['categoria'] as String?)
          : const Value.absent(),
      devedorContatoId: data.containsKey('devedorContato')
          ? Value(data['devedorContato'] as String?)
          : const Value.absent(),
      credorContatoId: data.containsKey('credorContato')
          ? Value(data['credorContato'] as String?)
          : const Value.absent(),
      recorrencia: data.containsKey('recorrencia')
          ? (data['recorrencia'] is Map
              ? Value(TransacaoRecorrenciaModel.fromMap(
                  Map<String, dynamic>.from(data['recorrencia'] as Map),
                ))
              : (data['recorrencia'] is String && (data['recorrencia'] as String).isNotEmpty
                  ? Value(TransacaoRecorrenciaModel(
                      id: data['recorrencia'] as String,
                      tipoRecorrencia: 'mês',
                      frequencia: 1,
                    ))
                  : const Value(null)))
          : const Value.absent(),
    );
  }

  TransacaoModel _parseTransacaoModelFromData(
    String id,
    Map<String, dynamic> data,
  ) {
    final contaId = data['conta'] as String?;
    final contaDestinoId = data['contaDestino'] as String?;
    final categoriaId = data['categoria'] as String?;
    final devedorContatoId = data['devedorContato'] as String?;
    final credorContatoId = data['credorContato'] as String?;

    return TransacaoModel(
      id: id,
      descricao: data['descricao'] as String? ?? '',
      valor: (data['valor'] as num?)?.toDouble() ?? 0.0,
      tipo: data['tipo'] as String? ?? 'despesa',
      dataCompetencia: data['dataCompetencia'] != null
          ? TransacaoModel.parseDateCompetencia(data['dataCompetencia'] as String)
          : DateTime.now(),
      consolidada: data['consolidada'] as bool? ?? false,
      conta: contaId != null
          ? ContaModel(id: contaId, name: '', saldoAtual: 0.0, userId: '')
          : null,
      contaDestino: contaDestinoId != null
          ? ContaModel(
              id: contaDestinoId,
              name: '',
              saldoAtual: 0.0,
              userId: '',
            )
          : null,
      categoria: CategoriaTransacaoModel(
        id: categoriaId ?? '',
        userId: '',
        name: '',
      ),
      devedorContato: devedorContatoId != null
          ? ContatoModel(id: devedorContatoId, ownerId: '', nome: '')
          : null,
      credorContato: credorContatoId != null
          ? ContatoModel(id: credorContatoId, ownerId: '', nome: '')
          : null,
      divisoes: [],
    );
  }
}
