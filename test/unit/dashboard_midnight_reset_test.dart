import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppvdigital/app/capacitacao/tarefas_habitos/dashboard_logic.dart';
import 'package:ppvdigital/models/categorias_tarefas_habitos_model.dart';
import 'package:ppvdigital/models/historico_item_model.dart';
import 'package:ppvdigital/models/local/app_database.dart';
import 'package:ppvdigital/models/tarefas_habitos_model.dart';
import 'package:ppvdigital/models/tarefas_habitos_qtd_model.dart';
import 'package:ppvdigital/repositories/drift_tarefa_habito_repository.dart';
import 'package:ppvdigital/repositories/tarefa_habito_repository.dart';

class FakeRemoteTarefaHabitoRepository implements TarefaHabitoRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Dashboard Midnight Reset & Empty Today History Tests', () {
    final catSaude = CategoriasTarefasHabitosModel(
      id: 'cat1',
      nome: 'Saúde',
      cor: Colors.green,
      usuario: 'user1',
    );

    final habit1 = TarefaHabitoModel(
      id: 'h1',
      nome: 'Beber Água',
      tipo: 'habito',
      usuario: 'user1',
      concluida: false,
      agendamento: null,
      duration: 15,
      tarefasHabitosQtd: [
        TarefaHabitoQtdModel(
          id: 'q1',
          usuario: 'user1',
          metaVezes: 4,
          valor: 1,
          reiniciaEmQtd: 1,
          reiniciaEmTipo: 'dias',
          vezesPraticado: 0,
          createdAt: DateTime(2026, 8),
          categoriasTarefasHabitos: catSaude,
        ),
      ],
    );

    test('DashboardLogic returns 0 executed for today when historico is empty for today', () {
      final now = DateTime.now();
      // Record from yesterday
      final yesterday = now.subtract(const Duration(days: 1));
      final historicoYesterday = [
        HistoricoItemModel(
          id: 'hist1',
          usuario: 'user1',
          createdAt: yesterday,
          tarefasEHabitos: habit1,
        ),
      ];

      // Executed commitment time
      final executed = DashboardLogic.getExecutedCommitmentTime([habit1], historicoYesterday);
      expect(executed['dias'], equals(0)); // 0 executed today

      // Category progress
      final progress = DashboardLogic.getCategoryProgress([habit1], historicoYesterday);
      expect(progress.first.cycles['dias']!.totalExecuted, equals(0));
      expect(progress.first.cycles['dias']!.percentage, equals(0.0));

      // Completion rate for last 7 days: index 6 (today) must be 0%
      final rates = DashboardLogic.getCompletionRateLast7DaysList([habit1], historicoYesterday);
      expect(rates.length, equals(7));
      expect(rates.last.completedCount, equals(0));
      expect(rates.last.rate, equals(0.0));
    });

    test('DriftTarefaHabitoRepository resets daily habit vezesPraticado after midnight across timezones', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final repo = DriftTarefaHabitoRepository(
        database: db,
        remoteRepository: FakeRemoteTarefaHabitoRepository(),
      );

      // Create habit locally
      await repo.createTarefaHabito(
        nome: 'Exercício',
        tipo: 'habito',
        metas: [
          {
            'id': 'q_ex',
            'metaVezes': 1,
            'valor': 1,
            'reiniciaEmQtd': 1,
            'reiniciaEmTipo': 'dias',
            'createdAt': DateTime(2026, 8).millisecondsSinceEpoch,
          }
        ],
        usuarioId: 'user1',
      );

      // Record an execution that took place yesterday at 23:00 (which in UTC is 02:00 today)
      final now = DateTime.now();
      final yesterdayNightLocal = DateTime(now.year, now.month, now.day - 1, 23);
      final yesterdayNightUtc = yesterdayNightLocal.toUtc();

      await db.into(db.historicoTarefasHabitos).insert(
        HistoricoTarefasHabitosCompanion.insert(
          remoteId: 'h_yesterday',
          usuario: 'user1',
          tarefaHabitoId: (await repo.getTarefasEHabitos(usuarioId: 'user1')).first.id,
          createdAt: yesterdayNightUtc,
        ),
      );

      // Fetch habits today
      final habitsToday = await repo.getTarefasEHabitos(usuarioId: 'user1');
      expect(habitsToday.length, equals(1));
      // Daily habit should be 0 because it was executed yesterday, not today
      expect(habitsToday.first.tarefasHabitosQtd.first.vezesPraticado, equals(0));

      await db.close();
    });
  });
}
