import 'dart:developer';

import 'package:appwrite/appwrite.dart';
import 'package:ppvdigital/core.dart';
import 'package:ppvdigital/models/backup/backup_payload_model.dart';
import 'package:ppvdigital/models/local/app_database.dart';

/// Serviço responsável pela restauração segura dos dados de backup no Appwrite.
///
/// Implementa integridade referencial estrita executando a reconstituição em 4 fases
/// sequenciais de dependência e controle de lotes paralelos para máxima performance.
class RestoreService {
  RestoreService({
    required this.tablesDB,
    this.databaseId = Core.databaseId,
    this.localDatabase,
    this.onResetControllers = Core.resetAllControllers,
  });

  final TablesDB tablesDB;
  final String databaseId;
  final AppDatabase? localDatabase;
  final void Function()? onResetControllers;

  /// Valida o JSON de backup: integridade de formato, metadados e assinatura SHA-256.
  Future<bool> validateBackup(String jsonContent) async {
    try {
      final payload = BackupPayloadModel.fromJson(jsonContent);
      return payload.isValidChecksum;
    } catch (e) {
      log('Falha na validação do backup: $e');
      return false;
    }
  }

  /// Remove atributos internos do Appwrite antes de enviar para criação/atualização.
  static Map<String, dynamic> sanitizeData(Map<String, dynamic> raw) {
    final clean = Map<String, dynamic>.from(raw);
    clean.remove(r'$id');
    clean.remove(r'$sequence');
    clean.remove(r'$tableId');
    clean.remove(r'$databaseId');
    clean.remove(r'$createdAt');
    clean.remove(r'$updatedAt');
    clean.remove(r'$permissions');
    return clean;
  }

  /// Insere ou atualiza um registro individual respeitando o modo selecionado.
  Future<void> upsertRow({
    required String tableId,
    required String rowId,
    required Map<String, dynamic> data,
    required bool cleanReplace,
  }) async {
    final cleanData = sanitizeData(data);

    if (cleanReplace) {
      // No modo de substituição, os registros anteriores já foram limpos
      await tablesDB.createRow(
        databaseId: databaseId,
        tableId: tableId,
        rowId: rowId,
        data: cleanData,
      );
    } else {
      // No modo mesclagem / upsert, tenta atualizar; se não existir (404), cria
      try {
        await tablesDB.updateRow(
          databaseId: databaseId,
          tableId: tableId,
          rowId: rowId,
          data: cleanData,
        );
      } catch (_) {
        await tablesDB.createRow(
          databaseId: databaseId,
          tableId: tableId,
          rowId: rowId,
          data: cleanData,
        );
      }
    }
  }

  /// Insere uma lista de itens em lotes controlados para evitar saturação de conexões.
  Future<void> insertBatch({
    required String tableId,
    required List<Map<String, dynamic>> items,
    required bool cleanReplace,
    int batchSize = 10,
  }) async {
    for (var i = 0; i < items.length; i += batchSize) {
      final end = (i + batchSize > items.length) ? items.length : i + batchSize;
      final chunk = items.sublist(i, end);
      await Future.wait(
        chunk.map((item) {
          final rowId = item[r'$id'] as String? ?? ID.unique();
          return upsertRow(
            tableId: tableId,
            rowId: rowId,
            data: item,
            cleanReplace: cleanReplace,
          );
        }),
      );
    }
  }

  /// Remove registros existentes no Appwrite em lotes controlados.
  Future<void> deleteExistingRows({
    required String tableId,
    List<String> queries = const [],
  }) async {
    while (true) {
      final res = await tablesDB.listRows(
        databaseId: databaseId,
        tableId: tableId,
        queries: [...queries, Query.limit(100)],
      );
      if (res.rows.isEmpty) break;

      await Future.wait(
        res.rows.map(
          (r) => tablesDB.deleteRow(
            databaseId: databaseId,
            tableId: tableId,
            rowId: r.$id,
          ),
        ),
      );

      if (res.rows.length < 100) break;
    }
  }

