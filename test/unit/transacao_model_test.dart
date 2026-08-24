import 'package:flutter_test/flutter_test.dart';
import 'package:ppvdigital/models/divisao_transacao_model.dart';
import 'package:ppvdigital/models/enums.dart';
import 'package:ppvdigital/models/tarefas_habitos_model.dart';
import 'package:ppvdigital/models/tarefas_habitos_qtd_model.dart';
import 'package:ppvdigital/models/transacao_model.dart';

void main() {
  group('Enums & TransacaoModel Unit Tests', () {
    test('TipoTransacao fromString works correctly', () {
      expect(TipoTransacao.fromString('despesa'), TipoTransacao.despesa);
      expect(TipoTransacao.fromString('receita'), TipoTransacao.receita);
      expect(TipoTransacao.fromString('transferencia'), TipoTransacao.transferencia);
      expect(TipoTransacao.fromString('  RECEITA  '), TipoTransacao.receita);
      expect(TipoTransacao.fromString('unknown'), TipoTransacao.despesa);
      expect(TipoTransacao.fromString(null), TipoTransacao.despesa);
    });

    test('TipoItem and TipoHabito fromString work correctly', () {
      expect(TipoItem.fromString('tarefa'), TipoItem.tarefa);
      expect(TipoItem.fromString('habito'), TipoItem.habito);
      expect(TipoHabito.fromString('positivo'), TipoHabito.positivo);
      expect(TipoHabito.fromString('negativo'), TipoHabito.negativo);
      expect(TipoHabito.fromString(null), TipoHabito.positivo);
    });

    test('TipoRecorrencia fromString works with accents and variations', () {
      expect(TipoRecorrencia.fromString('dia'), TipoRecorrencia.dia);
      expect(TipoRecorrencia.fromString('semana'), TipoRecorrencia.semana);
      expect(TipoRecorrencia.fromString('mês'), TipoRecorrencia.mes);
      expect(TipoRecorrencia.fromString('mes'), TipoRecorrencia.mes);
      expect(TipoRecorrencia.fromString('ano'), TipoRecorrencia.ano);
      expect(TipoRecorrencia.fromString(null), TipoRecorrencia.mes);
    });

    test('TransacaoModel equality and hashCode includes divisoes list', () {
      final t1 = TransacaoModel(
        id: 't1',
        descricao: 'Almoço',
        valor: 50.0,
        tipo: 'despesa',
        dataCompetencia: DateTime(2026, 8, 24),
        consolidada: true,
        divisoes: [
          DivisaoTransacaoModel(id: 'd1', transacaoId: 't1', contatoResponsavel: 'c1', peso: 50),
        ],
      );

      final t2 = TransacaoModel(
        id: 't1',
        descricao: 'Almoço',
        valor: 50.0,
        tipo: 'despesa',
        dataCompetencia: DateTime(2026, 8, 24),
        consolidada: true,
        divisoes: [
          DivisaoTransacaoModel(id: 'd1', transacaoId: 't1', contatoResponsavel: 'c1', peso: 50),
        ],
      );

      final t3 = TransacaoModel(
        id: 't1',
        descricao: 'Almoço',
        valor: 50.0,
        tipo: 'despesa',
        dataCompetencia: DateTime(2026, 8, 24),
        consolidada: true,
        divisoes: [
          DivisaoTransacaoModel(id: 'd2', transacaoId: 't1', contatoResponsavel: 'c2', peso: 100),
        ],
      );

      expect(t1, equals(t2));
      expect(t1.hashCode, equals(t2.hashCode));
      expect(t1, isNot(equals(t3)));
      expect(t1.tipoEnum, TipoTransacao.despesa);
    });

    test('TarefaHabitoModel helper getters for enum and negative habits', () {
      final positiveHabit = TarefaHabitoModel(
        id: 'h1',
        nome: 'Ler livro',
        tipo: 'habito',
        usuario: 'u1',
        concluida: false,
        agendamento: null,
        tarefasHabitosQtd: [
          TarefaHabitoQtdModel(
            id: 'q1',
            usuario: 'u1',
            valor: 1,
            metaVezes: 1,
            vezesPraticado: 0,
            reiniciaEmTipo: 'dia',
            reiniciaEmQtd: 1,
            createdAt: DateTime(2026, 8, 24),
          ),
        ],
      );

      expect(positiveHabit.tipoEnum, TipoItem.habito);
      expect(positiveHabit.isHabitoNegativo, isFalse);
      expect(positiveHabit.tipoHabitoEnum, TipoHabito.positivo);

      final negativeHabit = TarefaHabitoModel(
        id: 'h2',
        nome: 'Parar de fumar',
        tipo: 'habito',
        usuario: 'u1',
        concluida: false,
        agendamento: null,
        tarefasHabitosQtd: [
          TarefaHabitoQtdModel(
            id: 'q2',
            usuario: 'u1',
            valor: -1,
            metaVezes: 30,
            vezesPraticado: 5,
            reiniciaEmTipo: 'dia',
            reiniciaEmQtd: 1,
            createdAt: DateTime(2026, 8, 24),
          ),
        ],
      );

      expect(negativeHabit.isHabitoNegativo, isTrue);
      expect(negativeHabit.tipoHabitoEnum, TipoHabito.negativo);
    });
  });
}
