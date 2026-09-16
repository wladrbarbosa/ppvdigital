import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
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

    group('Archived Items Exclusion Tests', () {
      final categoryA = CategoriasTarefasHabitosModel(
        id: 'catA',
        nome: 'Saúde',
        cor: Colors.green,
        usuario: 'u1',
      );

      final activeHabit = TarefaHabitoModel(
        id: 'h_active',
        usuario: 'u1',
        nome: 'Hábito Ativo',
        tipo: 'habito',
        duration: 30,
        concluida: false,
        agendamento: null,
        tarefasHabitosQtd: [
          TarefaHabitoQtdModel(
            id: 'q_active',
            usuario: 'u1',
            metaVezes: 2,
            valor: 1.0,
            reiniciaEmTipo: 'dias',
            reiniciaEmQtd: 1,
            vezesPraticado: 1,
            categoriasTarefasHabitos: categoryA,
            createdAt: DateTime.now(),
          ),
        ],
      );

      final archivedHabit = TarefaHabitoModel(
        id: 'h_archived',
        usuario: 'u1',
        nome: 'Hábito Arquivado',
        tipo: 'habito',
        duration: 60,
        concluida: false,
        arquivado: true,
        agendamento: null,
        tarefasHabitosQtd: [
          TarefaHabitoQtdModel(
            id: 'q_archived',
            usuario: 'u1',
            metaVezes: 5,
            valor: 2.0,
            reiniciaEmTipo: 'dias',
            reiniciaEmQtd: 1,
            vezesPraticado: 3,
            categoriasTarefasHabitos: categoryA,
            createdAt: DateTime.now(),
          ),
        ],
      );

      final activeTask = TarefaHabitoModel(
        id: 't_active',
        usuario: 'u1',
        nome: 'Tarefa Ativa',
        tipo: 'tarefa',
        duration: 20,
        concluida: true,
        agendamento: null,
        tarefasHabitosQtd: [
          TarefaHabitoQtdModel(
            id: 'qt_active',
            usuario: 'u1',
            metaVezes: 1,
            valor: 3.0,
            reiniciaEmTipo: 'dias',
            reiniciaEmQtd: 1,
            vezesPraticado: 0,
            categoriasTarefasHabitos: categoryA,
            createdAt: DateTime.now(),
          ),
        ],
      );

      final archivedTask = TarefaHabitoModel(
        id: 't_archived',
        usuario: 'u1',
        nome: 'Tarefa Arquivada',
        tipo: 'tarefa',
        duration: 40,
        concluida: true,
        arquivado: true,
        agendamento: null,
        tarefasHabitosQtd: [
          TarefaHabitoQtdModel(
            id: 'qt_archived',
            usuario: 'u1',
            metaVezes: 1,
            valor: 5.0,
            reiniciaEmTipo: 'dias',
            reiniciaEmQtd: 1,
            vezesPraticado: 0,
            categoriasTarefasHabitos: categoryA,
            createdAt: DateTime.now(),
          ),
        ],
      );

      test('getPlannedCommitmentTime ignores archived habits', () {
        final planned = DashboardLogic.getPlannedCommitmentTime([
          activeHabit,
          archivedHabit,
        ]);
        // Apenas activeHabit: 30 * 2 = 60 min
        expect(planned['dias'], 60);
      });

      test('getExecutedCommitmentTime ignores archived items in fallback and historico', () {
        final now = DateTime.now();
        // 1. Fallback sem historico
        final executedFallback = DashboardLogic.getExecutedCommitmentTime([
          activeHabit,
          archivedHabit,
          activeTask,
          archivedTask,
        ]);
        // Active habit: 30 * 1 = 30 min. Active task: 20 min. Total = 50 min.
        // Archived habit (60*3=180) e Archived task (40) devem ser ignorados.
        expect(executedFallback['dias'], 50);

        // 2. Com historico
        final historico = [
          HistoricoItemModel(
            id: 'hist1',
            usuario: 'u1',
            tarefasEHabitos: activeHabit,
            createdAt: now,
          ),
          HistoricoItemModel(
            id: 'hist2',
            usuario: 'u1',
            tarefasEHabitos: archivedHabit,
            createdAt: now,
          ),
        ];

        final executedWithHist = DashboardLogic.getExecutedCommitmentTime(
          [activeHabit, archivedHabit],
          historico,
        );
        // Apenas o historico do activeHabit (30 min) deve contar
        expect(executedWithHist['dias'], 30);
      });

      test('getCategoryProgress ignores archived items and archived history', () {
        final now = DateTime.now();
        final historico = [
          HistoricoItemModel(
            id: 'hist1',
            usuario: 'u1',
            tarefasEHabitos: activeHabit,
            createdAt: now,
          ),
          HistoricoItemModel(
            id: 'hist2',
            usuario: 'u1',
            tarefasEHabitos: archivedHabit,
            createdAt: now,
          ),
        ];

        final list = DashboardLogic.getCategoryProgress(
          [activeHabit, archivedHabit, activeTask, archivedTask],
          historico,
        );

        expect(list.length, 1);
        final cat = list.first;
        // Meta do activeHabit: metaVezes(2) * valor(1.0) = 2.0 (archivedHabit ignorado)
        expect(cat.cycles['dias']!.totalGoal, 2.0);
        // Executado do historico apenas para activeHabit: valor(1.0) = 1.0 (archivedHabit ignorado)
        expect(cat.cycles['dias']!.totalExecuted, 1.0);
      });

      test('getCategoryAttentionDistribution ignores archived items and completed tasks', () {
        final pendingActiveTask = activeTask.copyWith(concluida: false);
        final list = DashboardLogic.getCategoryAttentionDistribution([
          activeHabit,
          archivedHabit,
          pendingActiveTask,
          archivedTask,
        ]);
        expect(list.length, 1);
        // activeHabit valor=1.0 + pendingActiveTask valor=3.0 = 4.0 (archivedHabit e archivedTask ignorados)
        expect(list.first.totalValue, 4.0);
      });

      test('getCompletionRateLast7DaysList ignores archived habits and archived historico', () {
        final now = DateTime.now();
        final historico = [
          HistoricoItemModel(
            id: 'h_act',
            usuario: 'u1',
            tarefasEHabitos: activeHabit,
            createdAt: now,
          ),
          HistoricoItemModel(
            id: 'h_arch',
            usuario: 'u1',
            tarefasEHabitos: archivedHabit,
            createdAt: now,
          ),
        ];

        final list = DashboardLogic.getCompletionRateLast7DaysList(
          [activeHabit, archivedHabit],
          historico,
        );

        final todayRate = list.last;
        // totalHabits = 1 (activeHabit), completed = 1 (activeHabit) -> rate = 1.0
        expect(todayRate.totalCount, 1);
        expect(todayRate.completedCount, 1);
        expect(todayRate.rate, 1.0);
      });

      test('getHabitTaskDistribution ignores archived items', () {
        final incompleteActiveTask = activeTask.copyWith(concluida: false);
        final incompleteArchivedTask = archivedTask.copyWith(concluida: false);

        final distribution = DashboardLogic.getHabitTaskDistribution([
          activeHabit,
          archivedHabit,
          incompleteActiveTask,
          incompleteArchivedTask,
        ]);

        // Apenas activeHabit e incompleteActiveTask
        expect(distribution['Hábitos'], 1);
        expect(distribution['Tarefas'], 1);
      });

      test('Categories without active items or with only archived items are completely omitted', () {
        final catTrabalho = CategoriasTarefasHabitosModel(
          id: 'catTrabalho',
          nome: 'Trabalho',
          cor: Colors.blue,
          usuario: 'u1',
        );

        // catTrabalho possui apenas itens arquivados (e qualquer outra categoria sem itens nunca aparece)
        final archivedTrabalhoHabit = TarefaHabitoModel(
          id: 'h_trab_arch',
          usuario: 'u1',
          nome: 'Reunião Arquivada',
          tipo: 'habito',
          duration: 30,
          concluida: false,
          arquivado: true,
          agendamento: null,
          tarefasHabitosQtd: [
            TarefaHabitoQtdModel(
              id: 'q_trab_arch',
              usuario: 'u1',
              metaVezes: 2,
              valor: 1.0,
              reiniciaEmTipo: 'dias',
              reiniciaEmQtd: 1,
              vezesPraticado: 0,
              categoriasTarefasHabitos: catTrabalho,
              createdAt: DateTime.now(),
            ),
          ],
        );

        // catLazer não possui nenhum item na lista
        // Apenas activeHabit (categoria Saúde) está ativo
        final progressList = DashboardLogic.getCategoryProgress([
          activeHabit,
          archivedTrabalhoHabit,
        ]);

        expect(progressList.length, 1);
        expect(progressList.first.name, 'Saúde');
        expect(progressList.any((c) => c.name == 'Trabalho'), isFalse);
        expect(progressList.any((c) => c.name == 'Lazer'), isFalse);

        final attentionList = DashboardLogic.getCategoryAttentionDistribution([
          activeHabit,
          archivedTrabalhoHabit,
        ]);

        expect(attentionList.length, 1);
        expect(attentionList.first.name, 'Saúde');
        expect(attentionList.any((c) => c.name == 'Trabalho'), isFalse);
        expect(attentionList.any((c) => c.name == 'Lazer'), isFalse);
      });

      test('Category with empty or whitespace name resolves to Sem Categoria', () {
        final blankCategory = CategoriasTarefasHabitosModel(
          id: 'catBlank',
          nome: '   ',
          cor: Colors.grey,
          usuario: 'u1',
        );

        final habitWithBlankCat = TarefaHabitoModel(
          id: 'h_blank',
          usuario: 'u1',
          nome: 'Hábito Sem Nome de Categoria',
          tipo: 'habito',
          duration: 15,
          concluida: false,
          agendamento: null,
          tarefasHabitosQtd: [
            TarefaHabitoQtdModel(
              id: 'q_blank',
              usuario: 'u1',
              metaVezes: 1,
              valor: 1.0,
              reiniciaEmTipo: 'dias',
              reiniciaEmQtd: 1,
              vezesPraticado: 0,
              categoriasTarefasHabitos: blankCategory,
              createdAt: DateTime.now(),
            ),
          ],
        );

        final progressList = DashboardLogic.getCategoryProgress([
          habitWithBlankCat,
        ]);

        expect(progressList.length, 1);
        expect(progressList.first.name, 'Sem Categoria');

        final attentionList = DashboardLogic.getCategoryAttentionDistribution([
          habitWithBlankCat,
        ]);

        expect(attentionList.length, 1);
        expect(attentionList.first.name, 'Sem Categoria');
      });

      test('Category with only archived habits and existing historical executions is completely omitted from getCategoryProgress', () {
        final catCachorros = CategoriasTarefasHabitosModel(
          id: 'catCachorros',
          nome: 'Cachorros',
          cor: Colors.brown,
          usuario: 'u1',
        );

        final archivedCachorroHabit = TarefaHabitoModel(
          id: 'h_cachorro_archived',
          usuario: 'u1',
          nome: 'Passear com o cachorro',
          tipo: 'habito',
          duration: 30,
          concluida: false,
          arquivado: true,
          agendamento: null,
          tarefasHabitosQtd: [
            TarefaHabitoQtdModel(
              id: 'q_cachorro',
              usuario: 'u1',
              metaVezes: 2,
              valor: 1.0,
              reiniciaEmTipo: 'dias',
              reiniciaEmQtd: 1,
              vezesPraticado: 0,
              categoriasTarefasHabitos: catCachorros,
              createdAt: DateTime.now().subtract(const Duration(days: 30)),
            ),
          ],
        );

        final historico = [
          HistoricoItemModel(
            id: 'hist_cachorro_old',
            usuario: 'u1',
            tarefasEHabitos: archivedCachorroHabit,
            createdAt: DateTime.now().subtract(const Duration(days: 5)),
          ),
          HistoricoItemModel(
            id: 'hist_saude',
            usuario: 'u1',
            tarefasEHabitos: activeHabit,
            createdAt: DateTime.now(),
          ),
        ];

        final progressList = DashboardLogic.getCategoryProgress(
          [activeHabit, archivedCachorroHabit],
          historico,
        );

        // Cachorros tem histórico passado, mas como seu único hábito está arquivado, não deve aparecer
        expect(progressList.any((c) => c.name == 'Cachorros'), isFalse);
        expect(progressList.length, 1);
        expect(progressList.first.name, 'Saúde');
      });
    });

    group('Commitment Time Accuracy & Edge Cases Tests', () {
      final now = DateTime.now();

      test('getPlannedCommitmentTime ignores habits without duration (duration == null or <= 0)', () {
        final items = <TarefaHabitoModel>[
          TarefaHabitoModel(
            id: 'h1',
            usuario: 'u1',
            nome: 'Leitura',
            tipo: 'habito',
            duration: 30,
            concluida: false,
            agendamento: null,
            tarefasHabitosQtd: [
              TarefaHabitoQtdModel(
                id: 'q1',
                usuario: 'u1',
                metaVezes: 1,
                valor: 1.0,
                reiniciaEmTipo: 'dias',
                reiniciaEmQtd: 1,
                vezesPraticado: 0,
                createdAt: now,
              ),
            ],
          ),
          TarefaHabitoModel(
            id: 'h2',
            usuario: 'u1',
            nome: 'Beber Água',
            tipo: 'habito',
            concluida: false,
            agendamento: null,
            tarefasHabitosQtd: [
              TarefaHabitoQtdModel(
                id: 'q2',
                usuario: 'u1',
                metaVezes: 8,
                valor: 1.0,
                reiniciaEmTipo: 'dias',
                reiniciaEmQtd: 1,
                vezesPraticado: 0,
                createdAt: now,
              ),
            ],
          ),
          TarefaHabitoModel(
            id: 'h3',
            usuario: 'u1',
            nome: 'Alongar',
            tipo: 'habito',
            duration: 0, // duração zerada
            concluida: false,
            agendamento: null,
            tarefasHabitosQtd: [
              TarefaHabitoQtdModel(
                id: 'q3',
                usuario: 'u1',
                metaVezes: 1,
                valor: 1.0,
                reiniciaEmTipo: 'dias',
                reiniciaEmQtd: 1,
                vezesPraticado: 0,
                createdAt: now,
              ),
            ],
          ),
        ];

        final planned = DashboardLogic.getPlannedCommitmentTime(items);
        // Apenas h1 (30 min) deve contar. h2 (null) e h3 (0) NÃO devem gerar 30min default cada
        expect(planned['dias'], equals(30));
      });

      test('getPlannedCommitmentTime ignores negative habits (valor < 0)', () {
        final items = <TarefaHabitoModel>[
          TarefaHabitoModel(
            id: 'h1',
            usuario: 'u1',
            nome: 'Estudo',
            tipo: 'habito',
            duration: 40,
            concluida: false,
            agendamento: null,
            tarefasHabitosQtd: [
              TarefaHabitoQtdModel(
                id: 'q1',
                usuario: 'u1',
                metaVezes: 1,
                valor: 1.0,
                reiniciaEmTipo: 'dias',
                reiniciaEmQtd: 1,
                vezesPraticado: 0,
                createdAt: now,
              ),
            ],
          ),
          TarefaHabitoModel(
            id: 'h_neg',
            usuario: 'u1',
            nome: 'Não Fumar',
            tipo: 'habito',
            concluida: false,
            agendamento: null,
            tarefasHabitosQtd: [
              TarefaHabitoQtdModel(
                id: 'q_neg',
                usuario: 'u1',
                metaVezes: 30, // Meta de 30 dias de abstinência
                valor: -1.0,   // Hábito negativo
                reiniciaEmTipo: 'dias',
                reiniciaEmQtd: 1,
                vezesPraticado: 0,
                createdAt: now,
              ),
            ],
          ),
        ];

        final planned = DashboardLogic.getPlannedCommitmentTime(items);
        // Hábito negativo com meta de 30 dias NÃO pode somar 30*30 = 900 min
        expect(planned['dias'], equals(40));
      });

      test('getPlannedCommitmentTime does not duplicate duration when habit has multiple categories', () {
        final catSaude = CategoriasTarefasHabitosModel(id: 'c1', nome: 'Saúde', cor: Colors.green, usuario: 'u1');
        final catFoco = CategoriasTarefasHabitosModel(id: 'c2', nome: 'Foco', cor: Colors.blue, usuario: 'u1');

        final items = <TarefaHabitoModel>[
          TarefaHabitoModel(
            id: 'h_multi',
            usuario: 'u1',
            nome: 'Treino',
            tipo: 'habito',
            duration: 60,
            concluida: false,
            agendamento: null,
            tarefasHabitosQtd: [
              TarefaHabitoQtdModel(
                id: 'q1',
                usuario: 'u1',
                metaVezes: 1,
                valor: 1.0,
                reiniciaEmTipo: 'dias',
                reiniciaEmQtd: 1,
                vezesPraticado: 0,
                categoriasTarefasHabitos: catSaude,
                createdAt: now,
              ),
              TarefaHabitoQtdModel(
                id: 'q2',
                usuario: 'u1',
                metaVezes: 1,
                valor: 1.0,
                reiniciaEmTipo: 'dias',
                reiniciaEmQtd: 1,
                vezesPraticado: 0,
                categoriasTarefasHabitos: catFoco,
                createdAt: now,
              ),
            ],
          ),
        ];

        final planned = DashboardLogic.getPlannedCommitmentTime(items);
        // 60 minutos devem ser contabilizados apenas uma vez, e não duplicados para 120 min
        expect(planned['dias'], equals(60));
      });

      test('getExecutedCommitmentTime ignores negative habit relapses and items without duration', () {
        final habitPositivo = TarefaHabitoModel(
          id: 'h1',
          usuario: 'u1',
          nome: 'Meditar',
          tipo: 'habito',
          duration: 20,
          concluida: false,
          agendamento: null,
          tarefasHabitosQtd: [
            TarefaHabitoQtdModel(
              id: 'q1',
              usuario: 'u1',
              metaVezes: 1,
              valor: 1.0,
              reiniciaEmTipo: 'dias',
              reiniciaEmQtd: 1,
              vezesPraticado: 1,
              createdAt: now,
            ),
          ],
        );

        final habitSemDuracao = TarefaHabitoModel(
          id: 'h2',
          usuario: 'u1',
          nome: 'Tomar Vitamina',
          tipo: 'habito',
          concluida: false,
          agendamento: null,
          tarefasHabitosQtd: [
            TarefaHabitoQtdModel(
              id: 'q2',
              usuario: 'u1',
              metaVezes: 1,
              valor: 1.0,
              reiniciaEmTipo: 'dias',
              reiniciaEmQtd: 1,
              vezesPraticado: 1,
              createdAt: now,
            ),
          ],
        );

        final habitNegativo = TarefaHabitoModel(
          id: 'h3',
          usuario: 'u1',
          nome: 'Fumar',
          tipo: 'habito',
          duration: 15,
          concluida: false,
          agendamento: null,
          tarefasHabitosQtd: [
            TarefaHabitoQtdModel(
              id: 'q3',
              usuario: 'u1',
              metaVezes: 30,
              valor: -1.0,
              reiniciaEmTipo: 'dias',
              reiniciaEmQtd: 1,
              vezesPraticado: 1,
              createdAt: now,
            ),
          ],
        );

        final historico = [
          HistoricoItemModel(id: 'hist1', usuario: 'u1', tarefasEHabitos: habitPositivo, createdAt: now),
          HistoricoItemModel(id: 'hist2', usuario: 'u1', tarefasEHabitos: habitSemDuracao, createdAt: now),
          HistoricoItemModel(id: 'hist3', usuario: 'u1', tarefasEHabitos: habitNegativo, createdAt: now), // Relapso não é tempo produtivo
        ];

        final executed = DashboardLogic.getExecutedCommitmentTime([habitPositivo, habitSemDuracao, habitNegativo], historico);
        // Apenas meditar (20 min) deve contar como tempo executado.
        expect(executed['dias'], equals(20));
      });
    });
  });
}
