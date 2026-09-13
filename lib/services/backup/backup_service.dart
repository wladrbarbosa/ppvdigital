import 'dart:developer';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:intl/intl.dart';
import 'package:ppvdigital/core.dart';
import 'package:ppvdigital/models/backup/backup_payload_model.dart';
import 'package:ppvdigital/models/local/app_database.dart';
import 'package:ppvdigital/services/backup/backup_file_saver.dart';

/// Serviço de extração e empacotamento completo de dados do Appwrite para Backup.
///
/// Executa varreduras paginadas com `Query.limit(5000)` e cursores diretamente
/// no Appwrite Database, garantindo 100% de integridade referencial com cobertura
/// temporal irrestrita (passado, presente e futuro no módulo de finanças).
class BackupService {
  BackupService({
    required this.tablesDB,
    this.databaseId = Core.databaseId,
    this.localDatabase,
    this.fileSaver = saveBackupFile,
  });

  final TablesDB tablesDB;
  final String databaseId;
  final AppDatabase? localDatabase;
  final Future<String?> Function(String content, String fileName) fileSaver;

  /// Helper genérico para paginar e recuperar todas as linhas de uma tabela no Appwrite.
  Future<List<Map<String, dynamic>>> fetchAllRows({
    required String tableId,
    List<String> queries = const [],
  }) async {
    final List<Map<String, dynamic>> allRows = [];
    String? lastId;

    while (true) {
      final currentQueries = [
        ...queries,
        Query.limit(5000),
        if (lastId != null) Query.cursorAfter(lastId),
      ];

      final RowList res = await tablesDB.listRows(
        databaseId: databaseId,
        tableId: tableId,
        queries: currentQueries,
      );

      for (final row in res.rows) {
        final map = Map<String, dynamic>.from(row.data);
        map[r'$id'] = row.$id;
        allRows.add(map);
      }

      if (res.rows.length < 5000) {
        break;
      }
      lastId = res.rows.last.$id;
    }

    return allRows;
  }

