import 'package:flutter_test/flutter_test.dart';
import 'package:ppvdigital/app/capacitacao/financas/financas_controller.dart';
import 'package:ppvdigital/models/categoria_transacao_model.dart';
import 'package:ppvdigital/models/conta_model.dart';
import 'package:ppvdigital/models/contato_model.dart';
import 'package:ppvdigital/models/divisao_transacao_model.dart';
import 'package:ppvdigital/models/transacao_model.dart';
import 'package:ppvdigital/models/transacao_recorrencia_model.dart';
import 'package:ppvdigital/repositories/financas_repository.dart';

class MockFinancasRepoForController implements FinancasRepository {
  final Map<String, String> settings = {};
  final List<ContaModel> contas = [];
  final List<CategoriaTransacaoModel> categorias = [];
  final List<ContatoModel> contatos = [];
  final List<TransacaoModel> transacoes = [];
  final List<Map<String, dynamic>> executedBatches = [];

  @override
  Future<String?> getSetting(String key) async => settings[key];

  @override
  Future<void> saveSetting(String key, String value) async {
    settings[key] = value;
  }

  @override
  Future<bool> createConta({
    required String name,
    required double saldoInicial,
    required String usuarioId,
  }) async {
    contas.add(ContaModel(id: 'c_${contas.length + 1}', name: name, userId: usuarioId, saldoAtual: saldoInicial));
    return true;
  }

  @override
  Future<bool> updateConta({
    required String id,
    required String name,
    required double saldoAtual,
  }) async {
    final idx = contas.indexWhere((c) => c.id == id);
    if (idx != -1) {
      contas[idx] = ContaModel(id: id, name: name, userId: contas[idx].userId, saldoAtual: saldoAtual);
      return true;
    }
    return false;
  }

  @override
  Future<bool> deleteConta({required String id}) async {
    contas.removeWhere((c) => c.id == id);
    return true;
  }

  @override
  Future<bool> createCategoria({
    required String name,
    String? icone,
    required String hexColor,
    required String usuarioId,
  }) async {
    categorias.add(CategoriaTransacaoModel(id: 'cat_${categorias.length + 1}', name: name, icone: icone, userId: usuarioId));
    return true;
  }

  @override
  Future<bool> updateCategoria({
    required String id,
    required String name,
    String? icone,
    required String hexColor,
  }) async {
    final idx = categorias.indexWhere((c) => c.id == id);
    if (idx != -1) {
      categorias[idx] = CategoriaTransacaoModel(id: id, name: name, icone: icone, userId: categorias[idx].userId);
      return true;
    }
    return false;
  }

  @override
  Future<bool> deleteCategoria({required String id}) async {
    categorias.removeWhere((c) => c.id == id);
    return true;
  }

  @override
  Future<ContatoModel> createContato({
    required String ownerId,
    required String nome,
    String? email,
    String? userId,
  }) async {
    final c = ContatoModel(id: 'ct_${contatos.length + 1}', ownerId: ownerId, nome: nome, email: email, userId: userId);
    contatos.add(c);
    return c;
  }

  int updateAccountBalanceCallCount = 0;

  @override
  Future<void> updateAccountBalance({required String contaId, required double newSaldo}) async {
    updateAccountBalanceCallCount++;
    final idx = contas.indexWhere((c) => c.id == contaId);
    if (idx != -1) {
      contas[idx] = ContaModel(id: contaId, name: contas[idx].name, userId: contas[idx].userId, saldoAtual: newSaldo);
    }
  }

  @override
  Future<void> executeBatchOperations(List<Map<String, dynamic>> operations) async {
    executedBatches.addAll(operations);
  }

  @override
  Future<List<ContaModel>> getContas({required String usuarioId, bool forceLocal = false, DateTime? lastSyncedAt}) async => contas;

  @override
  Future<List<CategoriaTransacaoModel>> getCategorias({required String usuarioId, bool forceLocal = false, DateTime? lastSyncedAt}) async => categorias;

