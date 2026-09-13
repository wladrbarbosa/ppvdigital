import 'package:flutter_test/flutter_test.dart';
import 'package:ppvdigital/models/backup/backup_payload_model.dart';

void main() {
  group('BackupSummary Tests', () {
    test('Calcula totalRecords e serializa corretamente', () {
      const summary = BackupSummary(
        contas: 2,
        contatos: 5,
        categoriasTransacoes: 8,
        categoriasTarefasHabitos: 3,
        tarefasHabitosQtds: 6,
        transacaoRecorrencias: 1,
        tarefasEHabitos: 10,
        transacoes: 50,
        divisaoTransacoes: 4,
        historicoTarefasHabitos: 100,
      );

      expect(summary.totalRecords, equals(189));

      final map = summary.toMap();
      expect(map['contas'], equals(2));
      expect(map['totalRecords'], equals(189));

      final deserialized = BackupSummary.fromMap(map);
      expect(deserialized.totalRecords, equals(189));
      expect(deserialized.transacoes, equals(50));
      expect(deserialized.historicoTarefasHabitos, equals(100));
    });

    test('Lida com mapa vazio ou valores nulos com defaults zerados', () {
      final summary = BackupSummary.fromMap({});
      expect(summary.totalRecords, equals(0));
      expect(summary.contas, equals(0));
    });
  });

  group('BackupPayloadModel Tests', () {
    final now = DateTime.now();
    final pastDate = DateTime(2023, 5, 10);
    final futureDate = DateTime(2028, 11, 25);

    Map<String, List<Map<String, dynamic>>> createSampleData() {
      return {
        'contas': [
          {
            r'$id': 'acc_1',
            'name': 'Conta Corrente',
            'saldoAtual': 1500.50,
            'userId': 'user_123',
          }
        ],
        'contatos': [
          {
            r'$id': 'contact_1',
            'nome': 'João Silva',
            'ownerId': 'user_123',
          }
        ],
        'categoriasTransacoes': [
          {
            r'$id': 'cat_fin_1',
            'nome': 'Alimentação',
            'corHex': '#FF5733',
            'userId': 'user_123',
          }
        ],
        'categoriasTarefasHabitos': [
          {
            r'$id': 'cat_th_1',
            'nome': 'Saúde',
            'corHex': '#33FF57',
            'usuario': 'user_123',
          }
        ],
        'tarefasHabitosQtds': [
          {
            r'$id': 'qtd_1',
            'metaVezes': 3,
            'valor': 'Exercício',
            'usuario': 'user_123',
          }
        ],
        'transacaoRecorrencias': [
          {
            r'$id': 'rec_1',
            'tipoRecorrencia': 'mensal',
            'frequencia': 1,
          }
        ],
        'tarefasEHabitos': [
          {
            r'$id': 'task_1',
            'nome': 'Correr no parque',
            'tipo': 'habito',
            'usuario': 'user_123',
            'agendamento': futureDate.toIso8601String(),
          }
        ],
        'transacoes': [
          {
            r'$id': 'tx_past',
            'descricao': 'Compra Supermercado 2023',
            'valor': 250.0,
            'tipo': 'despesa',
            'dataCompetencia': pastDate.toIso8601String(),
            'consolidada': true,
            'conta': 'acc_1',
          },
          {
            r'$id': 'tx_current',
            'descricao': 'Salário Mês Atual',
            'valor': 5000.0,
            'tipo': 'receita',
            'dataCompetencia': now.toIso8601String(),
            'consolidada': true,
            'conta': 'acc_1',
          },
          {
            r'$id': 'tx_future',
            'descricao': 'Parcela 12/12 Carro 2028',
            'valor': 890.0,
            'tipo': 'despesa',
            'dataCompetencia': futureDate.toIso8601String(),
            'consolidada': false,
            'conta': 'acc_1',
          },
        ],
        'divisaoTransacoes': [
          {
            r'$id': 'div_1',
            'descricao': 'Subitem mercado',
            'valor': 50.0,
            'transacao': 'tx_past',
          }
        ],
        'historicoTarefasHabitos': [
          {
            r'$id': 'hist_1',
            'tarefasEHabitos': 'task_1',
            'usuario': 'user_123',
          }
        ],
      };
    }

    test('Serialização e deserialização preservam metadados e as 10 coleções', () {
      final sampleData = createSampleData();
      final model = BackupPayloadModel(
        exportedAt: now,
        userId: 'user_123',
        userEmail: 'teste@exemplo.com',
        data: sampleData,
      );

      expect(model.version, equals(1));
      expect(model.app, equals('PPVDigital'));
      expect(model.userId, equals('user_123'));
      expect(model.userEmail, equals('teste@exemplo.com'));
      expect(model.contas.length, equals(1));
      expect(model.transacoes.length, equals(3));
      expect(model.summary.totalRecords, equals(12));

      final jsonStr = model.toJson();
      final fromJson = BackupPayloadModel.fromJson(jsonStr);

      expect(fromJson.version, equals(model.version));
      expect(fromJson.userId, equals(model.userId));
      expect(fromJson.userEmail, equals(model.userEmail));
      expect(fromJson.summary.totalRecords, equals(12));
      expect(fromJson.transacoes.length, equals(3));
    });

    test('Garante cobertura temporal irrestrita (passado, presente e futuro)', () {
      final sampleData = createSampleData();
      final model = BackupPayloadModel(
        exportedAt: now,
        userId: 'user_123',
        userEmail: 'teste@exemplo.com',
        data: sampleData,
      );

      final pastTx = model.transacoes.firstWhere((t) => t[r'$id'] == 'tx_past');
      final futureTx =
          model.transacoes.firstWhere((t) => t[r'$id'] == 'tx_future');

      expect(pastTx['dataCompetencia'], equals(pastDate.toIso8601String()));
      expect(pastTx['consolidada'], isTrue);

      expect(futureTx['dataCompetencia'], equals(futureDate.toIso8601String()));
      expect(futureTx['consolidada'], isFalse);

      final jsonStr = model.toJson();
      final reloaded = BackupPayloadModel.fromJson(jsonStr);

      final reloadedFutureTx =
          reloaded.transacoes.firstWhere((t) => t[r'$id'] == 'tx_future');
      expect(reloadedFutureTx['descricao'], equals('Parcela 12/12 Carro 2028'));
      expect(
          reloadedFutureTx['dataCompetencia'], equals(futureDate.toIso8601String()));
    });

    test('Checksum SHA-256 é válido e detecta adulteração de dados', () {
      final sampleData = createSampleData();
      final model = BackupPayloadModel(
        exportedAt: now,
        userId: 'user_123',
        userEmail: 'teste@exemplo.com',
        data: sampleData,
      );

      expect(model.isValidChecksum, isTrue);
      expect(model.checksum.startsWith('sha256:'), isTrue);

      // Criando uma cópia com dado adulterado
      final tamperedData = Map<String, List<Map<String, dynamic>>>.from(sampleData);
      tamperedData['contas'] = [
        {
          r'$id': 'acc_1',
          'name': 'Conta Fraude',
          'saldoAtual': 9999999.0,
          'userId': 'user_123',
        }
      ];

      final tamperedModel = BackupPayloadModel(
        exportedAt: now,
        userId: 'user_123',
        userEmail: 'teste@exemplo.com',
        data: tamperedData,
        checksum: model.checksum, // Checksum original para dados alterados
      );

      expect(tamperedModel.isValidChecksum, isFalse);
    });

    test('Lança FormatException quando o JSON é inválido ou malformado', () {
      expect(
        () => BackupPayloadModel.fromJson('not a json'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => BackupPayloadModel.fromJson('["array", "invalido"]'),
        throwsA(isA<FormatException>()),
      );
    });

    test('Getters de coleções e toJson pretty funcionam corretamente', () {
      final sampleData = createSampleData();
      final model = BackupPayloadModel(
        exportedAt: now,
        userId: 'user_123',
        userEmail: 'teste@exemplo.com',
        data: sampleData,
      );

      expect(model.contas.length, equals(1));
      expect(model.contatos.length, equals(1));
      expect(model.categoriasTransacoes.length, equals(1));
      expect(model.categoriasTarefasHabitos.length, equals(1));
      expect(model.tarefasHabitosQtds.length, equals(1));
      expect(model.transacaoRecorrencias.length, equals(1));
      expect(model.tarefasEHabitos.length, equals(1));
      expect(model.transacoes.length, equals(3));
      expect(model.divisaoTransacoes.length, equals(1));
      expect(model.historicoTarefasHabitos.length, equals(1));

      final prettyJson = model.toJson(pretty: true);
      expect(prettyJson, contains('\n'));
      expect(prettyJson, contains('PPVDigital'));
    });

    test('Modelo lida com mapa sem dados ou coleções ausentes com listas vazias', () {
      final emptyModel = BackupPayloadModel(
        exportedAt: now,
        userId: 'user_empty',
        userEmail: 'empty@exemplo.com',
        data: {},
      );

      expect(emptyModel.contas, isEmpty);
      expect(emptyModel.contatos, isEmpty);
      expect(emptyModel.categoriasTransacoes, isEmpty);
      expect(emptyModel.categoriasTarefasHabitos, isEmpty);
      expect(emptyModel.tarefasHabitosQtds, isEmpty);
      expect(emptyModel.transacaoRecorrencias, isEmpty);
      expect(emptyModel.tarefasEHabitos, isEmpty);
      expect(emptyModel.transacoes, isEmpty);
      expect(emptyModel.divisaoTransacoes, isEmpty);
      expect(emptyModel.historicoTarefasHabitos, isEmpty);
      expect(emptyModel.summary.totalRecords, equals(0));
    });

    test('fromMap usa DateTime.now() quando exportedAt é ausente ou inválido', () {
      final model = BackupPayloadModel.fromMap({
        'exportedAt': 'data_invalida',
        'userId': 'user_fallback',
      });
      expect(model.userId, equals('user_fallback'));
      expect(model.exportedAt, isNotNull);
    });
  });
}