  /// Extrai diretamente do Appwrite a totalidade dos dados das 10 tabelas vinculadas ao usuário.
  ///
  /// Garante cobertura temporal irrestrita (sem teto nem piso de data em finanças),
  /// capturando transações históricas, mês corrente e lançamentos futuros programados.
  Future<BackupPayloadModel> generateBackup({
    required String userId,
    required String userEmail,
    void Function(String step, double progress)? onProgress,
  }) async {
    final Map<String, List<Map<String, dynamic>>> data = {};

    // 1. Contas
    onProgress?.call('Coletando contas...', 0.1);
    final contas = await fetchAllRows(
      tableId: Core.tableContas,
      queries: [Query.equal('userId', userId)],
    );
    data['contas'] = contas;

    // 2. Contatos
    onProgress?.call('Coletando contatos...', 0.2);
    final contatos = await fetchAllRows(
      tableId: Core.tableContatos,
      queries: [Query.equal('ownerId', userId)],
    );
    data['contatos'] = contatos;

    // 3. Categorias de Transações
    onProgress?.call('Coletando categorias financeiras...', 0.3);
    final categoriasTransacoes = await fetchAllRows(
      tableId: Core.tableCategoriasTransacoes,
      queries: [Query.equal('userId', userId)],
    );
    data['categoriasTransacoes'] = categoriasTransacoes;

    // 4. Categorias de Tarefas e Hábitos
    onProgress?.call('Coletando categorias de tarefas e hábitos...', 0.4);
    final categoriasTarefasHabitos = await fetchAllRows(
      tableId: Core.tableCategoriasTarefasHabitos,
      queries: [Query.equal('usuario', userId)],
    );
    data['categoriasTarefasHabitos'] = categoriasTarefasHabitos;

    // 5. Metas de Tarefas e Hábitos (tarefasHabitosQtds)
    onProgress?.call('Coletando metas de tarefas...', 0.5);
    final tarefasHabitosQtds = await fetchAllRows(
      tableId: Core.tableTarefasHabitosQtds,
      queries: [Query.equal('usuario', userId)],
    );
    data['tarefasHabitosQtds'] = tarefasHabitosQtds;

    // 6. Tarefas e Hábitos
    onProgress?.call('Coletando tarefas e hábitos...', 0.6);
    final tarefasEHabitos = await fetchAllRows(
      tableId: Core.tableTarefasEHabitos,
      queries: [Query.equal('usuario', userId)],
    );
    data['tarefasEHabitos'] = tarefasEHabitos;

    // 7. Histórico de Tarefas e Hábitos
    onProgress?.call('Coletando histórico de tarefas e hábitos...', 0.7);
    final historicoTarefasHabitos = await fetchAllRows(
      tableId: Core.tableHistoricoTarefasHabitos,
      queries: [Query.equal('usuario', userId)],
    );
    data['historicoTarefasHabitos'] = historicoTarefasHabitos;

    // 8. Transações (Cobertura Temporal Irrestrita: Passado, Presente e Futuro)
    onProgress?.call('Coletando transações financeiras (todas as datas)...', 0.8);
    final contaIds = contas
        .map((c) => c[r'$id'] as String?)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toList();

    final Map<String, Map<String, dynamic>> transacoesMap = {};

    if (contaIds.isNotEmpty) {
      for (var k = 0; k < contaIds.length; k += 100) {
        final chunk = contaIds.sublist(
          k,
          k + 100 > contaIds.length ? contaIds.length : k + 100,
        );

        // Transações de saída / origem (sem filtro de data)
        final txConta = await fetchAllRows(
          tableId: Core.tableTransacoes,
          queries: [Query.equal('conta', chunk)],
        );
        for (final t in txConta) {
          final id = t[r'$id'] as String? ?? '';
          if (id.isNotEmpty) transacoesMap[id] = t;
        }

        // Transações de transferência / destino (sem filtro de data)
        final txDestino = await fetchAllRows(
          tableId: Core.tableTransacoes,
          queries: [Query.equal('contaDestino', chunk)],
        );
        for (final t in txDestino) {
          final id = t[r'$id'] as String? ?? '';
          if (id.isNotEmpty) transacoesMap[id] = t;
        }
      }
    }

    final transacoes = transacoesMap.values.toList();
    data['transacoes'] = transacoes;

    // 9. Divisões de Transações (divisao_transacoes)
    onProgress?.call('Coletando divisões de transações...', 0.85);
    final transacaoIds = transacoes
        .map((t) => t[r'$id'] as String?)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toList();

    final List<Map<String, dynamic>> divisaoTransacoes = [];
    if (transacaoIds.isNotEmpty) {
      for (var k = 0; k < transacaoIds.length; k += 100) {
        final chunk = transacaoIds.sublist(
          k,
          k + 100 > transacaoIds.length ? transacaoIds.length : k + 100,
        );
        final divs = await fetchAllRows(
          tableId: Core.tableDivisaoTransacoes,
          queries: [Query.equal('transacao', chunk)],
        );
        divisaoTransacoes.addAll(divs);
      }
    }
    data['divisaoTransacoes'] = divisaoTransacoes;

    // 10. Recorrências de Transações (transacao_recorrencia)
    onProgress?.call('Coletando regras de recorrência...', 0.9);
    final recorrenciaIds = transacoes
        .map((t) {
          final rec = t['recorrencia'];
          if (rec is String && rec.isNotEmpty) return rec;
          if (rec is Map && rec[r'$id'] is String) return rec[r'$id'] as String;
          return null;
        })
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    final List<Map<String, dynamic>> transacaoRecorrencias = [];
    if (recorrenciaIds.isNotEmpty) {
      for (var k = 0; k < recorrenciaIds.length; k += 100) {
        final chunk = recorrenciaIds.sublist(
          k,
          k + 100 > recorrenciaIds.length ? recorrenciaIds.length : k + 100,
        );
        final recs = await fetchAllRows(
          tableId: Core.tableTransacaoRecorrencias,
          queries: [Query.equal(r'$id', chunk)],
        );
        transacaoRecorrencias.addAll(recs);
      }
    }
    data['transacaoRecorrencias'] = transacaoRecorrencias;

    onProgress?.call('Gerando assinatura de integridade...', 0.95);
    final payload = BackupPayloadModel(
      exportedAt: DateTime.now(),
      userId: userId,
      userEmail: userEmail,
      data: data,
    );

    onProgress?.call('Backup gerado com sucesso!', 1.0);
    return payload;
  }

  /// Dispara o download do arquivo de backup no formato JSON (.json)
  Future<String?> downloadBackup(
    BackupPayloadModel payload, {
    String? customFileName,
  }) async {
    try {
      final now = payload.exportedAt;
      final dateFormatted = DateFormat('yyyy-MM-dd_HHmmss').format(now);
      final fileName =
          customFileName ?? 'backup_ppvdigital_$dateFormatted.json';
      final jsonContent = payload.toJson(pretty: true);
      return await fileSaver(jsonContent, fileName);
    } catch (e) {
      log('Erro ao baixar arquivo de backup: $e');
      rethrow;
    }
  }
}
