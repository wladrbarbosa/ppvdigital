import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppvdigital/app/capacitacao/tarefas_habitos/dashboard_logic.dart';
import 'package:ppvdigital/models/categorias_tarefas_habitos_model.dart';
import 'package:ppvdigital/models/historico_item_model.dart';
import 'package:ppvdigital/models/tarefas_habitos_model.dart';
import 'package:ppvdigital/models/tarefas_habitos_qtd_model.dart';

void main() {
  group('DashboardLogic Tests', () {
    test('getPlannedCommitmentTime calculates planned habit times across cycles', () {
      final items = <TarefaHabitoModel>[
        TarefaHabitoModel(
          id: '1',
          usuario: 'u1',
          nome: 'Habit 1 (Daily)',
          tipo: 'habito',
          duration: 30, // 30 mins
          concluida: false,
          agendamento: null,
          tarefasHabitosQtd: [
            TarefaHabitoQtdModel(
              id: 'q1',
              usuario: 'u1',
              metaVezes: 2, // 60 min/day
              valor: 1.0,
              reiniciaEmTipo: 'dias',
              reiniciaEmQtd: 1,
              vezesPraticado: 0,
              createdAt: DateTime.now(),
            )
          ],
        ),
        TarefaHabitoModel(
          id: '2',
          usuario: 'u1',
          nome: 'Task 1 (Should be ignored in planned)',
          tipo: 'tarefa',
          duration: 120,
          concluida: false,
          agendamento: null,
          tarefasHabitosQtd: [],
        ),
      ];

      final planned = DashboardLogic.getPlannedCommitmentTime(items);
      final now = DateTime.now();
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      expect(planned['dias'], 60); // 30 * 2
      expect(planned['semanas'], 420); // 60 * 7
      expect(planned['meses'], 60 * daysInMonth);
      expect(planned['anos'], 21900); // 60 * 365
    });

    test('getExecutedCommitmentTime calculates executed times for tasks and habits', () {
      final items = <TarefaHabitoModel>[
        TarefaHabitoModel(
          id: '1',
          usuario: 'u1',
          nome: 'Habit 1',
          tipo: 'habito',
          duration: 30,
          concluida: false,
          agendamento: null,
          tarefasHabitosQtd: [
            TarefaHabitoQtdModel(
              id: 'q1',
              usuario: 'u1',
              metaVezes: 2,
              valor: 1.0,
              reiniciaEmTipo: 'dias',
              reiniciaEmQtd: 1,
              vezesPraticado: 1, // 30 mins executed
              createdAt: DateTime.now(),
            )
          ],
        ),
        TarefaHabitoModel(
          id: '2',
          usuario: 'u1',
          nome: 'Task 1 (Completed)',
          tipo: 'tarefa',
          duration: 45,
          concluida: true, // 45 mins executed
          agendamento: null,
          tarefasHabitosQtd: [],
        ),
      ];

      final executed = DashboardLogic.getExecutedCommitmentTime(items);
      expect(executed['dias'], 75); // 30 + 45
    });

    test('getCategoryProgress calculates total goals and executed counts', () {
      final categoryA = CategoriasTarefasHabitosModel(
        id: 'catA',
        nome: 'Saúde',
        cor: Colors.red,
        usuario: 'user1',
      );

      final items = <TarefaHabitoModel>[
        TarefaHabitoModel(
          id: '1',
          usuario: 'u1',
          nome: 'Habit 1',
          tipo: 'habito',
          concluida: false,
          agendamento: null,
          tarefasHabitosQtd: [
            TarefaHabitoQtdModel(
              id: 'q1',
              usuario: 'u1',
              metaVezes: 4,
              valor: 1.0,
              vezesPraticado: 2,
              categoriasTarefasHabitos: categoryA,
              reiniciaEmTipo: 'dias',
              reiniciaEmQtd: 1,
              createdAt: DateTime.now(),
            )
          ],
        ),
      ];

      final list = DashboardLogic.getCategoryProgress(items);
      expect(list.length, 1);
      expect(list.first.name, 'Saúde');
      expect(list.first.cycles['dias']!.totalGoal, 4);
      expect(list.first.cycles['dias']!.totalExecuted, 2);
      expect(list.first.cycles['dias']!.percentage, 0.5);
    });

    test('getAvailableTime returns correct minutes per cycle', () {
      final available = DashboardLogic.getAvailableTime();
      final now = DateTime.now();
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      expect(available['dias'], 1440);
      expect(available['semanas'], 10080);
      expect(available['meses'], daysInMonth * 24 * 60);
      expect(available['anos'], 525600);
    });

    test('getCompletionRateLast7Days calculates correct rates', () {
      final now = DateTime.now();
      final items = <TarefaHabitoModel>[
        TarefaHabitoModel(
          id: 'h1',
          usuario: 'u1',
          nome: 'Habit 1',
          tipo: 'habito',
          concluida: false,
          agendamento: null,
          tarefasHabitosQtd: [
            TarefaHabitoQtdModel(
              id: 'q1',
              usuario: 'u1',
              metaVezes: 1,
              valor: 1.0,
              vezesPraticado: 0,
              reiniciaEmTipo: 'dias',
              reiniciaEmQtd: 1,
              createdAt: now,
            )
          ]
        ),
      ];

      final historico = <HistoricoItemModel>[
        HistoricoItemModel(
          id: 'h1',
          usuario: 'u1',
          tarefasEHabitos: items[0],
          createdAt: now,
        ),
      ];

      final rates = DashboardLogic.getCompletionRateLast7Days(items, historico);
      expect(rates[now.day], 1.0);
    });

    test('getHabitTaskDistribution counts correctly', () {
      final items = <TarefaHabitoModel>[
        TarefaHabitoModel(
          id: '1',
          usuario: 'u1',
          nome: 'H1',
          tipo: 'habito',
          concluida: false,
          agendamento: null,
          tarefasHabitosQtd: [],
        ),
        TarefaHabitoModel(
          id: '2',
          usuario: 'u1',
          nome: 'T1',
          tipo: 'tarefa',
          concluida: false,
          agendamento: null,
          tarefasHabitosQtd: [],
        ),
      ];

      final distribution = DashboardLogic.getHabitTaskDistribution(items);
      expect(distribution['Hábitos'], 1);
      expect(distribution['Tarefas'], 1);
    });

    test('getCategoryAttentionDistribution sums registered values per category', () {
      final categoryA = CategoriasTarefasHabitosModel(
        id: 'catA',
        nome: 'Trabalho',
        cor: Colors.blue,
        usuario: 'u1',
      );

      final items = <TarefaHabitoModel>[
        TarefaHabitoModel(
          id: '1',
          usuario: 'u1',
          nome: 'Habit 1',
          tipo: 'habito',
          concluida: false,
          agendamento: null,
          tarefasHabitosQtd: [
            TarefaHabitoQtdModel(
              id: 'q1',
              usuario: 'u1',
              metaVezes: 5,
              valor: 10.0,
              vezesPraticado: 0,
              categoriasTarefasHabitos: categoryA,
              reiniciaEmTipo: 'dias',
              reiniciaEmQtd: 1,
              createdAt: DateTime.now(),
            ),
          ],
        ),
      ];

      final list = DashboardLogic.getCategoryAttentionDistribution(items);
      expect(list.length, 1);
      expect(list.first.name, 'Trabalho');
      expect(list.first.totalValue, 10.0);
    });
  });
}
