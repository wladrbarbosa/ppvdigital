import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppvdigital/models/local/app_database.dart';
import 'package:ppvdigital/models/transacao_model.dart';
import 'package:ppvdigital/models/transacao_recorrencia_model.dart';
import 'package:ppvdigital/repositories/drift_financas_repository.dart';
import 'package:ppvdigital/repositories/financas_repository.dart';

class MockRemoteFinancasRepository implements FinancasRepository {
  List<TransacaoModel> transacoes = [];

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
    return transacoes;
  }

  @override
  Future<List<TransacaoModel>> getRecurrenceSeries({
    required String recurrenceId,
  }) async {
    return transacoes.where((t) => t.recorrencia?.id == recurrenceId).toList();
  }

  @override
  Future<String> createRecorrenciaRow({
    required String tipoRecorrencia,
    required int frequencia,
    int? totalParcelas,
    int? parcelaInicio,
    DateTime? fimRecorrencia,
  }) async {
    return 'new_rec_id';
  }

  @override
  Future<void> executeBatchOperations(
    List<Map<String, dynamic>> operations,
  ) async {
    for (final op in operations) {
      final action = op['action'] as String;
      final rowId = op['rowId'] as String;
      final data = op['data'] as Map<String, dynamic>?;

      if (action == 'update' && data != null) {
        final index = transacoes.indexWhere((t) => t.id == rowId);
        if (index != -1) {
          final t = transacoes[index];
          DateTime? nextDate = t.dataCompetencia;
          if (data.containsKey('dataCompetencia')) {
            nextDate = DateTime.parse(data['dataCompetencia'] as String);
          }
          transacoes[index] = t.copyWith(
            descricao: data['descricao'] as String? ?? t.descricao,
            valor: (data['valor'] as num?)?.toDouble() ?? t.valor,
            tipo: data['tipo'] as String? ?? t.tipo,
            dataCompetencia: nextDate,
            consolidada: data.containsKey('consolidada')
                ? data['consolidada'] as bool
                : t.consolidada,
          );
        }
      }
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase database;
  late MockRemoteFinancasRepository remoteRepository;
  late DriftFinancasRepository driftRepository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    remoteRepository = MockRemoteFinancasRepository();
    driftRepository = DriftFinancasRepository(
      database: database,
      remoteRepository: remoteRepository,
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('Batch update updates transactions locally and remotely', () async {
    final t1 = TransacaoModel(
      id: 't1',
      descricao: 'Transacao 1',
      valor: 100.0,
      tipo: 'despesa',
      dataCompetencia: DateTime(2026, 7, 10),
      consolidada: false,
      divisoes: [],
    );

    final t2 = TransacaoModel(
      id: 't2',
      descricao: 'Transacao 2',
      valor: 200.0,
      tipo: 'receita',
      dataCompetencia: DateTime(2026, 7, 12),
      consolidada: false,
      divisoes: [],
    );

    remoteRepository.transacoes = [t1, t2];

    // Seed local database by syncing
    await driftRepository.getTransacoes(
      usuarioId: 'user1',
      contaIds: [],
      targetMonth: DateTime(2026, 7),
    );

    // Verify seeded correctly
    var localTrans = await driftRepository
        .watchTransacoes(
          usuarioId: 'user1',
          contaIds: [],
          targetMonth: DateTime(2026, 7),
        )
        .first;

    expect(localTrans.length, equals(2));
    expect(localTrans[0].dataCompetencia, equals(DateTime(2026, 7, 10)));

    // Perform batch update on date
    final nextDate = DateTime(2026, 7, 15);
    final ops = [
      {
        'action': 'update',
        'databaseId': 'db1',
        'tableId': '671f7a6f000cb3ab17b9',
        'rowId': 't1',
        'data': {
          'descricao': 'Transacao 1',
          'valor': 100.0,
          'tipo': 'despesa',
          'dataCompetencia': nextDate.toIso8601String(),
          'consolidada': false,
          'conta': null,
          'contaDestino': null,
          'categoria': null,
          'recorrencia': 'rec_123',
          'devedorContato': null,
          'credorContato': null,
        },
      },
      {
        'action': 'update',
        'databaseId': 'db1',
        'tableId': '671f7a6f000cb3ab17b9',
        'rowId': 't2',
        'data': {
          'descricao': 'Transacao 2',
          'valor': 200.0,
          'tipo': 'receita',
          'dataCompetencia': nextDate.toIso8601String(),
          'consolidada': false,
          'conta': null,
          'contaDestino': null,
          'categoria': null,
          'recorrencia': null,
          'devedorContato': null,
          'credorContato': null,
        },
      },
    ];

    await driftRepository.executeBatchOperations(ops);

    // Check local database is updated
    localTrans = await driftRepository
        .watchTransacoes(
          usuarioId: 'user1',
          contaIds: [],
          targetMonth: DateTime(2026, 7),
        )
        .first;

    expect(localTrans.length, equals(2));
    expect(
      localTrans.firstWhere((t) => t.id == 't1').dataCompetencia,
      equals(nextDate),
    );
    expect(
      localTrans.firstWhere((t) => t.id == 't2').dataCompetencia,
      equals(nextDate),
    );

    // Verify remote is updated
    expect(
      remoteRepository.transacoes
          .firstWhere((t) => t.id == 't1')
          .dataCompetencia,
      equals(nextDate),
    );
  });

  test('Batch update updates transaction types in SQLite', () async {
    final t1 = TransacaoModel(
      id: 't1',
      descricao: 'Transacao 1',
      valor: 100.0,
      tipo: 'despesa',
      dataCompetencia: DateTime(2026, 7, 10),
      consolidada: false,
      divisoes: [],
    );

    final t2 = TransacaoModel(
      id: 't2',
      descricao: 'Transacao 2',
      valor: 200.0,
      tipo: 'despesa',
      dataCompetencia: DateTime(2026, 8, 10),
      consolidada: false,
      divisoes: [],
    );

    remoteRepository.transacoes = [t1, t2];

    // Seed local database
    await driftRepository.getTransacoes(
      usuarioId: 'user1',
      contaIds: [],
      targetMonth: DateTime(2026, 7),
    );
    await driftRepository.getTransacoes(
      usuarioId: 'user1',
      contaIds: [],
      targetMonth: DateTime(2026, 8),
    );

    // Perform update
    final ops = [
      {
        'action': 'update',
        'databaseId': 'db1',
        'tableId': '671f7a6f000cb3ab17b9',
        'rowId': 't1',
        'data': {
          'descricao': 'Transacao 1',
          'valor': 100.0,
          'tipo': 'receita',
          'dataCompetencia': DateTime(2026, 7, 10).toIso8601String(),
          'consolidada': false,
        },
      },
      {
        'action': 'update',
        'databaseId': 'db1',
        'tableId': '671f7a6f000cb3ab17b9',
        'rowId': 't2',
        'data': {
          'descricao': 'Transacao 2',
          'valor': 200.0,
          'tipo': 'receita',
          'dataCompetencia': DateTime(2026, 8, 10).toIso8601String(),
          'consolidada': false,
        },
      }
    ];

    await driftRepository.executeBatchOperations(ops);

    // Verify local is updated
    final localTrans = await database.select(database.transacaos).get();
    expect(localTrans.firstWhere((t) => t.remoteId == 't1').tipo, equals('receita'));
    expect(localTrans.firstWhere((t) => t.remoteId == 't2').tipo, equals('receita'));
  });

  test('current_and_future recurrent update updates current and future transactions', () async {
    final rec = TransacaoRecorrenciaModel(
      id: 'rec_1',
      tipoRecorrencia: 'mês',
      frequencia: 1,
    );

    final t1 = TransacaoModel(
      id: 't1',
      descricao: 'Aluguel (Parcela 1/3)',
      valor: 1000.0,
      tipo: 'despesa',
      dataCompetencia: DateTime(2026, 7, 10),
      consolidada: false,
      recorrencia: rec,
      divisoes: [],
    );

    final t2 = TransacaoModel(
      id: 't2',
      descricao: 'Aluguel (Parcela 2/3)',
      valor: 1000.0,
      tipo: 'despesa',
      dataCompetencia: DateTime(2026, 8, 10),
      consolidada: false,
      recorrencia: rec,
      divisoes: [],
    );

    final t3 = TransacaoModel(
      id: 't3',
      descricao: 'Aluguel (Parcela 3/3)',
      valor: 1000.0,
      tipo: 'despesa',
      dataCompetencia: DateTime(2026, 9, 10),
      consolidada: false,
      recorrencia: rec,
      divisoes: [],
    );

    remoteRepository.transacoes = [t1, t2, t3];

    // Seed local database
    await driftRepository.getTransacoes(
      usuarioId: 'user1',
      contaIds: [],
      targetMonth: DateTime(2026, 7),
    );
    await driftRepository.getTransacoes(
      usuarioId: 'user1',
      contaIds: [],
      targetMonth: DateTime(2026, 8),
    );
    await driftRepository.getTransacoes(
      usuarioId: 'user1',
      contaIds: [],
      targetMonth: DateTime(2026, 9),
    );

    // Let's verify SQLite has 3 transactions
    var localTrans = await database.select(database.transacaos).get();
    expect(localTrans.length, equals(3));
    expect(localTrans.every((t) => t.tipo == 'despesa'), isTrue);

    // Simulate controller updateTransacao for 'current_and_future' on t2 (August)
    // original is t2. We change it to receita.
    // futureTrans should be t3 (September).
    // t1 (July) is in the past, so it should NOT be updated.
    
    // 1. Fetch series
    final allRecTrans = await driftRepository.getRecurrenceSeries(
      recurrenceId: 'rec_1',
    );
    expect(allRecTrans.length, equals(3));

    // 2. newRecId
    final newRecId = await driftRepository.createRecorrenciaRow(
      tipoRecorrencia: 'mês',
      frequencia: 1,
      totalParcelas: 3,
      parcelaInicio: 2,
    );
    expect(newRecId, equals('new_rec_id'));

    // 3. Sort and filter future transactions
    final futureTrans = allRecTrans
        .where((t) => t.id != 't2' && t.dataCompetencia.isAfter(DateTime(2026, 8, 10)))
        .toList();
    expect(futureTrans.length, equals(1));
    expect(futureTrans.first.id, equals('t3'));

    // 4. Create batch ops
    final ops = <Map<String, dynamic>>[];
    
    // Future update
    ops.add({
      'action': 'update',
      'databaseId': 'db1',
      'tableId': '671f7a6f000cb3ab17b9',
      'rowId': 't3',
      'data': {
        'descricao': 'Aluguel (Parcela 3/3)',
        'valor': 1000.0,
        'tipo': 'receita',
        'dataCompetencia': DateTime(2026, 9, 10).toIso8601String(),
        'recorrencia': newRecId,
      },
    });

    // Current update
    ops.add({
      'action': 'update',
      'databaseId': 'db1',
      'tableId': '671f7a6f000cb3ab17b9',
      'rowId': 't2',
      'data': {
        'descricao': 'Aluguel (Parcela 2/3)',
        'valor': 1000.0,
        'tipo': 'receita',
        'dataCompetencia': DateTime(2026, 8, 10).toIso8601String(),
        'recorrencia': newRecId,
      },
    });

    await driftRepository.executeBatchOperations(ops);

    // Verify SQLite
    localTrans = await database.select(database.transacaos).get();
    expect(localTrans.firstWhere((t) => t.remoteId == 't1').tipo, equals('despesa')); // Past unchanged
    expect(localTrans.firstWhere((t) => t.remoteId == 't2').tipo, equals('receita')); // Current updated
    expect(localTrans.firstWhere((t) => t.remoteId == 't3').tipo, equals('receita')); // Future updated
    expect(localTrans.firstWhere((t) => t.remoteId == 't2').recorrencia?.id, equals('new_rec_id'));
    expect(localTrans.firstWhere((t) => t.remoteId == 't3').recorrencia?.id, equals('new_rec_id'));
  });
}
