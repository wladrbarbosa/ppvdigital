import 'dart:developer';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:ppvdigital/core.dart';
import 'package:ppvdigital/models/categoria_transacao_model.dart';
import 'package:ppvdigital/models/conta_model.dart';
import 'package:ppvdigital/models/contato_model.dart';
import 'package:ppvdigital/models/divisao_transacao_model.dart';
import 'package:ppvdigital/models/transacao_model.dart';
import 'package:ppvdigital/repositories/financas_repository.dart';

class AppwriteFinancasRepository implements FinancasRepository {
  AppwriteFinancasRepository(this.databases);
  final Databases databases;

  @override
  Future<List<ContatoModel>> getContatos({
    required String usuarioId,
    bool forceLocal = false,
    DateTime? lastSyncedAt,
  }) async {
    final TablesDB tablesDB = TablesDB(databases.client);
    final queries = [Query.equal('ownerId', usuarioId), Query.limit(5000)];
    if (lastSyncedAt != null) {
      queries.add(Query.greaterThan(r'$updatedAt', lastSyncedAt.toIso8601String()));
    }
    final contatosDocs = await tablesDB.listRows(
      databaseId: Core.databaseId,
      tableId: Core.tableContatos,
      queries: queries,
    );
    return contatosDocs.rows.map((d) {
      final map = Map<String, dynamic>.from(d.data);
      map['\$id'] = d.$id;
      return ContatoModel.fromMap(map);
    }).toList();
  }

  @override
  Future<ContatoModel> createContato({
    required String ownerId,
    required String nome,
    String? email,
    String? userId,
  }) async {
    final TablesDB tablesDB = TablesDB(databases.client);
    final Row newContactRow = await tablesDB.createRow(
      databaseId: Core.databaseId,
      tableId: Core.tableContatos,
      rowId: ID.unique(),
      data: {
        'ownerId': ownerId,
        'nome': nome,
        'email': email,
        'userId': userId,
      },
    );
    final map = Map<String, dynamic>.from(newContactRow.data);
    map['\$id'] = newContactRow.$id;
    return ContatoModel.fromMap(map);
  }

  @override
  Future<List<ContaModel>> getContas({
    required String usuarioId,
    bool forceLocal = false,
    DateTime? lastSyncedAt,
  }) async {
    final TablesDB tablesDB = TablesDB(databases.client);
    final queries = [Query.equal('userId', usuarioId), Query.limit(5000)];
    if (lastSyncedAt != null) {
      queries.add(Query.greaterThan(r'$updatedAt', lastSyncedAt.toIso8601String()));
    }
    final accountsDocs = await tablesDB.listRows(
      databaseId: Core.databaseId,
      tableId: Core.tableContas,
      queries: queries,
    );
    return accountsDocs.rows.map((d) {
      final map = Map<String, dynamic>.from(d.data);
      map['\$id'] = d.$id;
      return ContaModel.fromMap(map);
    }).toList();
  }

  @override
  Future<bool> createConta({
    required String name,
    required double saldoInicial,
    required String usuarioId,
  }) async {
    final TablesDB tablesDB = TablesDB(databases.client);
    await tablesDB.createRow(
      databaseId: Core.databaseId,
      tableId: Core.tableContas,
      rowId: ID.unique(),
      data: {'name': name, 'userId': usuarioId, 'saldoAtual': saldoInicial},
    );
    return true;
  }

  @override
  Future<bool> updateConta({
    required String id,
    required String name,
    required double saldoAtual,
  }) async {
    final TablesDB tablesDB = TablesDB(databases.client);
    await tablesDB.updateRow(
      databaseId: Core.databaseId,
      tableId: Core.tableContas,
      rowId: id,
      data: {'name': name, 'saldoAtual': saldoAtual},
    );
    return true;
  }

  @override
  Future<bool> deleteConta({required String id}) async {
    final TablesDB tablesDB = TablesDB(databases.client);
    await tablesDB.deleteRow(
      databaseId: Core.databaseId,
      tableId: Core.tableContas,
      rowId: id,
    );
    return true;
  }