  List<TransacaoModel> recurrenceSeries = [];
  final List<Map<String, dynamic>> updatedRows = [];
  final List<Map<String, dynamic>> createdRecorrencias = [];
  String createdRecId = 'new_rec_id';

  @override
  Future<List<ContatoModel>> getContatos({required String usuarioId, bool forceLocal = false, DateTime? lastSyncedAt}) async => contatos;

  @override
  Future<List<TransacaoModel>> getTransacoes({required String usuarioId, required List<String> contaIds, DateTime? targetMonth, DateTime? beforeDate, bool forceLocal = false, DateTime? lastSyncedAt}) async => transacoes;

  @override
  Future<Set<String>> getActiveTransacaoIdsInMonth({required String usuarioId, required List<String> contaIds, DateTime? targetMonth, DateTime? beforeDate}) async => transacoes.map((t) => t.id).toSet();

  @override
  Future<List<TransacaoModel>> getRecurrenceSeries({required String recurrenceId}) async {
    if (recurrenceSeries.isNotEmpty) return recurrenceSeries;
    return transacoes.where((t) => t.recorrencia?.id == recurrenceId).toList();
  }

  @override
  Future<List<DivisaoTransacaoModel>> getDivisoes({required List<String> contatoResponsavelIds, bool forceLocal = false, DateTime? lastSyncedAt}) async => [];

  @override
  Future<String> createRecorrenciaRow({
    required String tipoRecorrencia,
    required int frequencia,
    int? totalParcelas,
    int? parcelaInicio,
    DateTime? fimRecorrencia,
  }) async {
    createdRecorrencias.add({
      'tipoRecorrencia': tipoRecorrencia,
      'frequencia': frequencia,
      'totalParcelas': totalParcelas,
      'parcelaInicio': parcelaInicio,
      'fimRecorrencia': fimRecorrencia,
    });
    return createdRecId;
  }

  @override
  Future<void> deleteRow({required String tableId, required String rowId}) async {}

  @override
  Future<void> updateRow({
    required String tableId,
    required String rowId,
    required Map<String, dynamic> data,
  }) async {
    updatedRows.add({'tableId': tableId, 'rowId': rowId, 'data': data});
  }

  @override
  Stream<List<ContaModel>> watchContas({required String usuarioId}) => Stream.value(contas);

  @override
  Stream<List<CategoriaTransacaoModel>> watchCategorias({required String usuarioId}) => Stream.value(categorias);

  @override
  Stream<List<ContatoModel>> watchContatos({required String usuarioId}) => Stream.value(contatos);

  @override
  Stream<List<TransacaoModel>> watchTransacoes({required String usuarioId, required List<String> contaIds, DateTime? targetMonth}) => Stream.value(transacoes);
}

