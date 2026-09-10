import 'package:flutter_test/flutter_test.dart';
import 'package:ppvdigital/models/historico_item_model.dart';
import 'package:ppvdigital/models/tarefas_habitos_model.dart';

void main() {
  group('HistoricoItemModel', () {
    final mockTarefa = TarefaHabitoModel(
      id: 'task-1',
      nome: 'Leitura diária',
      tipo: 'habito',
      usuario: 'user-1',
      concluida: false,
      agendamento: null,
      tarefasHabitosQtd: [],
    );

    test('parses fromMap when dataCriacao is an integer (milliseconds)', () {
      final now = DateTime(2026, 9, 10, 15, 30);
      final map = {
        'id': 'hist-1',
        'usuario': 'user-1',
        'tarefasEHabitos': mockTarefa.toMap(),
        'dataCriacao': now.millisecondsSinceEpoch,
      };

      final model = HistoricoItemModel.fromMap(map);
      expect(model.id, 'hist-1');
      expect(model.usuario, 'user-1');
      expect(model.createdAt.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
    });

    test('parses fromMap when dataCriacao is an ISO string', () {
      final now = DateTime.utc(2026, 9, 10, 15, 30);
      final map = {
        'id': 'hist-2',
        'usuario': 'user-1',
        'tarefasEHabitos': mockTarefa.toMap(),
        'dataCriacao': now.toIso8601String(),
      };

      final model = HistoricoItemModel.fromMap(map);
      expect(model.id, 'hist-2');
      expect(model.createdAt.toUtc(), now);
    });

    test('parses fromMap when dataCriacao is null and fallback createdAt is provided', () {
      final now = DateTime(2026, 9, 10, 15, 30);
      final map = {
        'id': 'hist-3',
        'usuario': 'user-1',
        'tarefasEHabitos': mockTarefa.toMap(),
        'createdAt': now.millisecondsSinceEpoch,
      };

      final model = HistoricoItemModel.fromMap(map);
      expect(model.id, 'hist-3');
      expect(model.createdAt.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
    });

    test('toMap and copyWith preserve data correctly', () {
      final now = DateTime(2026, 9, 10, 15, 30);
      final original = HistoricoItemModel(
        id: 'hist-1',
        usuario: 'user-1',
        tarefasEHabitos: mockTarefa,
        createdAt: now,
      );

      final updated = original.copyWith(createdAt: DateTime(2026, 9, 11, 10));
      expect(updated.createdAt, DateTime(2026, 9, 11, 10));
      expect(updated.id, original.id);

      final map = original.toMap();
      expect(map['id'], 'hist-1');
      expect(map['createdAt'], now.millisecondsSinceEpoch);
    });
  });
}
