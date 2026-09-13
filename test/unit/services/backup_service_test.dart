import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppvdigital/core.dart';
import 'package:ppvdigital/services/backup/backup_service.dart';

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

class FakeTablesDB implements TablesDB {
  FakeTablesDB({required this.tableData});

  final Map<String, List<Row>> tableData;
  final List<Map<String, dynamic>> recordedCalls = [];

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
    recordedCalls.add({
      'tableId': tableId,
      'queries': queries ?? [],
    });

    final allRows = tableData[tableId] ?? [];

    // Lógica simplificada de paginação para simular o comportamento de cursorAfter
    final cursorQuery = queries?.firstWhere(
      (q) => q.contains('cursorAfter'),
      orElse: () => '',
    );
    if (cursorQuery != null && cursorQuery.isNotEmpty) {
      String cursorId = '';
      try {
        final decoded = json.decode(cursorQuery) as Map<String, dynamic>;
        cursorId = (decoded['values'] as List).first.toString();
      } catch (_) {
        final match = RegExp(r'\["([^"]+)"\]').firstMatch(cursorQuery);
        cursorId = match?.group(1) ?? '';
      }
      final index = allRows.indexWhere((r) => r.$id == cursorId);
      if (index != -1 && index + 1 < allRows.length) {
        final sublist = allRows.sublist(index + 1);
        return RowList(total: allRows.length, rows: sublist);
      }
      return RowList(total: allRows.length, rows: []);
    }

    // Se houver mais de 5000 itens e sem cursor, simula limite de página do Appwrite
    if (allRows.length > 5000) {
      return RowList(total: allRows.length, rows: allRows.sublist(0, 5000));
    }

    return RowList(total: allRows.length, rows: allRows);
  }
}