  @override
  Future<List<CategoriaTransacaoModel>> getCategorias({
    required String usuarioId,
    bool forceLocal = false,
    DateTime? lastSyncedAt,
  }) async {
    final TablesDB tablesDB = TablesDB(databases.client);
    final queries = [Query.equal('userId', usuarioId), Query.limit(5000)];
    if (lastSyncedAt != null) {
      queries.add(Query.greaterThan(r'$updatedAt', lastSyncedAt.toIso8601String()));
    }
    final catDocs = await tablesDB.listRows(
      databaseId: Core.databaseId,
      tableId: Core.tableCategoriasTransacoes,
      queries: queries,
    );
    return catDocs.rows.map((d) {
      final map = Map<String, dynamic>.from(d.data);
      map['\$id'] = d.$id;
      return CategoriaTransacaoModel.fromMap(map);
    }).toList();
  }

  @override
  Future<bool> createCategoria({
    required String name,
    String? icone,
    required String hexColor,
    required String usuarioId,
  }) async {
    final TablesDB tablesDB = TablesDB(databases.client);
    await tablesDB.createRow(
      databaseId: Core.databaseId,
      tableId: Core.tableCategoriasTransacoes,
      rowId: ID.unique(),
      data: {
        'userId': usuarioId,
        'name': name,
        'icone': icone,
        'cor': hexColor,
      },
    );
    return true;
  }

  @override
  Future<bool> updateCategoria({
    required String id,
    required String name,
    String? icone,
    required String hexColor,
  }) async {
    final TablesDB tablesDB = TablesDB(databases.client);
    await tablesDB.updateRow(
      databaseId: Core.databaseId,
      tableId: Core.tableCategoriasTransacoes,
      rowId: id,
      data: {'name': name, 'icone': icone, 'cor': hexColor},
    );
    return true;
  }

  @override
  Future<bool> deleteCategoria({required String id}) async {
    final TablesDB tablesDB = TablesDB(databases.client);
    await tablesDB.deleteRow(
      databaseId: Core.databaseId,
      tableId: Core.tableCategoriasTransacoes,
      rowId: id,
    );
    return true;
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
    final TablesDB tablesDB = TablesDB(databases.client);
    final List<TransacaoModel> loadedTrans = [];

    final List<String> selectFields = lightweight
        ? [
            'valor',
            'tipo',
            'conta.*',
            'contaDestino.*',
            'consolidada',
            'dataCompetencia',
            'categoria.*',
            'devedorContato.*',
            'credorContato.*',
          ]
        : [
            'descricao',
            'valor',
            'tipo',
            'dataCompetencia',
            'consolidada',
            'conta.*',
            'contaDestino.*',
            'categoria.*',
            'recorrencia.*',
            'devedorContato.*',
            'credorContato.*',
          ];

    final List<String> baseQueries = [
      Query.select(selectFields),
      Query.limit(5000),
    ];

    if (lastSyncedAt != null) {
      baseQueries.add(
        Query.greaterThan(r'$updatedAt', lastSyncedAt.toIso8601String()),
      );
    }

    if (targetMonth != null) {
      final firstDayOfMonth = DateTime(targetMonth.year, targetMonth.month);
      final lastDayOfMonth = DateTime(
        targetMonth.year,
        targetMonth.month + 1,
      ).subtract(const Duration(milliseconds: 1));
      baseQueries.add(
        Query.greaterThanEqual(
          'dataCompetencia',
          firstDayOfMonth.toIso8601String(),
        ),
      );
      baseQueries.add(
        Query.lessThanEqual(
          'dataCompetencia',
          lastDayOfMonth.toIso8601String(),
        ),
      );
    } else if (beforeDate != null) {
      baseQueries.add(
        Query.lessThan('dataCompetencia', beforeDate.toIso8601String()),
      );
    }

    if (contaIds.isNotEmpty) {
      for (int k = 0; k < contaIds.length; k += 100) {
        final chunkContaIds = contaIds.sublist(
          k,
          k + 100 > contaIds.length ? contaIds.length : k + 100,
        );
        final transDocs1 = await tablesDB.listRows(
          databaseId: Core.databaseId,
          tableId: Core.tableTransacoes,
          queries: [Query.equal('conta', chunkContaIds), ...baseQueries],
        );
        for (final doc in transDocs1.rows) {
          final map = Map<String, dynamic>.from(doc.data);
          map['\$id'] = doc.$id;
          loadedTrans.add(TransacaoModel.fromMap(map));
        }
      }

      for (int k = 0; k < contaIds.length; k += 100) {
        final chunkContaIds = contaIds.sublist(
          k,
          k + 100 > contaIds.length ? contaIds.length : k + 100,
        );
        final transDocs2 = await tablesDB.listRows(
          databaseId: Core.databaseId,
          tableId: Core.tableTransacoes,
          queries: [Query.equal('contaDestino', chunkContaIds), ...baseQueries],
        );
        for (final doc in transDocs2.rows) {
          final map = Map<String, dynamic>.from(doc.data);
          map['\$id'] = doc.$id;
          if (!loadedTrans.any((t) => t.id == doc.$id)) {
            loadedTrans.add(TransacaoModel.fromMap(map));
          }
        }
      }
    }
    return loadedTrans;
  }

