import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ppvdigital/app/capacitacao/financas/widgets/exportar_transacoes_dialog.dart';
import 'package:ppvdigital/models/categoria_transacao_model.dart';
import 'package:ppvdigital/models/conta_model.dart';
import 'package:ppvdigital/models/transacao_model.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
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
    icone: 'restaurant',
    userId: 'u1',
  );

  final t1 = TransacaoModel(
    id: 't1',
    descricao: 'Supermercado',
    valor: 250.50,
    tipo: 'despesa',
    dataCompetencia: DateTime(2026, 9, 11, 10),
    consolidada: true,
    conta: sampleConta,
    categoria: sampleCategoria,
    divisoes: [],
  );

  final t2 = TransacaoModel(
    id: 't2',
    descricao: 'Salário',
    valor: 3500.00,
    tipo: 'receita',
    dataCompetencia: DateTime(2026, 9, 12, 9),
    consolidada: true,
    conta: sampleConta,
    divisoes: [],
  );

  final transactions = [t1, t2];
  final saldosDiarios = {
    '2026-09-11': 749.50,
    '2026-09-12': 4249.50,
  };

  Widget buildTestDialog({String? filterSummary}) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return Center(
              child: ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => ExportarTransacoesDialog(
                      transactions: transactions,
                      saldosDiarios: saldosDiarios,
                      currentMonth: DateTime(2026, 9),
                      filterSummary: filterSummary,
                    ),
                  );
                },
                child: const Text('Abrir Diálogo'),
              ),
            );
          },
        ),
      ),
    );
  }

  testWidgets('Renderiza opções do diálogo de exportação e pré-visualização inicial', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestDialog(filterSummary: 'Nubank | Alimentação'));
    await tester.tap(find.text('Abrir Diálogo'));
    await tester.pumpAndSettle();

    expect(find.text('Exportar Transações'), findsOneWidget);
    expect(find.textContaining('2 transações filtradas'), findsOneWidget);
    expect(find.text('Filtros: Nubank | Alimentação'), findsOneWidget);

    // Seletores de Formato
    expect(find.text('WhatsApp'), findsOneWidget);
    expect(find.text('CSV'), findsOneWidget);

    // Seletores de Estrutura
    expect(find.text('Por data com saldo acumulado'), findsOneWidget);
    expect(find.text('Somente transações com total'), findsOneWidget);

    // Botões de Ação
    expect(find.text('Cancelar'), findsOneWidget);
    expect(find.text('Copiar'), findsOneWidget);
    // Botão de download CSV não deve estar visível no modo WhatsApp inicial
    expect(find.text('Baixar .csv'), findsNothing);

    // Prévia deve conter texto do WhatsApp
    expect(find.textContaining('Relatório de Transações'), findsOneWidget);
    expect(find.textContaining('Supermercado'), findsOneWidget);
  });

  testWidgets('Alterna para CSV e exibe botão de download', (tester) async {
    await tester.pumpWidget(buildTestDialog());
    await tester.tap(find.text('Abrir Diálogo'));
    await tester.pumpAndSettle();

    // Tocar no formato CSV
    await tester.tap(find.text('CSV'));
    await tester.pumpAndSettle();

    // Botão de baixar deve ficar visível
    expect(find.text('Baixar .csv'), findsOneWidget);

    // Prévia deve conter cabeçalho CSV
    expect(find.textContaining('Data;Descrição;Categoria;Conta;Tipo;Status;Valor'), findsOneWidget);
  });

  testWidgets('Alterna estrutura para somente transações com total', (tester) async {
    await tester.pumpWidget(buildTestDialog());
    await tester.tap(find.text('Abrir Diálogo'));
    await tester.pumpAndSettle();

    // Tocar na opção de estrutura linear
    await tester.tap(find.text('Somente transações com total'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Total Geral:'), findsOneWidget);
  });

  testWidgets('Copia conteúdo para a área de transferência', (tester) async {
    String? copiedText;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall methodCall) async {
        if (methodCall.method == 'Clipboard.setData') {
          copiedText = (methodCall.arguments as Map)['text'] as String?;
          return null;
        } else if (methodCall.method == 'Clipboard.getData') {
          return <String, dynamic>{'text': copiedText};
        }
        return null;
      },
    );

    await tester.pumpWidget(buildTestDialog());
    await tester.tap(find.text('Abrir Diálogo'));
    await tester.pumpAndSettle();

    // Tocar no botão copiar
    await tester.tap(find.text('Copiar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // SnackBar de feedback
    expect(find.text('Copiado para a área de transferência!'), findsOneWidget);

    // Verifica que o Clipboard recebeu os dados
    expect(copiedText, isNotNull);
    expect(copiedText, contains('Supermercado'));
  });
}
