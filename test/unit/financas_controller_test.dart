import 'package:flutter_test/flutter_test.dart';
import 'package:ppvdigital/app/capacitacao/financas/financas_controller.dart';
import 'package:ppvdigital/models/categoria_transacao_model.dart';
import 'package:ppvdigital/models/conta_model.dart';
import 'package:ppvdigital/models/contato_model.dart';
import 'package:ppvdigital/models/divisao_transacao_model.dart';
import 'package:ppvdigital/models/transacao_model.dart';
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

  @override
  Future<void> updateAccountBalance({required String contaId, required double newSaldo}) async {
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

  @override
  Future<List<ContatoModel>> getContatos({required String usuarioId, bool forceLocal = false, DateTime? lastSyncedAt}) async => contatos;

  @override
  Future<List<TransacaoModel>> getTransacoes({required String usuarioId, required List<String> contaIds, DateTime? targetMonth, DateTime? beforeDate, bool forceLocal = false, DateTime? lastSyncedAt}) async => transacoes;

  @override
  Future<Set<String>> getActiveTransacaoIdsInMonth({required String usuarioId, required List<String> contaIds, required DateTime targetMonth}) async => transacoes.map((t) => t.id).toSet();

  @override
  Future<List<TransacaoModel>> getRecurrenceSeries({required String recurrenceId}) async => [];

  @override
  Future<List<DivisaoTransacaoModel>> getDivisoes({required List<String> contatoResponsavelIds, bool forceLocal = false, DateTime? lastSyncedAt}) async => [];

  @override
  Future<String> createRecorrenciaRow({required String tipoRecorrencia, required int frequencia, int? totalParcelas, int? parcelaInicio, DateTime? fimRecorrencia}) async => 'rec_id';

  @override
  Future<void> deleteRow({required String tableId, required String rowId}) async {}

  @override
  Future<void> updateRow({required String tableId, required String rowId, required Map<String, dynamic> data}) async {}

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
  });
}
