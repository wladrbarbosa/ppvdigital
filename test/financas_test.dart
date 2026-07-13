import 'package:flutter_test/flutter_test.dart';
import 'package:ppvdigital/models/divisao_transacao_model.dart';
import 'package:ppvdigital/models/transacao_model.dart';

void main() {
  group('Financas Unit Tests', () {
    test('Calculo de Divisao por Pesos', () {
      final t = TransacaoModel(
        id: 't1',
        descricao: 'Aluguel Compartilhado',
        valor: 1500.0,
        tipo: 'despesa',
        dataCompetencia: DateTime(2026, 6, 28),
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

      // Total weight is 2.0 + 1.0 = 3.0
      // userA weight is 2.0, so share is 2/3 of 1500 = 1000
      // userB weight is 1.0, so share is 1/3 of 1500 = 500

      double calcularValorDivisao(
        TransacaoModel transaction,
        String contatoId,
      ) {
        if (transaction.divisoes.isEmpty) return transaction.valor;
        final double totalPeso = transaction.divisoes.fold(
          0.0,
          (sum, div) => sum + div.peso,
        );
        final userDiv = transaction.divisoes.where(
          (div) => div.contatoResponsavel == contatoId,
        );
        if (userDiv.isEmpty) return 0.0;
        final double userPeso = userDiv.first.peso;
        return transaction.valor * (userPeso / totalPeso);
      }

      expect(calcularValorDivisao(t, 'userA'), equals(1000.0));
      expect(calcularValorDivisao(t, 'userB'), equals(500.0));
      expect(calcularValorDivisao(t, 'userC'), equals(0.0));
    });

    test('Geracao de Datas Recorrentes', () {
      final DateTime dataCompetencia = DateTime(2026, 1, 10);
      const String tipoRecorrencia = 'mês';
      const int frequencia = 1;
      const int totalParcelas = 3;

      final List<DateTime> dates = [];
      for (int i = 1; i <= totalParcelas; i++) {
        DateTime date = dataCompetencia;
        if (tipoRecorrencia == 'mês') {
          date = DateTime(
            dataCompetencia.year,
            dataCompetencia.month + (i - 1) * frequencia,
            dataCompetencia.day,
            dataCompetencia.hour,
            dataCompetencia.minute,
          );
        }
        dates.add(date);
      }

      expect(dates.length, equals(3));
      expect(dates[0], equals(DateTime(2026, 1, 10)));
      expect(dates[1], equals(DateTime(2026, 2, 10)));
      expect(dates[2], equals(DateTime(2026, 3, 10)));
    });
  });
}
