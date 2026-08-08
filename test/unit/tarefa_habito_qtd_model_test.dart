import 'package:flutter_test/flutter_test.dart';
import 'package:ppvdigital/models/tarefas_habitos_qtd_model.dart';

void main() {
  group('TarefaHabitoQtdModel Cycle Reset Calculations', () {
    test('Daily cycle reset always starts at 00:00:00 of reference day', () {
      final created = DateTime(2026, 8, 4, 15, 30, 45); // Tuesday afternoon
      final ref = DateTime(2026, 8, 4, 23, 59, 59);

      final start = TarefaHabitoQtdModel.calculateStartPeriod(
        createdAt: created,
        reiniciaEmQtd: 1,
        reiniciaEmTipo: 'dias',
        referenceDate: ref,
      );

      final end = TarefaHabitoQtdModel.calculateEndPeriod(start, 'dias', 1);

      expect(start, equals(DateTime(2026, 8, 4)));
      expect(end, equals(DateTime(2026, 8, 5)));

      // Next day at 00:00:01
      final nextDayRef = DateTime(2026, 8, 5, 0, 0, 1);
      final nextStart = TarefaHabitoQtdModel.calculateStartPeriod(
        createdAt: created,
        reiniciaEmQtd: 1,
        reiniciaEmTipo: 'dias',
        referenceDate: nextDayRef,
      );

      expect(nextStart, equals(DateTime(2026, 8, 5)));
    });

    test('Weekly cycle reset always starts at 00:00:00 of Monday', () {
      final created = DateTime(2026, 8, 1, 10); // Saturday
      // Reference date: Tuesday Aug 4, 2026
      final refTuesday = DateTime(2026, 8, 4, 14, 20);

      final start = TarefaHabitoQtdModel.calculateStartPeriod(
        createdAt: created,
        reiniciaEmQtd: 1,
        reiniciaEmTipo: 'semanas',
        referenceDate: refTuesday,
      );

      final end = TarefaHabitoQtdModel.calculateEndPeriod(start, 'semanas', 1);

      // Monday of that week was Monday Aug 3, 2026
      expect(start, equals(DateTime(2026, 8, 3)));
      expect(end, equals(DateTime(2026, 8, 10)));
    });

    test('Monthly cycle reset always starts at 00:00:00 on 1st of month', () {
      final created = DateTime(2026, 1, 15, 12);
      final refMidMonth = DateTime(2026, 8, 18, 19);

      final start = TarefaHabitoQtdModel.calculateStartPeriod(
        createdAt: created,
        reiniciaEmQtd: 1,
        reiniciaEmTipo: 'meses',
        referenceDate: refMidMonth,
      );

      final end = TarefaHabitoQtdModel.calculateEndPeriod(start, 'meses', 1);

      expect(start, equals(DateTime(2026, 8)));
      expect(end, equals(DateTime(2026, 9)));
    });

    test('Yearly cycle reset always starts at 00:00:00 on Jan 1st', () {
      final created = DateTime(2024, 5, 20, 8);
      final refDate = DateTime(2026, 8, 4, 14, 30);

      final start = TarefaHabitoQtdModel.calculateStartPeriod(
        createdAt: created,
        reiniciaEmQtd: 1,
        reiniciaEmTipo: 'anos',
        referenceDate: refDate,
      );

      final end = TarefaHabitoQtdModel.calculateEndPeriod(start, 'anos', 1);

      expect(start, equals(DateTime(2026)));
      expect(end, equals(DateTime(2027)));
    });
  });
}