void main() {
  group('BackupService Tests', () {
    const testUserId = 'user_123';
    const testUserEmail = 'usuario@exemplo.com';

    test('generateBackup extrai as 10 tabelas e preserva dados passados, correntes e futuros', () async {
      final pastDate = DateTime(2023, 1, 15).toIso8601String();
      final currentDate = DateTime.now().toIso8601String();
      final futureDate = DateTime(2028, 12, 31).toIso8601String();

      final fakeData = <String, List<Row>>{
        Core.tableContas: [
          createFakeRow(
            id: 'acc_1',
            tableId: Core.tableContas,
            data: {'name': 'Nubank', 'saldoAtual': 2000.0, 'userId': testUserId},
          ),
          createFakeRow(
            id: 'acc_2',
            tableId: Core.tableContas,
            data: {'name': 'Carteira', 'saldoAtual': 150.0, 'userId': testUserId},
          ),
        ],
        Core.tableContatos: [
          createFakeRow(
            id: 'contact_1',
            tableId: Core.tableContatos,
            data: {'nome': 'Maria', 'ownerId': testUserId},
          ),
        ],
        Core.tableCategoriasTransacoes: [
          createFakeRow(
            id: 'cat_fin_1',
            tableId: Core.tableCategoriasTransacoes,
            data: {'nome': 'Moradia', 'corHex': '#4A90E2', 'userId': testUserId},
          ),
        ],
        Core.tableCategoriasTarefasHabitos: [
          createFakeRow(
            id: 'cat_th_1',
            tableId: Core.tableCategoriasTarefasHabitos,
            data: {'nome': 'Estudos', 'corHex': '#50E3C2', 'usuario': testUserId},
          ),
        ],
        Core.tableTarefasHabitosQtds: [
          createFakeRow(
            id: 'qtd_1',
            tableId: Core.tableTarefasHabitosQtds,
            data: {'metaVezes': 5, 'valor': 'Ler 10 páginas', 'usuario': testUserId},
          ),
        ],
        Core.tableTarefasEHabitos: [
          createFakeRow(
            id: 'task_1',
            tableId: Core.tableTarefasEHabitos,
            data: {
              'nome': 'Hábito de Leitura',
              'tipo': 'habito',
              'usuario': testUserId,
              'agendamento': futureDate,
            },
          ),
        ],
        Core.tableHistoricoTarefasHabitos: [
          createFakeRow(
            id: 'hist_1',
            tableId: Core.tableHistoricoTarefasHabitos,
            data: {'tarefasEHabitos': 'task_1', 'usuario': testUserId},
          ),
        ],
        Core.tableTransacoes: [
          createFakeRow(
            id: 'tx_past',
            tableId: Core.tableTransacoes,
            data: {
              'descricao': 'Aluguel Passado 2023',
              'valor': 1200.0,
              'dataCompetencia': pastDate,
              'conta': 'acc_1',
              'consolidada': true,
              'recorrencia': 'rec_1',
            },
          ),
          createFakeRow(
            id: 'tx_curr',
            tableId: Core.tableTransacoes,
            data: {
              'descricao': 'Supermercado Mês Atual',
              'valor': 350.0,
              'dataCompetencia': currentDate,
              'conta': 'acc_1',
              'consolidada': true,
            },
          ),
          createFakeRow(
            id: 'tx_future',
            tableId: Core.tableTransacoes,
            data: {
              'descricao': 'Parcela Carro 2028',
              'valor': 800.0,
              'dataCompetencia': futureDate,
              'conta': 'acc_2',
              'consolidada': false,
            },
          ),
        ],
        Core.tableDivisaoTransacoes: [
          createFakeRow(
            id: 'div_1',
            tableId: Core.tableDivisaoTransacoes,
            data: {'descricao': 'Item A', 'valor': 100.0, 'transacao': 'tx_past'},
          ),
        ],
        Core.tableTransacaoRecorrencias: [
          createFakeRow(
            id: 'rec_1',
            tableId: Core.tableTransacaoRecorrencias,
            data: {'tipoRecorrencia': 'mês', 'frequencia': 1},
          ),
        ],
      };

      final fakeTablesDB = FakeTablesDB(tableData: fakeData);
      final service = BackupService(tablesDB: fakeTablesDB);

      final List<String> progressSteps = [];
      final List<double> progressValues = [];

      final payload = await service.generateBackup(
        userId: testUserId,
        userEmail: testUserEmail,
        onProgress: (step, progress) {
          progressSteps.add(step);
          progressValues.add(progress);
        },
      );

      // Validações gerais
      expect(payload.userId, equals(testUserId));
      expect(payload.userEmail, equals(testUserEmail));
      expect(payload.isValidChecksum, isTrue);

      // Resumo das 10 tabelas
      expect(payload.contas.length, equals(2));
      expect(payload.contatos.length, equals(1));
      expect(payload.categoriasTransacoes.length, equals(1));
      expect(payload.categoriasTarefasHabitos.length, equals(1));
      expect(payload.tarefasHabitosQtds.length, equals(1));
      expect(payload.tarefasEHabitos.length, equals(1));
      expect(payload.historicoTarefasHabitos.length, equals(1));
      expect(payload.transacoes.length, equals(3));
      expect(payload.divisaoTransacoes.length, equals(1));
      expect(payload.transacaoRecorrencias.length, equals(1));
      expect(payload.summary.totalRecords, equals(13));

      // Validação de cobertura temporal irrestrita (passado, presente e futuro)
      final pastTx = payload.transacoes.firstWhere((t) => t[r'$id'] == 'tx_past');
      final currTx = payload.transacoes.firstWhere((t) => t[r'$id'] == 'tx_curr');
      final futureTx = payload.transacoes.firstWhere((t) => t[r'$id'] == 'tx_future');

      expect(pastTx['dataCompetencia'], equals(pastDate));
      expect(currTx['dataCompetencia'], equals(currentDate));
      expect(futureTx['dataCompetencia'], equals(futureDate));
      expect(futureTx['consolidada'], isFalse);

      // Validação de progresso
      expect(progressSteps, isNotEmpty);
      expect(progressValues.first, equals(0.1));
      expect(progressValues.last, equals(1.0));
    });

    test('fetchAllRows pagina corretamente via cursor quando tabela excede 5000 registros', () async {
      // Cria 5050 linhas fictícias
      final largeRows = List.generate(
        5050,
        (i) => createFakeRow(
          id: 'row_$i',
          tableId: Core.tableHistoricoTarefasHabitos,
          data: {'index': i, 'usuario': testUserId},
        ),
      );

      final fakeTablesDB = FakeTablesDB(
        tableData: {Core.tableHistoricoTarefasHabitos: largeRows},
      );
      final service = BackupService(tablesDB: fakeTablesDB);

      final results = await service.fetchAllRows(
        tableId: Core.tableHistoricoTarefasHabitos,
      );

      expect(results.length, equals(5050));
      expect(fakeTablesDB.recordedCalls.length, equals(2)); // Duas páginas consultadas
    });

    test('Lida graciosamente com usuário sem contas ou registros vazios', () async {
      final fakeTablesDB = FakeTablesDB(tableData: {});
      final service = BackupService(tablesDB: fakeTablesDB);

      final payload = await service.generateBackup(
        userId: 'user_sem_dados',
        userEmail: 'vazio@exemplo.com',
      );

      expect(payload.summary.totalRecords, equals(0));
      expect(payload.contas, isEmpty);
      expect(payload.transacoes, isEmpty);
      expect(payload.isValidChecksum, isTrue);
    });

    test('downloadBackup formata nome padrão e exporta JSON via fileSaver', () async {
      String? savedContent;
      String? savedFileName;

      final fakeTablesDB = FakeTablesDB(tableData: {});
      final service = BackupService(
        tablesDB: fakeTablesDB,
        fileSaver: (content, fileName) async {
          savedContent = content;
          savedFileName = fileName;
          return '/caminho/fake/$fileName';
        },
      );

      final payload = await service.generateBackup(
        userId: testUserId,
        userEmail: testUserEmail,
      );

      final result = await service.downloadBackup(payload);
      expect(result, equals('/caminho/fake/$savedFileName'));
      expect(savedFileName, startsWith('backup_ppvdigital_'));
      expect(savedFileName, endsWith('.json'));
      expect(savedContent, contains('PPVDigital'));

      // Teste com customFileName
      final customResult = await service.downloadBackup(
        payload,
        customFileName: 'meu_backup_personalizado.json',
      );
      expect(customResult, equals('/caminho/fake/meu_backup_personalizado.json'));
      expect(savedFileName, equals('meu_backup_personalizado.json'));
    });

    test('downloadBackup relança exceção caso o fileSaver falhe', () async {
      final fakeTablesDB = FakeTablesDB(tableData: {});
      final service = BackupService(
        tablesDB: fakeTablesDB,
        fileSaver: (content, fileName) async => throw Exception('Disco cheio'),
      );

      final payload = await service.generateBackup(
        userId: testUserId,
        userEmail: testUserEmail,
      );

      expect(
        () => service.downloadBackup(payload),
        throwsA(isA<Exception>()),
      );
    });
  });
}
