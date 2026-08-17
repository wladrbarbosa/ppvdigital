import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppvdigital/app/capacitacao/tarefas_habitos/dashboard_logic.dart';
import 'package:ppvdigital/models/categorias_tarefas_habitos_model.dart';
import 'package:ppvdigital/models/historico_item_model.dart';
import 'package:ppvdigital/models/tarefas_habitos_model.dart';
import 'package:ppvdigital/models/tarefas_habitos_qtd_model.dart';

void main() {
  group('DashboardLogic Tests', () {
    test('getPlannedCommitmentTime calculates planned habit times across all cycles with metaVezes and reiniciaEmQtd', () {
      final now = DateTime.now();
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final daysInYear =
          ((now.year % 4 == 0 && now.year % 100 != 0) || now.year % 400 == 0)
              ? 366
              : 365;

      final items = <TarefaHabitoModel>[
        // Hábito diário: 30 min, 2x ao dia (reiniciaEmQtd = 1) -> 60 min/dia
        TarefaHabitoModel(
          id: '1',
          usuario: 'u1',
          nome: 'Habit Daily',
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
              vezesPraticado: 0,
              createdAt: now,
            )
          ],
        ),
        // Hábito semanal: 60 min, 2x a cada 1 semana -> 120 min/semana
        // Prorrateado: dia = 120/7 = 17 min, mês = 120*4 = 480 min, ano = 120*52 = 6240 min
        TarefaHabitoModel(
          id: '2',
          usuario: 'u1',
          nome: 'Habit Weekly',
          tipo: 'habito',
          duration: 60,
          concluida: false,
          agendamento: null,
          tarefasHabitosQtd: [
            TarefaHabitoQtdModel(
              id: 'q2',
              usuario: 'u1',
              metaVezes: 2,
              valor: 1.0,
              reiniciaEmTipo: 'semanas',
              reiniciaEmQtd: 1,
              vezesPraticado: 0,
              createdAt: now,
            )
          ],
        ),
        // Hábito mensal: 120 min, 1x a cada 2 meses (reiniciaEmQtd = 2) -> 60 min/mês
        // Prorrateado: dia = 60/daysInMonth min, semana = 60/4 = 15 min, ano = 60*12 = 720 min
        TarefaHabitoModel(
          id: '3',
          usuario: 'u1',
          nome: 'Habit Monthly',
          tipo: 'habito',
          duration: 120,
          concluida: false,
          agendamento: null,
          tarefasHabitosQtd: [
            TarefaHabitoQtdModel(
              id: 'q3',
              usuario: 'u1',
              metaVezes: 1,
              valor: 1.0,
              reiniciaEmTipo: 'meses',
              reiniciaEmQtd: 2,
              vezesPraticado: 0,
              createdAt: now,
            )
          ],
        ),
        // Tarefas não devem ser contabilizadas no tempo previsto de hábitos
        TarefaHabitoModel(
          id: '4',
          usuario: 'u1',
          nome: 'Task',
          tipo: 'tarefa',
          duration: 90,
          concluida: false,
          agendamento: null,
          tarefasHabitosQtd: [],
        ),
      ];

      final planned = DashboardLogic.getPlannedCommitmentTime(items);

      // Total dia: 60 (diário) + round(120/7 = 17) + round(60/daysInMonth)
      final expectedDia = 60 + (120 / 7).round() + (60 / daysInMonth).round();
      expect(planned['dias'], expectedDia);

      // Total semana: (60 * 7 = 420) + 120 (semanal) + round(60/4 = 15) = 555
      expect(planned['semanas'], 420 + 120 + 15);

      // Total mês: (60 * daysInMonth) + (120 * 4 = 480) + 60 (mensal)
      expect(planned['meses'], (60 * daysInMonth) + 480 + 60);

      // Total ano: (60 * daysInYear) + (120 * 52 = 6240) + (60 * 12 = 720)
      expect(planned['anos'], (60 * daysInYear) + 6240 + 720);
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

    test('getCategoryProgress hierarchical inclusion (Dia only daily, Semana daily+weekly, etc.) with incomplete tasks', () {
      final catSaude = CategoriasTarefasHabitosModel(
        id: 'catSaude',
        nome: 'Saúde',
        cor: Colors.red,
        usuario: 'user1',
      );

      final items = <TarefaHabitoModel>[
        // Hábito diário: meta = 2x, valor = 3.0 -> total diário = 6.0
        TarefaHabitoModel(
          id: 'h_dia',
          usuario: 'user1',
          nome: 'Caminhada',
          tipo: 'habito',
          concluida: false,
          agendamento: null,
          tarefasHabitosQtd: [
            TarefaHabitoQtdModel(
              id: 'q_dia',
              usuario: 'user1',
              metaVezes: 2,
              valor: 3.0,
              vezesPraticado: 1,
              categoriasTarefasHabitos: catSaude,
              reiniciaEmTipo: 'dias',
              reiniciaEmQtd: 1,
              createdAt: DateTime.now(),
            ),
          ],
        ),
        // Hábito semanal: meta = 1x, valor = 10.0 -> total semanal = 10.0
        TarefaHabitoModel(
          id: 'h_sem',
          usuario: 'user1',
          nome: 'Natação',
          tipo: 'habito',
          concluida: false,
          agendamento: null,
          tarefasHabitosQtd: [
            TarefaHabitoQtdModel(
              id: 'q_sem',
              usuario: 'user1',
              metaVezes: 1,
              valor: 10.0,
              vezesPraticado: 0,
              categoriasTarefasHabitos: catSaude,
              reiniciaEmTipo: 'semanas',
              reiniciaEmQtd: 1,
              createdAt: DateTime.now(),
            ),
          ],
        ),
        // Tarefa diária incompleta: meta = 1x, valor = 4.0 -> total diário = 4.0
        TarefaHabitoModel(
          id: 't_incompleta',
          usuario: 'user1',
          nome: 'Comprar Remédio',
          tipo: 'tarefa',
          concluida: false,
          agendamento: null,
          tarefasHabitosQtd: [
            TarefaHabitoQtdModel(
              id: 'q_t',
              usuario: 'user1',
              metaVezes: 1,
              valor: 4.0,
              vezesPraticado: 0,
              categoriasTarefasHabitos: catSaude,
              reiniciaEmTipo: 'dias',
              reiniciaEmQtd: 1,
              createdAt: DateTime.now(),
            ),
          ],
        ),
        // Tarefa concluída: não entra na meta restante de baseGoals
        TarefaHabitoModel(
          id: 't_concluida',
          usuario: 'user1',
          nome: 'Agendar Consulta',
          tipo: 'tarefa',
          concluida: true,
          agendamento: null,
          tarefasHabitosQtd: [
            TarefaHabitoQtdModel(
              id: 'q_t2',
              usuario: 'user1',
              metaVezes: 1,
              valor: 5.0,
              vezesPraticado: 0,
              categoriasTarefasHabitos: catSaude,
              reiniciaEmTipo: 'dias',
              reiniciaEmQtd: 1,
              createdAt: DateTime.now(),
            ),
          ],
        ),
      ];

      final list = DashboardLogic.getCategoryProgress(items);
      expect(list.length, 1);
      final cat = list.first;

      // Base diária = 6.0 (somente hábito diário, tarefas não entram na meta)
      // Base semanal = 10.0 (somente hábito semanal)
      // Dia: somente hábitos diários = 6.0
      expect(cat.cycles['dias']!.totalGoal, equals(6.0));

      // Semana: hábitos diários (6.0 * 7 = 42.0) + semanal (10.0) = 52.0
      expect(cat.cycles['semanas']!.totalGoal, equals(52.0));

      // Executado no dia: 1 * 3.0 (hábito) + 5.0 (tarefa concluída) = 8.0
      expect(cat.cycles['dias']!.totalExecuted, equals(8.0));
    });

    test('getAvailableTime returns correct minutes per cycle', () {
      final available = DashboardLogic.getAvailableTime();
      final now = DateTime.now();
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final daysInYear =
          ((now.year % 4 == 0 && now.year % 100 != 0) || now.year % 400 == 0)
              ? 366
              : 365;
      expect(available['dias'], 1440);
      expect(available['semanas'], 10080);
      expect(available['meses'], daysInMonth * 24 * 60);
      expect(available['anos'], daysInYear * 24 * 60);
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
