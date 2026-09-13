import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppvdigital/core.dart';
import 'package:ppvdigital/models/backup/backup_payload_model.dart';
import 'package:ppvdigital/models/local/app_database.dart';
import 'package:ppvdigital/services/backup/restore_service.dart';

Row createFakeRow({
  required String id,
  required String tableId,
  required Map<String, dynamic> data,
}) {
  return Row(
    $id: id,
    $sequence: 'seq_$id',
    $tableId: tableId,
    $databaseId: Core.databaseId,
    $createdAt: DateTime.now().toIso8601String(),
    $updatedAt: DateTime.now().toIso8601String(),
    $permissions: [],
    data: data,
  );
}

class FakeRestoreTablesDB implements TablesDB {
  FakeRestoreTablesDB();

  final Map<String, Map<String, Map<String, dynamic>>> tables = {};
  final List<String> callLog = [];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #client) {
      return Client();
    }
    return super.noSuchMethod(invocation);
  }

  @override
  Future<RowList> listRows({
    required String databaseId,
    required String tableId,
    List<String>? queries,
    String? transactionId,
    bool? total,
    num? ttl,
  }) async {
    callLog.add('listRows:$tableId');
    final tableMap = tables[tableId] ?? {};
    final rows = tableMap.entries.map((e) {
      return createFakeRow(id: e.key, tableId: tableId, data: e.value);
    }).toList();

    return RowList(total: rows.length, rows: rows);
  }

  @override
  Future<Row> createRow({
    required String databaseId,
    required String tableId,
    required String rowId,
    required Map<dynamic, dynamic> data,
    List<String>? permissions,
    String? transactionId,
  }) async {
    callLog.add('createRow:$tableId:$rowId');
    final map = Map<String, dynamic>.from(data);
    tables.putIfAbsent(tableId, () => {})[rowId] = map;
    return createFakeRow(id: rowId, tableId: tableId, data: map);
  }

  @override
  Future<Row> updateRow({
    required String databaseId,
    required String tableId,
    required String rowId,
    Map<dynamic, dynamic>? data,
    List<String>? permissions,
    String? transactionId,
  }) async {
    callLog.add('updateRow:$tableId:$rowId');
    final tableMap = tables[tableId];
    if (tableMap == null || !tableMap.containsKey(rowId)) {
      throw AppwriteException('Row not found', 404, 'row_not_found');
    }
    final map = Map<String, dynamic>.from(data ?? {});
    tableMap[rowId] = map;
    return createFakeRow(id: rowId, tableId: tableId, data: map);
  }

  @override
  Future<dynamic> deleteRow({
    required String databaseId,
    required String tableId,
    required String rowId,
    String? transactionId,
  }) async {
    callLog.add('deleteRow:$tableId:$rowId');
    tables[tableId]?.remove(rowId);
    return '';
  }
}

