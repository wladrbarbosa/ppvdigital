import 'package:flutter_test/flutter_test.dart';
import 'package:ppvdigital/app/capacitacao/tarefas_habitos/tarefas_habitos_controller.dart';
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
    });

    group('2. Lógica de Matriz de Calendário de Tarefas e Hábitos', () {
      List<DateTime> gerarMatrizDiasMes(int ano, int mes) {
        final primeiroDia = DateTime(ano, mes, 1);
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
        expect(DateTime(2026, 7, 1).weekday, equals(3));
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
            agendamento: DateTime(2026, 7, 22, 10, 0),
            tarefasHabitosQtd: [],
          ),
          TarefaHabitoModel(
            id: 't2',
            nome: 'Entrega de Relatório',
            tipo: 'tarefa',
            usuario: 'user1',
            concluida: false,
            agendamento: DateTime(2026, 7, 25, 15, 0),
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
  });
}