void main() {
  group('FinancasController Unit Tests', () {
    late MockFinancasRepoForController mockRepo;
    late FinancasController controller;

    setUp(() {
      mockRepo = MockFinancasRepoForController();
      controller = FinancasController(mockRepo);
    });

    test('save and load financas filters properly parses JSON', () async {
      await controller.saveFinancasFilters({'tabIndex': 2, 'selectedContas': ['c1', 'c2']});

      expect(controller.cachedFilters?['tabIndex'], 2);
      expect(controller.cachedFilters?['selectedContas'], ['c1', 'c2']);

      final loaded = await controller.loadFinancasFilters();
      expect(loaded?['tabIndex'], 2);
    });

    test('updateAccountBalance delegates to repository with calculated new balance', () async {
      final conta = ContaModel(id: 'c1', name: 'Banco', userId: 'u1', saldoAtual: 100.0);
      mockRepo.contas.add(conta);
      controller.contasList.add(conta);

      await controller.updateAccountBalance('c1', 50.0);
      expect(mockRepo.contas.first.saldoAtual, 150.0);
      expect(controller.contasList.first.saldoAtual, 150.0);

      await controller.updateAccountBalance('c1', -30.0);
      expect(mockRepo.contas.first.saldoAtual, 120.0);
      expect(controller.contasList.first.saldoAtual, 120.0);
    });

    test('reset clears internal controller state and synced cache', () {
      controller.reset();
      expect(controller.isSyncing, isFalse);
      expect(controller.contasList.isEmpty, isTrue);
      expect(controller.transacoesList.isEmpty, isTrue);
    });

    group('Recorrencia: expansão e redução de parcelas', () {
      test('Cenário do usuário: expande totalParcelas de 3 para 4 a partir da última parcela (T3) com current_and_future', () async {
        final rec = TransacaoRecorrenciaModel(
          id: 'rec_orig',
          tipoRecorrencia: 'mês',
          frequencia: 1,
          totalParcelas: 3,
          parcelaInicio: 1,
        );

        // T1 e T2 foram alteradas separadamente (recorrência desvinculada).
        // Apenas T3 permaneceu na série de recorrência.
        final t3 = TransacaoModel(
          id: 't3',
          descricao: 'Curso Flutter (Parcela 3/3)',
          valor: 150.0,
          tipo: 'despesa',
          dataCompetencia: DateTime(2026, 9, 10),
          consolidada: false,
          recorrencia: rec,
          divisoes: [],
        );

        controller.transacoesList.add(t3);
        mockRepo.recurrenceSeries = [t3];

        // Usuário altera a última parcela de 3/3 para inicial 3 e final 4
        final success = await controller.updateTransacao(
          id: 't3',
          descricao: 'Curso Flutter',
          valor: 150.0,
          tipo: 'despesa',
          dataCompetencia: DateTime(2026, 9, 10),
          contaId: 'c1',
          contaDestinoId: null,
          consolidada: false,
          categoriaId: 'cat1',
          divisao: [],
          optionRecorrencia: 'current_and_future',
          parcelaInicio: 3,
          totalParcelas: 4,
          tipoRecorrencia: 'mês',
          frequencia: 1,
        );

        expect(success, isTrue);

        // Verifica que o lote executado contém:
        // 1. Update de t3 para Parcela 3/4 com o novo ID de recorrência
        final updateT3 = mockRepo.executedBatches.firstWhere(
          (op) => op['action'] == 'update' && op['rowId'] == 't3',
        );
        final updateT3Data = updateT3['data'] as Map<String, dynamic>;
        expect(updateT3Data['descricao'], 'Curso Flutter (Parcela 3/4)');
        expect(updateT3Data['recorrencia'], 'new_rec_id');

        // 2. Create da 4ª parcela no mês seguinte (outubro) com Parcela 4/4
        final createT4 = mockRepo.executedBatches.firstWhere(
          (op) => op['action'] == 'create' && (op['data'] as Map<String, dynamic>?)?['descricao'] == 'Curso Flutter (Parcela 4/4)',
        );
        final createT4Data = createT4['data'] as Map<String, dynamic>;
        expect(createT4Data['dataCompetencia'], DateTime(2026, 10, 10).toIso8601String());
        expect(createT4Data['recorrencia'], 'new_rec_id');
        expect(createT4Data['valor'], 150.0);
        expect(createT4Data['consolidada'], isFalse);
      });

      test('Expande parcelas do meio com current_and_future (T2 alterada de 2/3 para 5 parcelas no total)', () async {
        final rec = TransacaoRecorrenciaModel(
          id: 'rec_1',
          tipoRecorrencia: 'mês',
          frequencia: 1,
          totalParcelas: 3,
          parcelaInicio: 1,
        );

        final t1 = TransacaoModel(
          id: 't1',
          descricao: 'Aluguel (Parcela 1/3)',
          valor: 800.0,
          tipo: 'despesa',
          dataCompetencia: DateTime(2026, 7),
          consolidada: false,
          recorrencia: rec,
          divisoes: [],
        );
        final t2 = TransacaoModel(
          id: 't2',
          descricao: 'Aluguel (Parcela 2/3)',
          valor: 800.0,
          tipo: 'despesa',
          dataCompetencia: DateTime(2026, 8),
          consolidada: false,
          recorrencia: rec,
          divisoes: [],
        );
        final t3 = TransacaoModel(
          id: 't3',
          descricao: 'Aluguel (Parcela 3/3)',
          valor: 800.0,
          tipo: 'despesa',
          dataCompetencia: DateTime(2026, 9),
          consolidada: false,
          recorrencia: rec,
          divisoes: [],
        );

        controller.transacoesList.addAll([t1, t2, t3]);
        mockRepo.recurrenceSeries = [t1, t2, t3];

        final success = await controller.updateTransacao(
          id: 't2',
          descricao: 'Aluguel',
          valor: 800.0,
          tipo: 'despesa',
          dataCompetencia: DateTime(2026, 8),
          contaId: 'c1',
          contaDestinoId: null,
          consolidada: false,
          categoriaId: 'cat1',
          divisao: [],
          optionRecorrencia: 'current_and_future',
          parcelaInicio: 2,
          totalParcelas: 5,
        );

        expect(success, isTrue);

        // T2 atualizada para 2/5
        final updateT2 = mockRepo.executedBatches.firstWhere(
          (op) => op['action'] == 'update' && op['rowId'] == 't2',
        );
        final updateT2Data = updateT2['data'] as Map<String, dynamic>;
        expect(updateT2Data['descricao'], 'Aluguel (Parcela 2/5)');

        // T3 existente atualizada para 3/5
        final updateT3 = mockRepo.executedBatches.firstWhere(
          (op) => op['action'] == 'update' && op['rowId'] == 't3',
        );
        final updateT3Data = updateT3['data'] as Map<String, dynamic>;
        expect(updateT3Data['descricao'], 'Aluguel (Parcela 3/5)');

        // Parcelas 4 e 5 criadas
        final creates = mockRepo.executedBatches.where((op) => op['action'] == 'create').toList();
        expect(creates.any((op) => (op['data'] as Map<String, dynamic>)['descricao'] == 'Aluguel (Parcela 4/5)'), isTrue);
        expect(creates.any((op) => (op['data'] as Map<String, dynamic>)['descricao'] == 'Aluguel (Parcela 5/5)'), isTrue);
      });

      test('Reduz totalParcelas com current_and_future (exclui parcelas futuras excedentes)', () async {
        final rec = TransacaoRecorrenciaModel(
          id: 'rec_long',
          tipoRecorrencia: 'mês',
          frequencia: 1,
          totalParcelas: 4,
          parcelaInicio: 1,
        );

        final t1 = TransacaoModel(id: 't1', descricao: 'P (Parcela 1/4)', valor: 50, tipo: 'despesa', dataCompetencia: DateTime(2026), consolidada: false, recorrencia: rec, divisoes: []);
        final t2 = TransacaoModel(id: 't2', descricao: 'P (Parcela 2/4)', valor: 50, tipo: 'despesa', dataCompetencia: DateTime(2026, 2), consolidada: false, recorrencia: rec, divisoes: []);
        final t3 = TransacaoModel(id: 't3', descricao: 'P (Parcela 3/4)', valor: 50, tipo: 'despesa', dataCompetencia: DateTime(2026, 3), consolidada: false, recorrencia: rec, divisoes: []);
        final t4 = TransacaoModel(id: 't4', descricao: 'P (Parcela 4/4)', valor: 50, tipo: 'despesa', dataCompetencia: DateTime(2026, 4), consolidada: false, recorrencia: rec, divisoes: []);

        controller.transacoesList.addAll([t1, t2, t3, t4]);
        mockRepo.recurrenceSeries = [t1, t2, t3, t4];

        // Edita T2 com current_and_future e reduz totalParcelas para 2
        final success = await controller.updateTransacao(
          id: 't2',
          descricao: 'P',
          valor: 50,
          tipo: 'despesa',
          dataCompetencia: DateTime(2026, 2),
          contaId: null,
          contaDestinoId: null,
          consolidada: false,
          categoriaId: null,
          divisao: [],
          optionRecorrencia: 'current_and_future',
          parcelaInicio: 2,
          totalParcelas: 2,
        );

        expect(success, isTrue);

        final updateT2 = mockRepo.executedBatches.firstWhere(
          (op) => op['action'] == 'update' && op['rowId'] == 't2',
        );
        final updateT2Data = updateT2['data'] as Map<String, dynamic>;
        expect(updateT2Data['descricao'], 'P (Parcela 2/2)');

        // T3 e T4 devem ser excluídas
        final deletes = mockRepo.executedBatches.where((op) => op['action'] == 'delete').toList();
        expect(deletes.any((op) => op['rowId'] == 't3'), isTrue);
        expect(deletes.any((op) => op['rowId'] == 't4'), isTrue);
      });

      test('Expande série inteira com a opção all (cria parcelas adicionais e atualiza existentes)', () async {
        final rec = TransacaoRecorrenciaModel(
          id: 'rec_all',
          tipoRecorrencia: 'mês',
          frequencia: 1,
          totalParcelas: 3,
          parcelaInicio: 1,
        );

        final t1 = TransacaoModel(id: 't1', descricao: 'Internet (Parcela 1/3)', valor: 100, tipo: 'despesa', dataCompetencia: DateTime(2026, 1, 5), consolidada: false, recorrencia: rec, divisoes: []);
        final t2 = TransacaoModel(id: 't2', descricao: 'Internet (Parcela 2/3)', valor: 100, tipo: 'despesa', dataCompetencia: DateTime(2026, 2, 5), consolidada: false, recorrencia: rec, divisoes: []);
        final t3 = TransacaoModel(id: 't3', descricao: 'Internet (Parcela 3/3)', valor: 100, tipo: 'despesa', dataCompetencia: DateTime(2026, 3, 5), consolidada: false, recorrencia: rec, divisoes: []);

        controller.transacoesList.addAll([t1, t2, t3]);
        mockRepo.recurrenceSeries = [t1, t2, t3];

        // Edita T1 com opção 'all' para 4 parcelas
        final success = await controller.updateTransacao(
          id: 't1',
          descricao: 'Internet Fibra',
          valor: 110,
          tipo: 'despesa',
          dataCompetencia: DateTime(2026, 1, 5),
          contaId: null,
          contaDestinoId: null,
          consolidada: false,
          categoriaId: null,
          divisao: [],
          optionRecorrencia: 'all',
          parcelaInicio: 1,
          totalParcelas: 4,
        );

        expect(success, isTrue);

        // Recorrência atualizada no banco
        expect(mockRepo.updatedRows.any((r) => r['rowId'] == 'rec_all' && (r['data'] as Map<String, dynamic>)['totalParcelas'] == 4), isTrue);

        // T1, T2 e T3 atualizadas para /4
        final updateT1 = mockRepo.executedBatches.firstWhere((op) => op['action'] == 'update' && op['rowId'] == 't1');
        final updateT1Data = updateT1['data'] as Map<String, dynamic>;
        expect(updateT1Data['descricao'], 'Internet Fibra (Parcela 1/4)');

        final updateT2 = mockRepo.executedBatches.firstWhere((op) => op['action'] == 'update' && op['rowId'] == 't2');
        final updateT2Data = updateT2['data'] as Map<String, dynamic>;
        expect(updateT2Data['descricao'], 'Internet Fibra (Parcela 2/4)');

        final updateT3 = mockRepo.executedBatches.firstWhere((op) => op['action'] == 'update' && op['rowId'] == 't3');
        final updateT3Data = updateT3['data'] as Map<String, dynamic>;
        expect(updateT3Data['descricao'], 'Internet Fibra (Parcela 3/4)');

        // Parcela 4 criada
        final createT4 = mockRepo.executedBatches.firstWhere(
          (op) => op['action'] == 'create' && (op['data'] as Map<String, dynamic>?)?['descricao'] == 'Internet Fibra (Parcela 4/4)',
        );
        final createT4Data = createT4['data'] as Map<String, dynamic>;
        expect(createT4Data['dataCompetencia'], DateTime(2026, 4, 5).toIso8601String());
        expect(createT4Data['valor'], 110);
      });

      test('Reduz série inteira com a opção all (exclui parcelas excedentes do final)', () async {
        final rec = TransacaoRecorrenciaModel(
          id: 'rec_all_red',
          tipoRecorrencia: 'mês',
          frequencia: 1,
          totalParcelas: 3,
          parcelaInicio: 1,
        );

        final t1 = TransacaoModel(id: 't1', descricao: 'Gym (Parcela 1/3)', valor: 80, tipo: 'despesa', dataCompetencia: DateTime(2026, 1, 10), consolidada: false, recorrencia: rec, divisoes: []);
        final t2 = TransacaoModel(id: 't2', descricao: 'Gym (Parcela 2/3)', valor: 80, tipo: 'despesa', dataCompetencia: DateTime(2026, 2, 10), consolidada: false, recorrencia: rec, divisoes: []);
        final t3 = TransacaoModel(id: 't3', descricao: 'Gym (Parcela 3/3)', valor: 80, tipo: 'despesa', dataCompetencia: DateTime(2026, 3, 10), consolidada: false, recorrencia: rec, divisoes: []);

        controller.transacoesList.addAll([t1, t2, t3]);
        mockRepo.recurrenceSeries = [t1, t2, t3];

        final success = await controller.updateTransacao(
          id: 't1',
          descricao: 'Gym',
          valor: 80,
          tipo: 'despesa',
          dataCompetencia: DateTime(2026, 1, 10),
          contaId: null,
          contaDestinoId: null,
          consolidada: false,
          categoriaId: null,
          divisao: [],
          optionRecorrencia: 'all',
          parcelaInicio: 1,
          totalParcelas: 2,
        );

        expect(success, isTrue);

        final updateT1 = mockRepo.executedBatches.firstWhere((op) => op['action'] == 'update' && op['rowId'] == 't1');
        final updateT1Data = updateT1['data'] as Map<String, dynamic>;
        expect(updateT1Data['descricao'], 'Gym (Parcela 1/2)');

        final updateT2 = mockRepo.executedBatches.firstWhere((op) => op['action'] == 'update' && op['rowId'] == 't2');
        final updateT2Data = updateT2['data'] as Map<String, dynamic>;
        expect(updateT2Data['descricao'], 'Gym (Parcela 2/2)');

        // T3 deve ser excluída
        final deleteT3 = mockRepo.executedBatches.firstWhere(
          (op) => op['action'] == 'delete' && op['rowId'] == 't3',
        );
        expect(deleteT3, isNotNull);
      });

      test('Excluir com current_and_future no meio de recorrência infinita encerra a regra de recorrência com totalParcelas e fimRecorrencia', () async {
        final rec = TransacaoRecorrenciaModel(
          id: 'rec_inf_del',
          tipoRecorrencia: 'mês',
          frequencia: 1,
        );

        final t1 = TransacaoModel(id: 't1', descricao: 'Netflix', valor: 55, tipo: 'despesa', dataCompetencia: DateTime(2026, 1, 10), consolidada: false, recorrencia: rec, divisoes: []);
        final t2 = TransacaoModel(id: 't2', descricao: 'Netflix', valor: 55, tipo: 'despesa', dataCompetencia: DateTime(2026, 2, 10), consolidada: false, recorrencia: rec, divisoes: []);
        final t3 = TransacaoModel(id: 't3', descricao: 'Netflix', valor: 55, tipo: 'despesa', dataCompetencia: DateTime(2026, 3, 10), consolidada: false, recorrencia: rec, divisoes: []);
        final t4 = TransacaoModel(id: 't4', descricao: 'Netflix', valor: 55, tipo: 'despesa', dataCompetencia: DateTime(2026, 4, 10), consolidada: false, recorrencia: rec, divisoes: []);

        controller.transacoesList.addAll([t1, t2, t3, t4]);
        mockRepo.recurrenceSeries = [t1, t2, t3, t4];

        // Usuário exclui de t3 em diante com 'current_and_future' (t1 e t2 permanecem)
        final success = await controller.deleteTransaction(
          transacao: t3,
          deleteOption: 'current_and_future',
        );

        expect(success, isTrue);

        // t3 e t4 deletadas
        expect(mockRepo.executedBatches.any((op) => op['action'] == 'delete' && op['rowId'] == 't3'), isTrue);
        expect(mockRepo.executedBatches.any((op) => op['action'] == 'delete' && op['rowId'] == 't4'), isTrue);
        expect(mockRepo.executedBatches.any((op) => op['action'] == 'delete' && op['rowId'] == 't1'), isFalse);
        expect(mockRepo.executedBatches.any((op) => op['action'] == 'delete' && op['rowId'] == 't2'), isFalse);

        // A recorrência original DEVE ser atualizada para finita (totalParcelas: 2, fimRecorrencia: 2026-02-10)
        final updateRec = mockRepo.executedBatches.firstWhere(
          (op) => op['action'] == 'update' && op['rowId'] == 'rec_inf_del',
        );
        final updateRecData = updateRec['data'] as Map<String, dynamic>;
        expect(updateRecData['totalParcelas'], 2);
        expect(updateRecData['fimRecorrencia'], DateTime(2026, 2, 10).toIso8601String());
      });

      test('Excluir com current_and_future a partir da 1ª parcela deleta a regra de recorrência órfã', () async {
        final rec = TransacaoRecorrenciaModel(
          id: 'rec_inf_del_all',
          tipoRecorrencia: 'mês',
          frequencia: 1,
        );

        final t1 = TransacaoModel(id: 't1', descricao: 'Spotify', valor: 35, tipo: 'despesa', dataCompetencia: DateTime(2026, 1, 10), consolidada: false, recorrencia: rec, divisoes: []);
        final t2 = TransacaoModel(id: 't2', descricao: 'Spotify', valor: 35, tipo: 'despesa', dataCompetencia: DateTime(2026, 2, 10), consolidada: false, recorrencia: rec, divisoes: []);

        controller.transacoesList.addAll([t1, t2]);
        mockRepo.recurrenceSeries = [t1, t2];

        final success = await controller.deleteTransaction(
          transacao: t1,
          deleteOption: 'current_and_future',
        );

        expect(success, isTrue);

        // Nenhuma parcela restou -> rec_inf_del_all deve ser deletada no batch
        expect(
          mockRepo.executedBatches.any(
            (op) => op['action'] == 'delete' && op['rowId'] == 'rec_inf_del_all',
          ),
          isTrue,
        );
      });

      test('Editar com current_and_future no meio de recorrência infinita encerra a recorrência antiga para não ressuscitar duplicatas', () async {
        final rec = TransacaoRecorrenciaModel(
          id: 'rec_old_inf',
          tipoRecorrencia: 'mês',
          frequencia: 1,
        );

        final t1 = TransacaoModel(id: 't1', descricao: 'Internet', valor: 100, tipo: 'despesa', dataCompetencia: DateTime(2026, 1, 10), consolidada: false, recorrencia: rec, divisoes: []);
        final t2 = TransacaoModel(id: 't2', descricao: 'Internet', valor: 100, tipo: 'despesa', dataCompetencia: DateTime(2026, 2, 10), consolidada: false, recorrencia: rec, divisoes: []);
        final t3 = TransacaoModel(id: 't3', descricao: 'Internet', valor: 100, tipo: 'despesa', dataCompetencia: DateTime(2026, 3, 10), consolidada: false, recorrencia: rec, divisoes: []);

        controller.transacoesList.addAll([t1, t2, t3]);
        mockRepo.recurrenceSeries = [t1, t2, t3];

        // Edita a partir de t2 (t1 fica no passado com rec_old_inf)
        final success = await controller.updateTransacao(
          id: 't2',
          descricao: 'Internet Reajustada',
          valor: 120,
          tipo: 'despesa',
          dataCompetencia: DateTime(2026, 2, 10),
          contaId: null,
          contaDestinoId: null,
          consolidada: false,
          categoriaId: null,
          divisao: [],
          optionRecorrencia: 'current_and_future',
        );

        expect(success, isTrue);

        // A recorrência antiga rec_old_inf deve ser atualizada para finita com totalParcelas: 1 e fimRecorrencia: 2026-01-10
        final updateOldRec = mockRepo.executedBatches.firstWhere(
          (op) => op['action'] == 'update' && op['rowId'] == 'rec_old_inf',
        );
        final updateOldRecData = updateOldRec['data'] as Map<String, dynamic>;
        expect(updateOldRecData['totalParcelas'], 1);
        expect(updateOldRecData['fimRecorrencia'], DateTime(2026, 1, 10).toIso8601String());
      });

      test('Criar recorrência infinita grava fimRecorrencia com a data da 24ª parcela gerada', () async {
        final success = await controller.createTransacao(
          descricao: 'Academia',
          valor: 150,
          tipo: 'despesa',
          dataCompetencia: DateTime(2026, 1, 15),
          contaId: null,
          contaDestinoId: null,
          consolidada: false,
          categoriaId: null,
          recorrente: true,
          recorrenciaIndeterminada: true,
          tipoRecorrencia: 'mês',
        );

        expect(success, isTrue);
        expect(mockRepo.createdRecorrencias, isNotEmpty);
        expect(
          mockRepo.createdRecorrencias.first['fimRecorrencia'],
          DateTime(2027, 12, 15),
        );
      });

      test('Excluir e criar séries recorrentes consolidadas agrupa atualização de saldo em 1 única chamada por conta', () async {
        final conta = ContaModel(id: 'c1', name: 'Conta Principal', userId: 'u1', saldoAtual: 1000.0);
        mockRepo.contas.add(conta);
        controller.contasList.add(conta);

        // Cria 4 parcelas consolidadas de R$ 50
        await controller.createTransacao(
          descricao: 'Parcelado',
          valor: 50,
          tipo: 'despesa',
          dataCompetencia: DateTime(2026, 1, 10),
          contaId: 'c1',
          contaDestinoId: null,
          consolidada: true,
          categoriaId: null,
          recorrente: true,
          recorrenciaIndeterminada: false,
          tipoRecorrencia: 'mês',
          totalParcelas: 4,
        );

        expect(mockRepo.updateAccountBalanceCallCount, 1);
        expect(mockRepo.contas.first.saldoAtual, 800.0);

        // Agora exclui todas as 4 parcelas consolidadas
        mockRepo.updateAccountBalanceCallCount = 0;
        final rec = TransacaoRecorrenciaModel(id: 'rec_4', tipoRecorrencia: 'mês', frequencia: 1, totalParcelas: 4);
        final series = List.generate(
          4,
          (i) => TransacaoModel(
            id: 'tx_$i',
            descricao: 'Parcelado',
            valor: 50,
            tipo: 'despesa',
            dataCompetencia: DateTime(2026, 1 + i, 10),
            consolidada: true,
            conta: conta,
            recorrencia: rec,
            divisoes: [],
          ),
        );
        mockRepo.recurrenceSeries = series;

        await controller.deleteTransaction(
          transacao: series.first,
          deleteOption: 'all',
        );

        expect(mockRepo.updateAccountBalanceCallCount, 1);
        expect(mockRepo.contas.first.saldoAtual, 1000.0);
      });
    });
  });
}