  /// Limpa os dados anteriores do usuário no Appwrite em ordem inversa de dependência.
  Future<void> cleanExistingUserData(String userId) async {
    // 1. Histórico de Tarefas
    await deleteExistingRows(
      tableId: Core.tableHistoricoTarefasHabitos,
      queries: [Query.equal('usuario', userId)],
    );

    // 2. Tarefas e Hábitos
    await deleteExistingRows(
      tableId: Core.tableTarefasEHabitos,
      queries: [Query.equal('usuario', userId)],
    );

    // 3. Metas de Tarefas (tarefasHabitosQtds)
    await deleteExistingRows(
      tableId: Core.tableTarefasHabitosQtds,
      queries: [Query.equal('usuario', userId)],
    );

    // 4. Categorias de Tarefas
    await deleteExistingRows(
      tableId: Core.tableCategoriasTarefasHabitos,
      queries: [Query.equal('usuario', userId)],
    );

    // 5. Transações e Divisões: primeiro localiza as contas do usuário
    final userAccountsRes = await tablesDB.listRows(
      databaseId: databaseId,
      tableId: Core.tableContas,
      queries: [Query.equal('userId', userId), Query.limit(5000)],
    );
    final contaIds = userAccountsRes.rows.map((r) => r.$id).toList();

    if (contaIds.isNotEmpty) {
      for (var k = 0; k < contaIds.length; k += 100) {
        final chunk = contaIds.sublist(
          k,
          k + 100 > contaIds.length ? contaIds.length : k + 100,
        );

        final transRes = await tablesDB.listRows(
          databaseId: databaseId,
          tableId: Core.tableTransacoes,
          queries: [Query.equal('conta', chunk), Query.limit(5000)],
        );

        final transIds = transRes.rows.map((r) => r.$id).toList();
        if (transIds.isNotEmpty) {
          for (var j = 0; j < transIds.length; j += 100) {
            final txChunk = transIds.sublist(
              j,
              j + 100 > transIds.length ? transIds.length : j + 100,
            );
            await deleteExistingRows(
              tableId: Core.tableDivisaoTransacoes,
              queries: [Query.equal('transacao', txChunk)],
            );
          }
        }

        // Deleta transações associadas
        await deleteExistingRows(
          tableId: Core.tableTransacoes,
          queries: [Query.equal('conta', chunk)],
        );
        await deleteExistingRows(
          tableId: Core.tableTransacoes,
          queries: [Query.equal('contaDestino', chunk)],
        );
      }
    }

    // 6. Categorias Financeiras
    await deleteExistingRows(
      tableId: Core.tableCategoriasTransacoes,
      queries: [Query.equal('userId', userId)],
    );

    // 7. Contatos
    await deleteExistingRows(
      tableId: Core.tableContatos,
      queries: [Query.equal('ownerId', userId)],
    );

    // 8. Contas
    await deleteExistingRows(
      tableId: Core.tableContas,
      queries: [Query.equal('userId', userId)],
    );
  }

  /// Executa a restauração completa dos dados em 4 fases estritas de integridade.
  Future<void> restoreBackup(
    BackupPayloadModel payload, {
    required bool cleanReplace,
    void Function(String step, double progress)? onProgress,
  }) async {
    if (!payload.isValidChecksum) {
      throw const FormatException(
        'Arquivo de backup corrompido ou com assinatura de integridade inválida.',
      );
    }

    final userId = payload.userId;

    if (cleanReplace) {
      onProgress?.call('Limpando dados anteriores do usuário...', 0.05);
      await cleanExistingUserData(userId);
    }

    // ==========================================
    // FASE 1: Entidades Independentes
    // ==========================================
    onProgress?.call('Restaurando contas bancárias...', 0.15);
    await insertBatch(
      tableId: Core.tableContas,
      items: payload.contas,
      cleanReplace: cleanReplace,
    );

    onProgress?.call('Restaurando contatos...', 0.25);
    await insertBatch(
      tableId: Core.tableContatos,
      items: payload.contatos,
      cleanReplace: cleanReplace,
    );

    onProgress?.call('Restaurando categorias de transações...', 0.35);
    await insertBatch(
      tableId: Core.tableCategoriasTransacoes,
      items: payload.categoriasTransacoes,
      cleanReplace: cleanReplace,
    );

    onProgress?.call('Restaurando categorias de tarefas e hábitos...', 0.45);
    await insertBatch(
      tableId: Core.tableCategoriasTarefasHabitos,
      items: payload.categoriasTarefasHabitos,
      cleanReplace: cleanReplace,
    );

    // ==========================================
    // FASE 2: Dependências Intermediárias
    // ==========================================
    onProgress?.call('Restaurando metas de tarefas e hábitos...', 0.55);
    await insertBatch(
      tableId: Core.tableTarefasHabitosQtds,
      items: payload.tarefasHabitosQtds,
      cleanReplace: cleanReplace,
    );

    onProgress?.call('Restaurando regras de recorrência...', 0.65);
    await insertBatch(
      tableId: Core.tableTransacaoRecorrencias,
      items: payload.transacaoRecorrencias,
      cleanReplace: cleanReplace,
    );

    // ==========================================
    // FASE 3: Entidades Centrais (Tarefas e Transações - Passadas e Futuras)
    // ==========================================
    onProgress?.call('Restaurando tarefas e hábitos...', 0.75);
    await insertBatch(
      tableId: Core.tableTarefasEHabitos,
      items: payload.tarefasEHabitos,
      cleanReplace: cleanReplace,
    );

    onProgress?.call('Restaurando transações financeiras (passado e futuro)...', 0.85);
    await insertBatch(
      tableId: Core.tableTransacoes,
      items: payload.transacoes,
      cleanReplace: cleanReplace,
    );

    // ==========================================
    // FASE 4: Sub-itens e Históricos
    // ==========================================
    onProgress?.call('Restaurando divisões de transações...', 0.90);
    await insertBatch(
      tableId: Core.tableDivisaoTransacoes,
      items: payload.divisaoTransacoes,
      cleanReplace: cleanReplace,
    );

    onProgress?.call('Restaurando histórico de tarefas e hábitos...', 0.95);
    await insertBatch(
      tableId: Core.tableHistoricoTarefasHabitos,
      items: payload.historicoTarefasHabitos,
      cleanReplace: cleanReplace,
    );

    // Limpa o cache Drift local e reseta os controllers para recarregar do zero
    onProgress?.call('Atualizando cache local e interface...', 0.98);
    if (localDatabase != null) {
      await localDatabase!.clearAllUserData();
    }
    onResetControllers?.call();

    onProgress?.call('Restauração concluída com sucesso!', 1.0);
  }
}
