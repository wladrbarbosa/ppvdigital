import 'package:flutter_test/flutter_test.dart';
import 'package:ppvdigital/models/conta_model.dart';
import 'package:ppvdigital/models/contato_model.dart';
import 'package:ppvdigital/models/divisao_transacao_model.dart';
import 'package:ppvdigital/models/transacao_model.dart';

void main() {
  group('Regras de Negócio - Módulo de Finanças', () {
    group('1. Cálculo de Divisões de Transações por Contato', () {
      double calcularValorDivisao(TransacaoModel transaction, String contatoId) {
        if (transaction.divisoes.isEmpty) return transaction.valor;
        final double totalPeso = transaction.divisoes.fold(
          0.0,
          (sum, div) => sum + div.peso,
        );
        if (totalPeso <= 0) return 0.0;
        final userDiv = transaction.divisoes.where(
          (div) => div.contatoResponsavel == contatoId,
        );
        if (userDiv.isEmpty) return 0.0;
        final double userPeso = userDiv.first.peso;
        return transaction.valor * (userPeso / totalPeso);
      }

      test('Divisão com pesos proporcionais (2:1)', () {
        final t = TransacaoModel(
          id: 't1',
          descricao: 'Jantar',
          valor: 300.0,
          tipo: 'despesa',
          dataCompetencia: DateTime(2026, 7, 1),
          consolidada: true,
          divisoes: [
            DivisaoTransacaoModel(
              id: 'd1',
              transacaoId: 't1',
              contatoResponsavel: 'userA',
              peso: 2.0,
            ),
            DivisaoTransacaoModel(
              id: 'd2',
              transacaoId: 't1',
              contatoResponsavel: 'userB',
              peso: 1.0,
            ),
          ],
        );

        expect(calcularValorDivisao(t, 'userA'), equals(200.0));
        expect(calcularValorDivisao(t, 'userB'), equals(100.0));
      });

      test('Divisão sem divisões cadastradas retorna valor integral', () {
        final t = TransacaoModel(
          id: 't2',
          descricao: 'Mercado',
          valor: 150.0,
          tipo: 'despesa',
          dataCompetencia: DateTime(2026, 7, 1),
          consolidada: true,
          divisoes: [],
        );

        expect(calcularValorDivisao(t, 'userA'), equals(150.0));
      });

      test('Contato não incluído na divisão retorna valor zero', () {
        final t = TransacaoModel(
          id: 't3',
          descricao: 'Uber',
          valor: 50.0,
          tipo: 'despesa',
          dataCompetencia: DateTime(2026, 7, 1),
          consolidada: true,
          divisoes: [
            DivisaoTransacaoModel(
              id: 'd1',
              transacaoId: 't3',
              contatoResponsavel: 'userA',
              peso: 1.0,
            ),
          ],
        );

        expect(calcularValorDivisao(t, 'userC'), equals(0.0));
      });

      test('Tratamento de peso total igual a zero', () {
        final t = TransacaoModel(
          id: 't4',
          descricao: 'Zero peso',
          valor: 100.0,
          tipo: 'despesa',
          dataCompetencia: DateTime(2026, 7, 1),
          consolidada: true,
          divisoes: [
            DivisaoTransacaoModel(
              id: 'd1',
              transacaoId: 't4',
              contatoResponsavel: 'userA',
              peso: 0.0,
            ),
          ],
        );

        expect(calcularValorDivisao(t, 'userA'), equals(0.0));
      });

      test('Filtro por contato apenas inclui devedor ou credor, ignorando divisões', () {
        final contatoA = ContatoModel(id: 'c1', ownerId: 'u1', nome: 'Contato A');

        final tDevedor = TransacaoModel(
          id: 't1',
          descricao: 'Empréstimo A',
          valor: 100.0,
          tipo: 'despesa',
          dataCompetencia: DateTime(2026, 7, 1),
          consolidada: true,
          devedorContato: contatoA,
          divisoes: [],
        );

        final tDivisaoA = TransacaoModel(
          id: 't2',
          descricao: 'Jantar Dividido',
          valor: 200.0,
          tipo: 'despesa',
          dataCompetencia: DateTime(2026, 7, 1),
          consolidada: true,
          divisoes: [
            DivisaoTransacaoModel(
              id: 'd1',
              transacaoId: 't2',
              contatoResponsavel: 'c1',
              peso: 1.0,
            ),
          ],
        );

        final selectedContatos = {'c1'};

        List<TransacaoModel> filtrarPorContato(
          List<TransacaoModel> list,
          Set<String> selected,
        ) {
          if (selected.isEmpty) return list;
          return list.where((t) {
            final bool isDevedor =
                t.devedorContato != null && selected.contains(t.devedorContato!.id);
            final bool isCredor =
                t.credorContato != null && selected.contains(t.credorContato!.id);
            return isDevedor || isCredor;
          }).toList();
        }

        final result = filtrarPorContato([tDevedor, tDivisaoA], selectedContatos);

        expect(result.length, equals(1));
        expect(result.first.id, equals('t1'));
      });
    });

    group('2. Geração de Datas para Recorrências e Parcelamentos', () {
      List<DateTime> gerarDatasRecorrentes({
        required DateTime dataCompetencia,
        required String tipoRecorrencia,
        required int frequencia,
        required int totalParcelas,
      }) {
        final List<DateTime> dates = [];
        for (int i = 1; i <= totalParcelas; i++) {
          final int factor = i - 1;
          DateTime date = dataCompetencia;
          switch (tipoRecorrencia) {
            case 'dia':
            case 'dias':
              date = dataCompetencia.add(Duration(days: factor * frequencia));
              break;
            case 'semana':
            case 'semanas':
              date = dataCompetencia.add(Duration(days: factor * 7 * frequencia));
              break;
            case 'mês':
            case 'meses':
              date = DateTime(
                dataCompetencia.year,
                dataCompetencia.month + (factor * frequencia),
                dataCompetencia.day,
                dataCompetencia.hour,
                dataCompetencia.minute,
              );
              break;
            case 'ano':
            case 'anos':
              date = DateTime(
                dataCompetencia.year + (factor * frequencia),
                dataCompetencia.month,
                dataCompetencia.day,
                dataCompetencia.hour,
                dataCompetencia.minute,
              );
              break;
          }
          dates.add(date);
        }
        return dates;
      }

      test('Recorrência mensal (3 parcelas)', () {
        final dates = gerarDatasRecorrentes(
          dataCompetencia: DateTime(2026, 1, 15),
          tipoRecorrencia: 'mês',
          frequencia: 1,
          totalParcelas: 3,
        );

        expect(dates.length, equals(3));
        expect(dates[0], equals(DateTime(2026, 1, 15)));
        expect(dates[1], equals(DateTime(2026, 2, 15)));
        expect(dates[2], equals(DateTime(2026, 3, 15)));
      });

      test('Recorrência semanal (2 em 2 semanas)', () {
        final dates = gerarDatasRecorrentes(
          dataCompetencia: DateTime(2026, 7, 1),
          tipoRecorrencia: 'semana',
          frequencia: 2,
          totalParcelas: 3,
        );

        expect(dates.length, equals(3));
        expect(dates[0], equals(DateTime(2026, 7, 1)));
        expect(dates[1], equals(DateTime(2026, 7, 15)));
        expect(dates[2], equals(DateTime(2026, 7, 29)));
      });

      test('Recorrência anual (frequência 1)', () {
        final dates = gerarDatasRecorrentes(
          dataCompetencia: DateTime(2026, 5, 10),
          tipoRecorrencia: 'ano',
          frequencia: 1,
          totalParcelas: 2,
        );

        expect(dates[0], equals(DateTime(2026, 5, 10)));
        expect(dates[1], equals(DateTime(2027, 5, 10)));
      });
    });

    group('3. Cálculo de Resumo Financeiro Mensal', () {
      final contaCorrente = ContaModel(
        id: 'c1',
        name: 'Conta Corrente',
        userId: 'user1',
        saldoAtual: 1000.0,
      );

      final contaPoupanca = ContaModel(
        id: 'c2',
        name: 'Poupança',
        userId: 'user1',
        saldoAtual: 500.0,
      );

      final transacoesMock = [
        // Mês anterior (Junho 2026)
        TransacaoModel(
          id: 't_past_1',
          descricao: 'Salário Junho',
          valor: 5000.0,
          tipo: 'receita',
          dataCompetencia: DateTime(2026, 6, 5),
          conta: contaCorrente,
          consolidada: true,
          divisoes: [],
        ),
        TransacaoModel(
          id: 't_past_2',
          descricao: 'Aluguel Junho',
          valor: 2000.0,
          tipo: 'despesa',
          dataCompetencia: DateTime(2026, 6, 10),
          conta: contaCorrente,
          consolidada: true,
          divisoes: [],
        ),
        // Mês atual (Julho 2026)
        TransacaoModel(
          id: 't_curr_1',
          descricao: 'Salário Julho',
          valor: 5000.0,
          tipo: 'receita',
          dataCompetencia: DateTime(2026, 7, 5),
          conta: contaCorrente,
          consolidada: true,
          divisoes: [],
        ),
        TransacaoModel(
          id: 't_curr_2',
          descricao: 'Aluguel Julho',
          valor: 2000.0,
          tipo: 'despesa',
          dataCompetencia: DateTime(2026, 7, 10),
          conta: contaCorrente,
          consolidada: true,
          divisoes: [],
        ),
        TransacaoModel(
          id: 't_curr_3',
          descricao: 'Restaurante Pendente',
          valor: 150.0,
          tipo: 'despesa',
          dataCompetencia: DateTime(2026, 7, 20),
          conta: contaCorrente,
          consolidada: false, // Pendente
          divisoes: [],
        ),
        TransacaoModel(
          id: 't_curr_4',
          descricao: 'Reserva Poupança',
          valor: 500.0,
          tipo: 'transferencia',
          dataCompetencia: DateTime(2026, 7, 15),
          conta: contaCorrente,
          contaDestino: contaPoupanca,
          consolidada: true,
          divisoes: [],
        ),
      ];

      test('Cálculo do Saldo Anterior (antes de Julho 2026)', () {
        final inicioMes = DateTime(2026, 7, 1);
        final transacoesPassadas = transacoesMock.where(
          (t) => t.dataCompetencia.isBefore(inicioMes) && t.consolidada,
        );

        double saldoAnterior = 0.0;
        for (final t in transacoesPassadas) {
          if (t.tipo == 'receita') saldoAnterior += t.valor;
          if (t.tipo == 'despesa') saldoAnterior -= t.valor;
        }

        expect(saldoAnterior, equals(3000.0)); // 5000 - 2000
      });

      test('Cálculo de Receita e Despesa do Mês de Julho 2026', () {
        final inicioMes = DateTime(2026, 7, 1);
        final fimMes = DateTime(2026, 7, 31, 23, 59, 59);

        final transacoesMes = transacoesMock.where(
          (t) =>
              !t.dataCompetencia.isBefore(inicioMes) &&
              !t.dataCompetencia.isAfter(fimMes),
        );

        double receitaMes = 0.0;
        double despesaMes = 0.0;

        for (final t in transacoesMes) {
          if (t.tipo == 'receita') receitaMes += t.valor;
          if (t.tipo == 'despesa') despesaMes += t.valor;
        }

        expect(receitaMes, equals(5000.0));
        expect(despesaMes, equals(2150.0)); // 2000 (consolidada) + 150 (pendente)
      });

      test('Transferência ajusta contas individuais mas mantém saldo total neutro', () {
        double saldoOrigem = 1000.0;
        double saldoDestino = 500.0;

        final tTransferencia = transacoesMock.firstWhere(
          (t) => t.tipo == 'transferencia',
        );

        saldoOrigem -= tTransferencia.valor;
        saldoDestino += tTransferencia.valor;

        expect(saldoOrigem, equals(500.0));
        expect(saldoDestino, equals(1000.0));
        expect(saldoOrigem + saldoDestino, equals(1500.0)); // Neutro no total
      });
    });

    group('4. Operações em Massa e Tolerância a Erros', () {
      test('Execução de fallback em lote continua quando um item individual falha', () {
        final List<String> executedOps = [];
        final List<Map<String, dynamic>> ops = [
          {'id': 'op1', 'action': 'update', 'shouldFail': false},
          {'id': 'op2', 'action': 'update', 'shouldFail': true},
          {'id': 'op3', 'action': 'update', 'shouldFail': false},
        ];

        for (final op in ops) {
          try {
            if (op['shouldFail'] == true) {
              throw Exception('Simulated row error for ${op['id']}');
            }
            executedOps.add(op['id'] as String);
          } catch (e) {
            // Isolamento de erro por linha no fallback
          }
        }

        expect(executedOps, equals(['op1', 'op3']));
      });

      test('Filtro de ID de recorrencia vazio evita chamadas de série desnecessárias', () {
        final tSemRecorrencia = TransacaoModel(
          id: 't_no_rec',
          descricao: 'Sem Recorrência',
          valor: 100.0,
          tipo: 'despesa',
          dataCompetencia: DateTime(2026, 7, 1),
          consolidada: false,
          divisoes: [],
        );

        bool recIdValido(TransacaoModel t) {
          return t.recorrencia != null && t.recorrencia!.id.isNotEmpty;
        }

        expect(recIdValido(tSemRecorrencia), isFalse);
      });
    });
  });
}
