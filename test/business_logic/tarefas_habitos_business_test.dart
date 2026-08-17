import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppvdigital/app/capacitacao/tarefas_habitos/dashboard_logic.dart';
import 'package:ppvdigital/app/capacitacao/tarefas_habitos/tarefas_habitos_controller.dart';
import 'package:ppvdigital/models/categorias_tarefas_habitos_model.dart';
import 'package:ppvdigital/models/historico_item_model.dart';
import 'package:ppvdigital/models/tarefas_habitos_model.dart';
import 'package:ppvdigital/models/tarefas_habitos_qtd_model.dart';

void main() {
  group('Regras de Negócio - Módulo de Tarefas e Hábitos', () {
    group('1. Lógica de Janelas de Reinício de Hábitos (TarefasHabitosTransformList)', () {
      final mockHabito = TarefaHabitoModel(
        id: 'h1',
        nome: 'Beber Água',
        tipo: 'habito',
        usuario: 'user1',
        concluida: false,
        agendamento: null,
        tarefasHabitosQtd: [],
      );

      final now = DateTime.now();

      test('Frequência de reinício diário ("dias")', () {
        final rawList = [
          {
            r'$id': 'qtd1',
            'usuario': 'user1',
            'metaVezes': 3,
            'valor': 1.0,
            'reiniciaEmTipo': 'dias',
            'reiniciaEmQtd': 1,
            'dataCriacao': now.subtract(const Duration(days: 5)).millisecondsSinceEpoch,
          }
        ];

        final historicoList = [
          // Histórico de hoje (deve contar)
          HistoricoItemModel(
            id: 'hist1',
            usuario: 'user1',
            createdAt: now,
            tarefasEHabitos: mockHabito,
          ),
          HistoricoItemModel(
            id: 'hist2',
            usuario: 'user1',
            createdAt: now,
            tarefasEHabitos: mockHabito,
          ),
          // Histórico de ontem (não deve contar para reinício diário de hoje)
          HistoricoItemModel(
            id: 'hist3',
            usuario: 'user1',
            createdAt: now.subtract(const Duration(days: 1)),
            tarefasEHabitos: mockHabito,
          ),
        ];

        final result = rawList.toTarefaHabitoQtdModelList(historicoList);

        expect(result.length, equals(1));
        expect(result.first.vezesPraticado, equals(2.0)); // Apenas hist1 e hist2
        expect(result.first.metaVezes, equals(3));
        expect(result.first.vezesPraticado >= result.first.metaVezes, isFalse);
      });

      test('Cálculo de Meta Atingida quando vezesPraticado >= metaVezes', () {
        final qtdModel = TarefaHabitoQtdModel(
          id: 'q1',
          usuario: 'user1',
          metaVezes: 2,
          valor: 1.0,
          reiniciaEmQtd: 1,
          reiniciaEmTipo: 'dias',
          vezesPraticado: 2.0,
          createdAt: DateTime.now(),
        );

        final bool isMetaAtingida = qtdModel.vezesPraticado >= qtdModel.metaVezes;
        expect(isMetaAtingida, isTrue);

        final qtdModelIncompleta = qtdModel.copyWith(vezesPraticado: 1.0);
        final bool isIncompletaAtingida =
            qtdModelIncompleta.vezesPraticado >= qtdModelIncompleta.metaVezes;
        expect(isIncompletaAtingida, isFalse);
      });

      test('Multiplicador de valor em vezesPraticado', () {
        final rawList = [
          {
            r'$id': 'qtd2',
            'usuario': 'user1',
            'metaVezes': 10,
            'valor': 2.5, // Cada execução vale 2.5
            'reiniciaEmTipo': 'dias',
            'reiniciaEmQtd': 1,
            'dataCriacao': now.millisecondsSinceEpoch,
          }
        ];

        final historicoList = [
          HistoricoItemModel(
            id: 'h1',
            usuario: 'user1',
            createdAt: now,
            tarefasEHabitos: mockHabito,
          ),
          HistoricoItemModel(
            id: 'h2',
            usuario: 'user1',
            createdAt: now,
            tarefasEHabitos: mockHabito,
          ),
        ];

        final result = rawList.toTarefaHabitoQtdModelList(historicoList);

        expect(result.first.vezesPraticado, equals(5.0)); // 2 registros * 2.5
      });

      test('Reset de hábito mensal criado no ano anterior', () {
        // Hábito mensal criado em 2025-01-01
        final creationDate = DateTime(2025);
        final rawList = [
          {
            r'$id': 'qtd_mensal',
            'usuario': 'user1',
            'metaVezes': 1,
            'valor': 1.0,
            'reiniciaEmTipo': 'meses',
            'reiniciaEmQtd': 1,
            'dataCriacao': creationDate.millisecondsSinceEpoch,
          }
        ];

        final historicoList = [
          // Praticado no ano anterior em 2025-05-10 (mês passado, não deve contar para o mês atual)
          HistoricoItemModel(
            id: 'hist_antigo',
            usuario: 'user1',
            createdAt: DateTime(2025, 5, 10),
            tarefasEHabitos: mockHabito,
          ),
          // Praticado no mês passado em 2026-06-15 (mês anterior ao atual)
          HistoricoItemModel(
            id: 'hist_mes_passado',
            usuario: 'user1',
            createdAt: DateTime(2026, 6, 15),
            tarefasEHabitos: mockHabito,
          ),
          // Praticado no mês atual
          HistoricoItemModel(
            id: 'hist_mes_atual',
            usuario: 'user1',
            createdAt: now,
            tarefasEHabitos: mockHabito,
          ),
        ];

        final result = rawList.toTarefaHabitoQtdModelList(historicoList);

        expect(result.length, equals(1));
        // Apenas o hist_mes_atual deve contar
        expect(result.first.vezesPraticado, equals(1.0));
      });
    });

    group('2. Lógica de Matriz de Calendário de Tarefas e Hábitos', () {
      List<DateTime> gerarMatrizDiasMes(int ano, int mes) {
        final primeiroDia = DateTime(ano, mes);
        final ultimoDia = DateTime(ano, mes + 1, 0);

        final diasAntes = primeiroDia.weekday - 1; // 1 = Segunda
        final inicioMatriz = primeiroDia.subtract(Duration(days: diasAntes));

        final List<DateTime> matriz = [];
        DateTime diaAtual = inicioMatriz;

        // Grade padronizada de 35 ou 42 dias (5 ou 6 semanas)
        while (matriz.length < 35 || diaAtual.isBefore(ultimoDia.add(const Duration(days: 1)))) {
          matriz.add(diaAtual);
          diaAtual = diaAtual.add(const Duration(days: 1));
          if (matriz.length >= 42) break;
        }

        return matriz;
      }

      test('Geração da matriz de Julho 2026 contendo todos os dias do mês', () {
        final matriz = gerarMatrizDiasMes(2026, 7);

        // Julho tem 31 dias
        final diasJulho = matriz.where((d) => d.month == 7);
        expect(diasJulho.length, equals(31));

        // Primeiro dia de julho 2026 foi Quarta-feira (weekday = 3)
        expect(DateTime(2026, 7).weekday, equals(3));
      });

      test('Filtragem de tarefas por data agendada', () {
        final dataDesejada = DateTime(2026, 7, 22);

        final tarefas = [
          TarefaHabitoModel(
            id: 't1',
            nome: 'Reunião de Equipe',
            tipo: 'tarefa',
            usuario: 'user1',
            concluida: false,
            agendamento: DateTime(2026, 7, 22, 10),
            tarefasHabitosQtd: [],
          ),
          TarefaHabitoModel(
            id: 't2',
            nome: 'Entrega de Relatório',
            tipo: 'tarefa',
            usuario: 'user1',
            concluida: false,
            agendamento: DateTime(2026, 7, 25, 15),
            tarefasHabitosQtd: [],
          ),
        ];

        final tarefasDoDia = tarefas.where((t) {
          if (t.agendamento == null) return false;
          return t.agendamento!.year == dataDesejada.year &&
              t.agendamento!.month == dataDesejada.month &&
              t.agendamento!.day == dataDesejada.day;
        }).toList();

        expect(tarefasDoDia.length, equals(1));
        expect(tarefasDoDia.first.id, equals('t1'));
      });
    });

    group('3. DashboardLogic - Cálculos de Tempo e Metas', () {
      test('getPlannedCommitmentTime escala corretamente por metaVezes e reiniciaEmQtd', () {
        final habitos = [
          TarefaHabitoModel(
            id: 'h_daily',
            nome: 'Exercício',
            tipo: 'habito',
            usuario: 'user1',
            concluida: false,
            agendamento: null,
            duration: 30, // 30 minutos
            tarefasHabitosQtd: [
              TarefaHabitoQtdModel(
                id: 'qtd_d',
                usuario: 'user1',
                metaVezes: 2, // 2 vezes ao dia = 60 min/dia
                valor: 1,
                reiniciaEmTipo: 'dias',
                reiniciaEmQtd: 1,
                vezesPraticado: 0,
                createdAt: DateTime.now(),
              ),
            ],
          ),
          TarefaHabitoModel(
            id: 'h_weekly',
            nome: 'Leitura',
            tipo: 'habito',
            usuario: 'user1',
            concluida: false,
            agendamento: null,
            duration: 60, // 60 minutos
            tarefasHabitosQtd: [
              TarefaHabitoQtdModel(
                id: 'qtd_w',
                usuario: 'user1',
                metaVezes: 2, // 2 vezes a cada 2 semanas = 1 vez/semana = 60 min/semana
                valor: 1,
                reiniciaEmTipo: 'semanas',
                reiniciaEmQtd: 2,
                vezesPraticado: 0,
                createdAt: DateTime.now(),
              ),
            ],
          ),
        ];

        final planned = DashboardLogic.getPlannedCommitmentTime(habitos);

        // h_daily: 60 min/dia, 420 min/semana
        // h_weekly: (60 * 2 / 2) = 60 min/semana, 60/7 = 9 min/dia
        expect(planned['dias'], equals(60 + 9));
        expect(planned['semanas'], equals(420 + 60));
      });

      test('getCategoryProgress calcula meta baseada em (metaVezes * valor) / reiniciaEmQtd', () {
        final habitos = [
          TarefaHabitoModel(
            id: 'h_estudo',
            nome: 'Estudo de Inglês',
            tipo: 'habito',
            usuario: 'user1',
            concluida: false,
            agendamento: null,
            duration: 45,
            tarefasHabitosQtd: [
              TarefaHabitoQtdModel(
                id: 'qtd_estudo',
                usuario: 'user1',
                metaVezes: 3,
                valor: 2, // Cada execução vale 2.0 -> total ciclo = 3 * 2.0 = 6.0
                reiniciaEmTipo: 'dias',
                reiniciaEmQtd: 1,
                vezesPraticado: 0,
                createdAt: DateTime.now(),
                categoriasTarefasHabitos: CategoriasTarefasHabitosModel(
                  id: 'cat1',
                  nome: 'Educação',
                  cor: const Color(0xFF4CAF50),
                  usuario: 'user1',
                ),
              ),
            ],
          ),
        ];

        final progress = DashboardLogic.getCategoryProgress(habitos);
        expect(progress.length, equals(1));
        expect(progress.first.name, equals('Educação'));

        final cycleDia = progress.first.cycles['dias']!;
        expect(cycleDia.totalGoal, equals(6.0));

        final cycleSemana = progress.first.cycles['semanas']!;
        expect(cycleSemana.totalGoal, equals(42.0)); // 6.0 * 7
      });

      test('getCategoryProgress inclui tarefas incompletas e calcula metas hierarquicas completas', () {
        final now = DateTime.now();
        final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
        final catTrabalho = CategoriasTarefasHabitosModel(
          id: 'cat_work',
          nome: 'Trabalho',
          cor: const Color(0xFF2196F3),
          usuario: 'user1',
        );

        final items = [
          // Hábito diário: 1x, valor 2.0 -> baseDias = 2.0
          TarefaHabitoModel(
            id: 'h1',
            nome: 'Revisar E-mails',
            tipo: 'habito',
            usuario: 'user1',
            concluida: false,
            agendamento: null,
            tarefasHabitosQtd: [
              TarefaHabitoQtdModel(
                id: 'q1',
                usuario: 'user1',
                metaVezes: 1,
                valor: 2,
                reiniciaEmTipo: 'dias',
                reiniciaEmQtd: 1,
                vezesPraticado: 0,
                createdAt: now,
                categoriasTarefasHabitos: catTrabalho,
              ),
            ],
          ),
          // Hábito semanal: 2x, valor 5.0 -> baseSemanas = 10.0
          TarefaHabitoModel(
            id: 'h2',
            nome: 'Reunião de Planejamento',
            tipo: 'habito',
            usuario: 'user1',
            concluida: false,
            agendamento: null,
            tarefasHabitosQtd: [
              TarefaHabitoQtdModel(
                id: 'q2',
                usuario: 'user1',
                metaVezes: 2,
                valor: 5,
                reiniciaEmTipo: 'semanas',
                reiniciaEmQtd: 1,
                vezesPraticado: 0,
                createdAt: now,
                categoriasTarefasHabitos: catTrabalho,
              ),
            ],
          ),
          // Hábito mensal: 1x, valor 20.0 -> baseMeses = 20.0
          TarefaHabitoModel(
            id: 'h3',
            nome: 'Fechamento Mensal',
            tipo: 'habito',
            usuario: 'user1',
            concluida: false,
            agendamento: null,
            tarefasHabitosQtd: [
              TarefaHabitoQtdModel(
                id: 'q3',
                usuario: 'user1',
                metaVezes: 1,
                valor: 20,
                reiniciaEmTipo: 'meses',
                reiniciaEmQtd: 1,
                vezesPraticado: 0,
                createdAt: now,
                categoriasTarefasHabitos: catTrabalho,
              ),
            ],
          ),
          // Tarefa incompleta diária: valor 3.0 -> não entra na meta de hábitos
          TarefaHabitoModel(
            id: 't1',
            nome: 'Enviar Relatório',
            tipo: 'tarefa',
            usuario: 'user1',
            concluida: false,
            agendamento: null,
            tarefasHabitosQtd: [
              TarefaHabitoQtdModel(
                id: 'qt1',
                usuario: 'user1',
                metaVezes: 1,
                valor: 3,
                reiniciaEmTipo: 'dias',
                reiniciaEmQtd: 1,
                vezesPraticado: 0,
                createdAt: now,
                categoriasTarefasHabitos: catTrabalho,
              ),
            ],
          ),
        ];

        final progress = DashboardLogic.getCategoryProgress(items);
        expect(progress.length, equals(1));
        final workCat = progress.first;

        // baseDias = 2.0 (somente hábito diário, tarefas não entram na meta)
        // baseSemanas = 10.0
        // baseMeses = 20.0
        // baseAnos = 0.0

        // Dia: somente hábitos diários = 2.0
        expect(workCat.cycles['dias']!.totalGoal, equals(2.0));

        // Semana: diárias (2.0 * 7 = 14.0) + semanal (10.0) = 24.0
        expect(workCat.cycles['semanas']!.totalGoal, equals(24.0));

        // Mês: diárias (2.0 * daysInMonth) + semanal (10.0 * 4 = 40.0) + mensal (20.0)
        expect(workCat.cycles['meses']!.totalGoal, equals((2.0 * daysInMonth) + 40.0 + 20.0));

        // Ano: diárias (2.0 * 365 = 730.0) + semanal (10.0 * 52 = 520.0) + mensal (20.0 * 12 = 240.0) + 0 = 1490.0
        expect(workCat.cycles['anos']!.totalGoal, equals(730.0 + 520.0 + 240.0));
      });
    });
  });
}
