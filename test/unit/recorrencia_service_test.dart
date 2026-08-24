import 'package:flutter_test/flutter_test.dart';
import 'package:ppvdigital/app/capacitacao/financas/services/recorrencia_service.dart';

void main() {
  group('RecorrenciaService Unit Tests', () {
    final baseDate = DateTime(2026, 1, 15, 10, 30);

    test('calcularDataParcela returns baseDate for step 0', () {
      final date = RecorrenciaService.calcularDataParcela(
        dataBase: baseDate,
        tipoRecorrencia: 'mês',
        frequencia: 1,
        stepIndex: 0,
      );
      expect(date, equals(baseDate));
    });

    test('calcularDataParcela for daily recurrence with frequency', () {
      final date1 = RecorrenciaService.calcularDataParcela(
        dataBase: baseDate,
        tipoRecorrencia: 'dia',
        frequencia: 1,
        stepIndex: 5,
      );
      expect(date1, equals(baseDate.add(const Duration(days: 5))));

      final date2 = RecorrenciaService.calcularDataParcela(
        dataBase: baseDate,
        tipoRecorrencia: 'dia',
        frequencia: 2,
        stepIndex: 3,
      );
      expect(date2, equals(baseDate.add(const Duration(days: 6))));
    });

    test('calcularDataParcela for weekly recurrence', () {
      final date = RecorrenciaService.calcularDataParcela(
        dataBase: baseDate,
        tipoRecorrencia: 'semana',
        frequencia: 1,
        stepIndex: 2,
      );
      expect(date, equals(baseDate.add(const Duration(days: 14))));
    });

    test('calcularDataParcela for monthly recurrence', () {
      final date = RecorrenciaService.calcularDataParcela(
        dataBase: baseDate,
        tipoRecorrencia: 'mês',
        frequencia: 2,
        stepIndex: 3,
      );
      expect(date.year, 2026);
      expect(date.month, 7); // Jan + 6 months = July
      expect(date.day, 15);
    });

    test('calcularDataParcela for yearly recurrence', () {
      final date = RecorrenciaService.calcularDataParcela(
        dataBase: baseDate,
        tipoRecorrencia: 'ano',
        frequencia: 1,
        stepIndex: 4,
      );
      expect(date.year, 2030);
      expect(date.month, 1);
      expect(date.day, 15);
    });

    test('formatarDescricaoParcela handles finite and indeterminate recurrence', () {
      final descFinite = RecorrenciaService.formatarDescricaoParcela(
        descricaoBase: 'Internet',
        recorrente: true,
        parcelaAtual: 3,
        totalParcelas: 12,
      );
      expect(descFinite, 'Internet (Parcela 3/12)');

      final descIndet = RecorrenciaService.formatarDescricaoParcela(
        descricaoBase: 'Internet',
        recorrente: true,
        recorrenciaIndeterminada: true,
        totalParcelas: 12,
      );
      expect(descIndet, 'Internet');

      final descNonRec = RecorrenciaService.formatarDescricaoParcela(
        descricaoBase: 'Almoço',
      );
      expect(descNonRec, 'Almoço');
    });

    test('gerarParcelas generates finite series of parcels', () {
      final parcelas = RecorrenciaService.gerarParcelas(
        descricao: 'Notebook',
        dataCompetencia: DateTime(2026, 3, 10),
        recorrente: true,
        tipoRecorrencia: 'mês',
        totalParcelas: 3,
      );

      expect(parcelas.length, 3);
      expect(parcelas[0].descricao, 'Notebook (Parcela 1/3)');
      expect(parcelas[0].dataCompetencia, DateTime(2026, 3, 10));
      expect(parcelas[1].descricao, 'Notebook (Parcela 2/3)');
      expect(parcelas[1].dataCompetencia, DateTime(2026, 4, 10));
      expect(parcelas[2].descricao, 'Notebook (Parcela 3/3)');
      expect(parcelas[2].dataCompetencia, DateTime(2026, 5, 10));
    });

    test('gerarParcelas generates 24 installments for indeterminate recurrence', () {
      final parcelas = RecorrenciaService.gerarParcelas(
        descricao: 'Aluguel',
        dataCompetencia: DateTime(2026),
        recorrente: true,
        recorrenciaIndeterminada: true,
        tipoRecorrencia: 'mês',
      );

      expect(parcelas.length, 24);
      expect(parcelas.first.descricao, 'Aluguel');
      expect(parcelas.last.descricao, 'Aluguel');
      expect(parcelas.last.dataCompetencia.year, 2027);
      expect(parcelas.last.dataCompetencia.month, 12);
    });
  });
}