void main() {
  group('RestoreService Tests', () {
    const testUserId = 'user_rest_123';
    const testEmail = 'rest@exemplo.com';

    BackupPayloadModel createSamplePayload() {
      final now = DateTime.now();
      final futureDate = DateTime(2028, 6, 20);

      final data = <String, List<Map<String, dynamic>>>{
        'contas': [
          {
            r'$id': 'acc_1',
            'name': 'Banco do Brasil',
            'saldoAtual': 3000.0,
            'userId': testUserId,
          }
        ],
        'contatos': [
          {
            r'$id': 'cont_1',
            'nome': 'Carlos',
            'ownerId': testUserId,
          }
        ],
        'categoriasTransacoes': [
          {
            r'$id': 'cat_tx_1',
            'nome': 'Transporte',
            'corHex': '#123456',
            'userId': testUserId,
          }
        ],
        'categoriasTarefasHabitos': [
          {
            r'$id': 'cat_th_1',
            'nome': 'Treino',
            'corHex': '#654321',
            'usuario': testUserId,
          }
        ],
        'tarefasHabitosQtds': [
          {
            r'$id': 'qtd_1',
            'metaVezes': 4,
            'usuario': testUserId,
          }
        ],
        'transacaoRecorrencias': [
          {
            r'$id': 'rec_1',
            'tipoRecorrencia': 'mês',
            'frequencia': 1,
          }
        ],
        'tarefasEHabitos': [
          {
            r'$id': 'th_1',
            'nome': 'Academia',
            'tipo': 'habito',
            'usuario': testUserId,
          }
        ],
        'transacoes': [
          {
            r'$id': 'tx_1',
            'descricao': 'Combustível Passado',
            'valor': 200.0,
            'conta': 'acc_1',
            'categoria': 'cat_tx_1',
            'dataCompetencia': now.subtract(const Duration(days: 30)).toIso8601String(),
            'consolidada': true,
          },
          {
            r'$id': 'tx_future',
            'descricao': 'IPVA 2028 Futuro',
            'valor': 1500.0,
            'conta': 'acc_1',
            'categoria': 'cat_tx_1',
            'dataCompetencia': futureDate.toIso8601String(),
            'consolidada': false,
          },
        ],
        'divisaoTransacoes': [
          {
            r'$id': 'div_1',
            'descricao': 'Parte A',
            'valor': 100.0,
            'transacao': 'tx_1',
          }
        ],
        'historicoTarefasHabitos': [
          {
            r'$id': 'hist_1',
            'tarefasEHabitos': 'th_1',
            'usuario': testUserId,
          }
        ],
      };

      return BackupPayloadModel(
        exportedAt: now,
        userId: testUserId,
        userEmail: testEmail,
        data: data,
      );
    }

    test('validateBackup valida JSON, schema e checksum corretamente', () async {
      final tablesDB = FakeRestoreTablesDB();
      final service = RestoreService(tablesDB: tablesDB);

      final payload = createSamplePayload();
      final jsonStr = payload.toJson();

      expect(await service.validateBackup(jsonStr), isTrue);

      // JSON com checksum adulterado
      final tamperedJson = jsonStr.replaceAll('Banco do Brasil', 'Banco Falso');
      expect(await service.validateBackup(tamperedJson), isFalse);

      // JSON malformado
      expect(await service.validateBackup('{"invalid":'), isFalse);
    });

    test('restoreBackup com cleanReplace executa limpeza e insere as 4 fases em ordem', () async {
      final tablesDB = FakeRestoreTablesDB();
      var resetControllersCalled = false;

      final service = RestoreService(
        tablesDB: tablesDB,
        onResetControllers: () => resetControllersCalled = true,
      );

      final payload = createSamplePayload();
      final List<String> steps = [];

      await service.restoreBackup(
        payload,
        cleanReplace: true,
        onProgress: (step, progress) => steps.add(step),
      );

      expect(resetControllersCalled, isTrue);
      expect(steps, isNotEmpty);
      expect(steps.first, contains('Limpando'));
      expect(steps.last, contains('sucesso'));

      // Verifica que as entidades foram inseridas no fakeTablesDB
      expect(tablesDB.tables[Core.tableContas]?.containsKey('acc_1'), isTrue);
      expect(tablesDB.tables[Core.tableContatos]?.containsKey('cont_1'), isTrue);
      expect(tablesDB.tables[Core.tableCategoriasTransacoes]?.containsKey('cat_tx_1'), isTrue);
      expect(tablesDB.tables[Core.tableCategoriasTarefasHabitos]?.containsKey('cat_th_1'), isTrue);
      expect(tablesDB.tables[Core.tableTarefasHabitosQtds]?.containsKey('qtd_1'), isTrue);
      expect(tablesDB.tables[Core.tableTransacaoRecorrencias]?.containsKey('rec_1'), isTrue);
      expect(tablesDB.tables[Core.tableTarefasEHabitos]?.containsKey('th_1'), isTrue);
      expect(tablesDB.tables[Core.tableTransacoes]?.containsKey('tx_1'), isTrue);
      expect(tablesDB.tables[Core.tableTransacoes]?.containsKey('tx_future'), isTrue);
      expect(tablesDB.tables[Core.tableDivisaoTransacoes]?.containsKey('div_1'), isTrue);
      expect(tablesDB.tables[Core.tableHistoricoTarefasHabitos]?.containsKey('hist_1'), isTrue);

      // Garante sanitização de campos internos
      final restoredAcc = tablesDB.tables[Core.tableContas]!['acc_1']!;
      expect(restoredAcc.containsKey(r'$id'), isFalse);
      expect(restoredAcc['name'], equals('Banco do Brasil'));
    });

    test('restoreBackup com cleanReplace: false faz upsert sem limpeza prévia', () async {
      final tablesDB = FakeRestoreTablesDB();

      // Pré-insere uma conta existente para testar o update
      tablesDB.tables[Core.tableContas] = {
        'acc_1': {'name': 'Nome Antigo', 'saldoAtual': 100.0, 'userId': testUserId},
      };

      final service = RestoreService(tablesDB: tablesDB);
      final payload = createSamplePayload();

      await service.restoreBackup(
        payload,
        cleanReplace: false,
      );

      // Deve ter atualizado para 'Banco do Brasil'
      final updatedAcc = tablesDB.tables[Core.tableContas]!['acc_1']!;
      expect(updatedAcc['name'], equals('Banco do Brasil'));
      expect(updatedAcc['saldoAtual'], equals(3000.0));
    });

    test('restoreBackup lança FormatException se checksum for inválido', () {
      final tablesDB = FakeRestoreTablesDB();
      final service = RestoreService(tablesDB: tablesDB);

      final payload = BackupPayloadModel(
        exportedAt: DateTime.now(),
        userId: testUserId,
        userEmail: testEmail,
        data: {},
        checksum: 'sha256:invalido',
      );

      expect(
        () => service.restoreBackup(payload, cleanReplace: true),
        throwsA(isA<FormatException>()),
      );
    });

    test('cleanExistingUserData remove todas as entidades prévias e limpa AppDatabase local', () async {
      final tablesDB = FakeRestoreTablesDB();
      final localDb = AppDatabase(NativeDatabase.memory());

      // Pré-popula tabelas com registros que serão limpos
      tablesDB.tables[Core.tableContas] = {
        'old_acc': {'name': 'Conta Velha', 'userId': testUserId},
      };
      tablesDB.tables[Core.tableContatos] = {
        'old_contact': {'nome': 'Contato Velho', 'ownerId': testUserId},
      };
      tablesDB.tables[Core.tableCategoriasTransacoes] = {
        'old_cat_fin': {'nome': 'Categoria Velha', 'userId': testUserId},
      };
      tablesDB.tables[Core.tableCategoriasTarefasHabitos] = {
        'old_cat_th': {'nome': 'Cat Tarefa Velha', 'usuario': testUserId},
      };
      tablesDB.tables[Core.tableTarefasHabitosQtds] = {
        'old_qtd': {'metaVezes': 1, 'usuario': testUserId},
      };
      tablesDB.tables[Core.tableTarefasEHabitos] = {
        'old_th': {'nome': 'Hábito Velho', 'usuario': testUserId},
      };
      tablesDB.tables[Core.tableHistoricoTarefasHabitos] = {
        'old_hist': {'usuario': testUserId},
      };
      tablesDB.tables[Core.tableTransacoes] = {
        'old_tx': {'descricao': 'Tx Velha', 'conta': 'old_acc'},
      };
      tablesDB.tables[Core.tableDivisaoTransacoes] = {
        'old_div': {'transacao': 'old_tx'},
      };

      // Insere algo no SQLite Drift
      await localDb.setSetting('custom_key', 'some_value');

      final service = RestoreService(
        tablesDB: tablesDB,
        localDatabase: localDb,
      );

      final payload = createSamplePayload();
      await service.restoreBackup(payload, cleanReplace: true);

      // Garante que registros antigos não existem mais
      expect(tablesDB.tables[Core.tableContas]?.containsKey('old_acc'), isFalse);
      expect(tablesDB.tables[Core.tableTransacoes]?.containsKey('old_tx'), isFalse);
      expect(tablesDB.tables[Core.tableDivisaoTransacoes]?.containsKey('old_div'), isFalse);
      expect(tablesDB.tables[Core.tableHistoricoTarefasHabitos]?.containsKey('old_hist'), isFalse);

      // Garante que os novos registros do payload foram restaurados
      expect(tablesDB.tables[Core.tableContas]?.containsKey('acc_1'), isTrue);
      expect(tablesDB.tables[Core.tableTransacoes]?.containsKey('tx_1'), isTrue);

      await localDb.close();
    });
  });
}