  @override
  Future<List<TransacaoModel>> getRecurrenceSeries({
    required String recurrenceId,
  }) async {
    final TablesDB tablesDB = TablesDB(databases.client);
    final recTransDocs = await tablesDB.listRows(
      databaseId: Core.databaseId,
      tableId: Core.tableTransacoes,
      queries: [
        Query.equal('recorrencia', [recurrenceId]),
        Query.select([
          'descricao',
          'valor',
          'tipo',
          'dataCompetencia',
          'consolidada',
          'conta.*',
          'contaDestino.*',
          'categoria.*',
          'recorrencia.*',
          'devedorContato.*',
          'credorContato.*',
        ]),
        Query.limit(5000),
      ],
    );

    final List<TransacaoModel> allRecTrans = [];
    for (final doc in recTransDocs.rows) {
      final map = Map<String, dynamic>.from(doc.data);
      map['\$id'] = doc.$id;
      allRecTrans.add(TransacaoModel.fromMap(map));
    }

    final List<String> recTransIds = allRecTrans.map((t) => t.id).toList();
    if (recTransIds.isNotEmpty) {
      final List<DivisaoTransacaoModel> allRecDivs = [];
      for (int k = 0; k < recTransIds.length; k += 100) {
        final chunkIds = recTransIds.sublist(
          k,
          k + 100 > recTransIds.length ? recTransIds.length : k + 100,
        );
        final divsDocs = await tablesDB.listRows(
          databaseId: Core.databaseId,
          tableId: Core.tableDivisaoTransacoes,
          queries: [Query.equal('transacao', chunkIds), Query.limit(5000)],
        );
        allRecDivs.addAll(
          divsDocs.rows.map((d) => DivisaoTransacaoModel.fromMap(d.data)),
        );
      }

      for (int i = 0; i < allRecTrans.length; i++) {
        final t = allRecTrans[i];
        final divsForT = allRecDivs
            .where((d) => d.transacaoId == t.id)
            .toList();
        allRecTrans[i] = t.copyWith(divisoes: divsForT);
      }
    }

    return allRecTrans;
  }

  @override
  Future<List<DivisaoTransacaoModel>> getDivisoes({
    required List<String> contatoResponsavelIds,
    bool forceLocal = false,
  }) async {
    final TablesDB tablesDB = TablesDB(databases.client);
    final List<DivisaoTransacaoModel> allDivs = [];

    for (int k = 0; k < contatoResponsavelIds.length; k += 100) {
      final chunkIds = contatoResponsavelIds.sublist(
        k,
        k + 100 > contatoResponsavelIds.length
            ? contatoResponsavelIds.length
            : k + 100,
      );
      final divsDocs = await tablesDB.listRows(
        databaseId: Core.databaseId,
        tableId: Core.tableDivisaoTransacoes,
        queries: [
          Query.equal('contatoResponsavel', chunkIds),
          Query.select(['transacao', 'contatoResponsavel', 'peso']),
          Query.limit(5000),
        ],
      );
      for (final doc in divsDocs.rows) {
        final map = Map<String, dynamic>.from(doc.data);
        map['\$id'] = doc.$id;
        allDivs.add(DivisaoTransacaoModel.fromMap(map));
      }
    }
    return allDivs;
  }

