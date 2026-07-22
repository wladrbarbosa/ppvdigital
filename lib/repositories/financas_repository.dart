import 'package:ppvdigital/models/categoria_transacao_model.dart';
import 'package:ppvdigital/models/conta_model.dart';
import 'package:ppvdigital/models/contato_model.dart';
import 'package:ppvdigital/models/divisao_transacao_model.dart';
import 'package:ppvdigital/models/transacao_model.dart';

abstract class FinancasRepository {
  Future<List<ContatoModel>> getContatos({
    required String usuarioId,
    bool forceLocal = false,
    DateTime? lastSyncedAt,
  });

  Future<ContatoModel> createContato({
    required String ownerId,
    required String nome,
    String? email,
    String? userId,
  });

  Future<List<ContaModel>> getContas({
    required String usuarioId,
    bool forceLocal = false,
    DateTime? lastSyncedAt,
  });

  Future<bool> createConta({
    required String name,
    required double saldoInicial,
    required String usuarioId,
  });

  Future<bool> updateConta({
    required String id,
    required String name,
    required double saldoAtual,
  });

  Future<bool> deleteConta({required String id});

  Future<List<CategoriaTransacaoModel>> getCategorias({
    required String usuarioId,
    bool forceLocal = false,
    DateTime? lastSyncedAt,
  });

  Future<bool> createCategoria({
    required String name,
    String? icone,
    required String hexColor,
    required String usuarioId,
  });

  Future<bool> updateCategoria({
    required String id,
    required String name,
    String? icone,
    required String hexColor,
  });

  Future<bool> deleteCategoria({required String id});

  Future<List<TransacaoModel>> getTransacoes({
    required String usuarioId,
    required List<String> contaIds,
    DateTime? targetMonth,
    DateTime? beforeDate,
    bool lightweight = false,
    bool forceLocal = false,
    DateTime? lastSyncedAt,
  });

  Future<List<TransacaoModel>> getRecurrenceSeries({
    required String recurrenceId,
  });

  Future<List<DivisaoTransacaoModel>> getDivisoes({
    required List<String> contatoResponsavelIds,
    bool forceLocal = false,
  });

  Future<String> createRecorrenciaRow({
    required String tipoRecorrencia,
    required int frequencia,
    int? totalParcelas,
    int? parcelaInicio,
    DateTime? fimRecorrencia,
  });

  Future<void> updateAccountBalance({
    required String contaId,
    required double newSaldo,
  });

  Future<void> deleteRow({required String tableId, required String rowId});

  Future<void> updateRow({
    required String tableId,
    required String rowId,
    required Map<String, dynamic> data,
  });

  Future<void> executeBatchOperations(List<Map<String, dynamic>> operations);

  Stream<List<ContatoModel>> watchContatos({required String usuarioId});

  Stream<List<ContaModel>> watchContas({required String usuarioId});

  Stream<List<CategoriaTransacaoModel>> watchCategorias({
    required String usuarioId,
  });

  Stream<List<TransacaoModel>> watchTransacoes({
    required String usuarioId,
    required List<String> contaIds,
    DateTime? targetMonth,
  });
}
