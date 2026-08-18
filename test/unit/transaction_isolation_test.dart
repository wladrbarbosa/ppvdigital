import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppvdigital/models/conta_model.dart';
import 'package:ppvdigital/models/local/app_database.dart';
import 'package:ppvdigital/models/transacao_model.dart';
import 'package:ppvdigital/repositories/drift_financas_repository.dart';
import 'package:ppvdigital/repositories/financas_repository.dart';

class MockRemoteFinancasRepo implements FinancasRepository {
  List<TransacaoModel> transacoes = [];

  @override
  Future<List<TransacaoModel>> getTransacoes({
    required String usuarioId,
    required List<String> contaIds,
    DateTime? targetMonth,
    DateTime? beforeDate,
    bool forceLocal = false,
    DateTime? lastSyncedAt,
  }) async {
    return transacoes.where((t) {
      final cId = t.conta?.id;
      final dId = t.contaDestino?.id;
      return (cId != null && contaIds.contains(cId)) ||
          (dId != null && contaIds.contains(dId));
    }).toList();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late AppDatabase database;
  late MockRemoteFinancasRepo remoteRepo;
  late DriftFinancasRepository driftRepo;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    remoteRepo = MockRemoteFinancasRepo();
    driftRepo = DriftFinancasRepository(
      database: database,
      remoteRepository: remoteRepo,
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('DriftFinancasRepository isolates queries to accounts belonging to the requested user', () async {
    final contaUser1 = ContaModel(id: 'c_user1', name: 'Conta User 1', userId: 'user_1', saldoAtual: 100);
    final contaUser2 = ContaModel(id: 'c_user2', name: 'Conta User 2', userId: 'user_2', saldoAtual: 200);

    // Save contas in SQLite
    await database.into(database.contas).insert(driftRepo.toContaCompanion(contaUser1));
    await database.into(database.contas).insert(driftRepo.toContaCompanion(contaUser2));

    final t1 = TransacaoModel(
      id: 'tx1',
      descricao: 'User 1 Tx',
      valor: 50.0,
      tipo: 'despesa',
      dataCompetencia: DateTime(2026, 7, 10),
      consolidada: true,
      conta: contaUser1,
      divisoes: [],
    );

    final t2 = TransacaoModel(
      id: 'tx2',
      descricao: 'User 2 Tx',
      valor: 80.0,
      tipo: 'despesa',
      dataCompetencia: DateTime(2026, 7, 12),
      consolidada: true,
      conta: contaUser2,
      divisoes: [],
    );

    // Insert both in SQLite
    await database.into(database.transacaos).insert(driftRepo.toTransacaoCompanion(t1));
    await database.into(database.transacaos).insert(driftRepo.toTransacaoCompanion(t2));

    // When querying user_1 without explicit contaIds, it must ONLY return user_1 transactions
    final user1Tx = await driftRepo.getTransacoes(
      usuarioId: 'user_1',
      contaIds: [],
      targetMonth: DateTime(2026, 7),
      forceLocal: true,
    );

    expect(user1Tx.length, equals(1));
    expect(user1Tx.first.id, equals('tx1'));
    expect(user1Tx.first.conta?.id, equals('c_user1'));

    // When querying user_2, it must ONLY return user_2 transactions
    final user2Tx = await driftRepo.getTransacoes(
      usuarioId: 'user_2',
      contaIds: [],
      targetMonth: DateTime(2026, 7),
      forceLocal: true,
    );

    expect(user2Tx.length, equals(1));
    expect(user2Tx.first.id, equals('tx2'));
    expect(user2Tx.first.conta?.id, equals('c_user2'));

    // If user_1 maliciously requests contaIds: ['c_user2'], it must return empty
    final maliciousTx = await driftRepo.getTransacoes(
      usuarioId: 'user_1',
      contaIds: ['c_user2'],
      targetMonth: DateTime(2026, 7),
      forceLocal: true,
    );

    expect(maliciousTx, isEmpty);
  });

  test('DriftFinancasRepository handleRealtimeEvent discards transactions from foreign user accounts', () async {
    final contaUser1 = ContaModel(id: 'c_user1', name: 'Conta User 1', userId: 'user_1', saldoAtual: 100);
    await database.into(database.contas).insert(driftRepo.toContaCompanion(contaUser1));

    // Realtime event for foreign transaction
    await driftRepo.handleRealtimeEvent(
      tableId: '671f7a6f000cb3ab17b9', // tableTransacoes
      action: 'create',
      payload: {
        r'$id': 'tx_foreign',
        'descricao': 'Foreign Tx',
        'valor': 999.0,
        'tipo': 'despesa',
        'dataCompetencia': DateTime(2026, 7, 10).toIso8601String(),
        'consolidada': true,
        'conta': {'\$id': 'c_user2', 'name': 'Other', 'userId': 'user_2'},
      },
    );

    final storedTx = await database.select(database.transacaos).get();
    expect(storedTx.any((t) => t.remoteId == 'tx_foreign'), isFalse);

    // Realtime event for own user transaction
    await driftRepo.handleRealtimeEvent(
      tableId: '671f7a6f000cb3ab17b9',
      action: 'create',
      payload: {
        r'$id': 'tx_own',
        'descricao': 'Own Tx',
        'valor': 15.0,
        'tipo': 'despesa',
        'dataCompetencia': DateTime(2026, 7, 10).toIso8601String(),
        'consolidada': true,
        'conta': {'\$id': 'c_user1', 'name': 'Conta User 1', 'userId': 'user_1'},
      },
    );

    final storedTxAfter = await database.select(database.transacaos).get();
    expect(storedTxAfter.any((t) => t.remoteId == 'tx_own'), isTrue);
  });
}