  @override
  Future<String> createRecorrenciaRow({
    required String tipoRecorrencia,
    required int frequencia,
    int? totalParcelas,
    int? parcelaInicio,
    DateTime? fimRecorrencia,
  }) async {
    final TablesDB tablesDB = TablesDB(databases.client);
    final Row recRow = await tablesDB.createRow(
      databaseId: Core.databaseId,
      tableId: Core.tableTransacaoRecorrencias,
      rowId: ID.unique(),
      data: {
        'tipoRecorrencia': tipoRecorrencia,
        'frequencia': frequencia,
        'totalParcelas': totalParcelas,
        'parcelaInicio': parcelaInicio,
        'fimRecorrencia': fimRecorrencia?.toIso8601String(),
      },
    );
    return recRow.$id;
  }

  @override
  Future<void> updateAccountBalance({
    required String contaId,
    required double newSaldo,
  }) async {
    final TablesDB tablesDB = TablesDB(databases.client);
    await tablesDB.updateRow(
      databaseId: Core.databaseId,
      tableId: Core.tableContas,
      rowId: contaId,
      data: {'saldoAtual': newSaldo},
    );
  }

  @override
  Future<void> deleteRow({
    required String tableId,
    required String rowId,
  }) async {
    final TablesDB tablesDB = TablesDB(databases.client);
    await tablesDB.deleteRow(
      databaseId: Core.databaseId,
      tableId: tableId,
      rowId: rowId,
    );
  }

  @override
  Future<void> updateRow({
    required String tableId,
    required String rowId,
    required Map<String, dynamic> data,
  }) async {
    final TablesDB tablesDB = TablesDB(databases.client);
    await tablesDB.updateRow(
      databaseId: Core.databaseId,
      tableId: tableId,
      rowId: rowId,
      data: data,
    );
  }

  @override
  Future<void> executeBatchOperations(
    List<Map<String, dynamic>> operations,
  ) async {
    final TablesDB tablesDB = TablesDB(databases.client);
    final List<Map<String, dynamic>> cleanedOperations = operations.map((op) {
      final cleanedOp = Map<String, dynamic>.from(op);
      if (cleanedOp['data'] is Map<String, dynamic>) {
        final dataMap = Map<String, dynamic>.from(
          cleanedOp['data'] as Map<String, dynamic>,
        );
        dataMap.removeWhere((key, value) => value == null);
        cleanedOp['data'] = dataMap;
      }
      return cleanedOp;
    }).toList();

    try {
      for (int j = 0; j < cleanedOperations.length; j += 100) {
        final chunk = cleanedOperations.sublist(
          j,
          j + 100 > cleanedOperations.length
              ? cleanedOperations.length
              : j + 100,
        );
        final String txId = (await tablesDB.createTransaction()).$id;
        await tablesDB.createOperations(
          transactionId: txId,
          operations: chunk,
        );
        await tablesDB.updateTransaction(transactionId: txId, commit: true);
      }
    } catch (e) {
      log(
        'Appwrite transaction failed: $e. Falling back to individual operations...',
      );
      for (final op in cleanedOperations) {
        final action = op['action'] as String;
        final tableId = op['tableId'] as String;
        final rowId = op['rowId'] as String;
        final data = op['data'] as Map<String, dynamic>?;

        if (action == 'update' && data != null) {
          await tablesDB.updateRow(
            databaseId: Core.databaseId,
            tableId: tableId,
            rowId: rowId,
            data: data,
          );
        } else if (action == 'create' && data != null) {
          await tablesDB.createRow(
            databaseId: Core.databaseId,
            tableId: tableId,
            rowId: rowId,
            data: data,
          );
        } else if (action == 'delete') {
          await tablesDB.deleteRow(
            databaseId: Core.databaseId,
            tableId: tableId,
            rowId: rowId,
          );
        }
      }
    }
  }

  @override
  Stream<List<ContatoModel>> watchContatos({required String usuarioId}) {
    return const Stream.empty();
  }

  @override
  Stream<List<ContaModel>> watchContas({required String usuarioId}) {
    return const Stream.empty();
  }

  @override
  Stream<List<CategoriaTransacaoModel>> watchCategorias({
    required String usuarioId,
  }) {
    return const Stream.empty();
  }

  @override
  Stream<List<TransacaoModel>> watchTransacoes({
    required String usuarioId,
    required List<String> contaIds,
    DateTime? targetMonth,
  }) {
    return const Stream.empty();
  }
}
