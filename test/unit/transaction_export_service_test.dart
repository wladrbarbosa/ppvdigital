import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ppvdigital/app/capacitacao/financas/services/transaction_export_service.dart';
import 'package:ppvdigital/models/categoria_transacao_model.dart';
import 'package:ppvdigital/models/conta_model.dart';
import 'package:ppvdigital/models/transacao_model.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR', null);
  });

  final sampleConta = ContaModel(
    id: 'c1',
    name: 'Nubank',
    saldoAtual: 1000.0,
    userId: 'u1',
  );

  final sampleCategoria = CategoriaTransacaoModel(
    id: 'cat1',
    name: 'Alimentação',
    cor: null,
    icone: 'restaurant',
    userId: 'u1',
  );

  final t1 = TransacaoModel(
    id: 't1',
    descricao: 'Supermercado',
    valor: 250.50,
    tipo: 'despesa',
    dataCompetencia: DateTime(2026, 9, 11, 10, 0),
    consolidada: true,
    conta: sampleConta,
    categoria: sampleCategoria,
    divisoes: [],
  );

  final t2 = TransacaoModel(
    id: 't2',
    descricao: 'Farmácia; Central',
    valor: 85.00,
    tipo: 'despesa',
    dataCompetencia: DateTime(2026, 9, 11, 15, 30),
    consolidada: true,
    conta: sampleConta,
    divisoes: [],
  );

  final t3 = TransacaoModel(
    id: 't3',
    descricao: 'Salário "Mensal"',
    valor: 3500.00,
    tipo: 'receita',
    dataCompetencia: DateTime(2026, 9, 12, 9, 0),
    consolidada: true,
    conta: sampleConta,
    divisoes: [],
  );

  final t4 = TransacaoModel(
    id: 't4',
    descricao: 'Reserva',
    valor: 300.00,
    tipo: 'transferencia',
    dataCompetencia: DateTime(2026, 9, 12, 14, 0),
    consolidada: true,
    conta: sampleConta,
    contaDestino: ContaModel(
      id: 'c2',
      name: 'Poupança',
      saldoAtual: 500.0,
      userId: 'u1',
    ),
    divisoes: [],
  );

  group('TransactionExportService - WhatsApp Format', () {
    test('formatWhatsApp com agrupamento por data e saldo acumulado', () {
      final saldosDiarios = {
        '2026-09-11': 1664.50,
        '2026-09-12': 4864.50,
      };

      final result = TransactionExportService.formatWhatsApp(
        transactions: [t1, t2, t3, t4],
        groupByDateWithBalance: true,
        saldosDiarios: saldosDiarios,
        currentMonth: DateTime(2026, 9, 1),
        filterSummary: 'Nubank | Alimentação',
      );

      expect(result, contains('Relatório de Transações'));
      expect(result, contains('Setembro'));
      expect(result, contains('Filtros: Nubank | Alimentação'));
      expect(result, contains('11/09/2026'));
      expect(result, contains('12/09/2026'));
      expect(result, contains('Supermercado'));
      expect(result, contains('🔴'));
      expect(result, contains('🟢'));
      expect(result, contains('🔵'));
      expect(result, contains('💰 *Saldo acumulado do dia:* R\$ 1.664,50'));
      expect(result, contains('💰 *Saldo acumulado do dia:* R\$ 4.864,50'));
      expect(result, contains('• Total Receitas: R\$ 3.500,00'));
      expect(result, contains('• Total Despesas: R\$ 335,50'));
      expect(result, contains('• *Saldo Líquido:* R\$ 3.164,50'));
    });

    test('formatWhatsApp linear (somente transações com total)', () {
      final result = TransactionExportService.formatWhatsApp(
        transactions: [t1, t3],
        groupByDateWithBalance: false,
        currentMonth: DateTime(2026, 9, 1),
      );

      expect(result, contains('Relatório de Transações'));
      expect(result, contains('11/09'));
      expect(result, contains('Supermercado'));
      expect(result, contains('12/09'));
      expect(result, contains('Salário "Mensal"'));
      expect(result, contains('• Receitas: R\$ 3.500,00'));
      expect(result, contains('• Despesas: R\$ 250,50'));
      expect(result, contains('• *Saldo:* R\$ 3.249,50'));
      expect(result, contains('2 transações'));
    });

    test('formatWhatsApp com lista vazia de transações', () {
      final result = TransactionExportService.formatWhatsApp(
        transactions: [],
        groupByDateWithBalance: true,
        currentMonth: DateTime(2026, 9, 1),
      );

      expect(result, contains('Nenhuma transação encontrada'));
    });
  });

  group('TransactionExportService - CSV Format', () {
    test('formatCsv com agrupamento por data e saldo acumulado', () {
      final saldosDiarios = {
        '2026-09-11': 1664.50,
        '2026-09-12': 4864.50,
      };

      final csv = TransactionExportService.formatCsv(
        transactions: [t1, t2, t3],
        groupByDateWithBalance: true,
        saldosDiarios: saldosDiarios,
        currentMonth: DateTime(2026, 9, 1),
      );

      // Deve começar com BOM UTF-8
      expect(csv.startsWith('\uFEFF'), isTrue);

      // Cabeçalho esperado
      expect(
        csv,
        contains('Data;Descrição;Categoria;Conta;Tipo;Status;Valor;Saldo Acumulado'),
      );

      // Linhas com valores
      expect(csv, contains('11/09/2026;Supermercado;Alimentação;Nubank;Despesa;Consolidada;-250,50;1.664,50'));
      // Verificação de escaping de ponto e vírgula na descrição
      expect(csv, contains('"Farmácia; Central"'));

      // Linhas de total
      expect(csv, contains('TOTAL RECEITAS;;;;;;3.500,00;'));
      expect(csv, contains('TOTAL DESPESAS;;;;;;-335,50;'));
      expect(csv, contains('SALDO LÍQUIDO;;;;;;3.164,50;'));
    });

    test('formatCsv linear sem coluna de saldo acumulado', () {
      final csv = TransactionExportService.formatCsv(
        transactions: [t1, t3],
        groupByDateWithBalance: false,
        currentMonth: DateTime(2026, 9, 1),
      );

      expect(csv.startsWith('\uFEFF'), isTrue);
      expect(
        csv,
        contains('Data;Descrição;Categoria;Conta;Tipo;Status;Valor\n'),
      );
      expect(csv, contains('11/09/2026;Supermercado;Alimentação;Nubank;Despesa;Consolidada;-250,50'));
      // Verificação de escaping de aspas
      expect(csv, contains('"Salário ""Mensal"""'));
      expect(csv, contains('TOTAL RECEITAS;;;;;;3.500,00'));
    });

    test('formatCsv com lista vazia', () {
      final csv = TransactionExportService.formatCsv(
        transactions: [],
        groupByDateWithBalance: false,
        currentMonth: DateTime(2026, 9, 1),
      );

      expect(csv.startsWith('\uFEFF'), isTrue);
      expect(csv, contains('Data;Descrição;Categoria;Conta;Tipo;Status;Valor'));
      expect(csv, contains('Nenhuma transação encontrada'));
    });
  });

  group('TransactionExportService - File Download', () {
    test('downloadCsvFile salva arquivo com sucesso', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (MethodCall methodCall) async => '.',
      );

      final path = await TransactionExportService.downloadCsvFile(
        csvContent: 'Data;Valor\n11/09/2026;100,00',
        fileName: 'test_export.csv',
      );

      expect(path, isNotNull);
      expect(path, contains('test_export.csv'));
    });
  });
}
