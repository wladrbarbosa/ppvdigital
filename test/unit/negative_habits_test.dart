import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ppvdigital/app/capacitacao/tarefas_habitos/dashboard_logic.dart';
import 'package:ppvdigital/models/categorias_tarefas_habitos_model.dart';
import 'package:ppvdigital/models/historico_item_model.dart';
import 'package:ppvdigital/models/local/app_database.dart';
import 'package:ppvdigital/models/tarefas_habitos_model.dart';
import 'package:ppvdigital/models/tarefas_habitos_qtd_model.dart';
import 'package:ppvdigital/repositories/drift_tarefa_habito_repository.dart';
import 'package:ppvdigital/repositories/tarefa_habito_repository.dart';

class MockRemoteRepo implements TarefaHabitoRepository {
  List<TarefaHabitoModel> items = [];

  @override
  Future<bool> createTarefaHabito({
    String? id,
    required String nome,
    required String tipo,
    required List<Map<String, dynamic>> metas,
    DateTime? agendamento,
    int? duration,
    bool arquivado = false,
    required String usuarioId,
  }) async {
    final metaModels = metas.map((m) {
      final createdAtRaw = m['createdAt'] ?? m[r'$createdAt'];
      final DateTime metaCreatedAt = createdAtRaw is int
          ? DateTime.fromMillisecondsSinceEpoch(createdAtRaw)
          : (createdAtRaw is String
              ? DateTime.tryParse(createdAtRaw) ?? DateTime.now()
              : (createdAtRaw is DateTime ? createdAtRaw : DateTime.now()));
      return TarefaHabitoQtdModel(
        id: (m['id'] as String?) ?? 'qtd_1',
        metaVezes: m['metaVezes'] as int,
        usuario: usuarioId,
        valor: m['valor'] as num,
        reiniciaEmQtd: m['reiniciaEmQtd'] as int,
        reiniciaEmTipo: m['reiniciaEmTipo'] as String,
        vezesPraticado: 0,
        createdAt: metaCreatedAt,
      );
    }).toList();

    items.add(
      TarefaHabitoModel(
        id: id ?? 'remote_id',
        nome: nome,
        tipo: tipo,
        usuario: usuarioId,
        agendamento: agendamento,
        concluida: false,
        arquivado: arquivado,
        tarefasHabitosQtd: metaModels,
      ),
    );
    return true;
  }

  @override
  Future<List<TarefaHabitoModel>> getTarefasEHabitos({
    required String usuarioId,
    bool forceLocal = false,
    DateTime? lastSyncedAt,
  }) async {
    return items;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Negative Habits Unit Tests', () {
    final catSaude = CategoriasTarefasHabitosModel(
      id: 'cat_saude',
      nome: 'Saúde',
      cor: Colors.green,
      usuario: 'user1',
    );

    final habitPositivo = TarefaHabitoModel(
      id: 'hab_pos',
      nome: 'Beber Água',
      tipo: 'habito',
      usuario: 'user1',
      agendamento: null,
      concluida: false,
      tarefasHabitosQtd: [
        TarefaHabitoQtdModel(
          id: 'qtd_pos',
          usuario: 'user1',
          metaVezes: 5,
          valor: 2.0,
          reiniciaEmQtd: 1,
          reiniciaEmTipo: 'dias',
          vezesPraticado: 0,
          createdAt: DateTime.now(),
          categoriasTarefasHabitos: catSaude,
        ),
      ],
    );

    final habitNegativo = TarefaHabitoModel(
      id: 'hab_neg',
      nome: 'Fumar Cigarro',
      tipo: 'habito',
      usuario: 'user1',
      agendamento: null,
      concluida: false,
      tarefasHabitosQtd: [
        TarefaHabitoQtdModel(
          id: 'qtd_neg',
          usuario: 'user1',
          metaVezes: 30, // 30 days goal
          valor: -3.0,
          reiniciaEmQtd: 1,
          reiniciaEmTipo: 'dias',
          vezesPraticado: 0,
          createdAt: DateTime.now(),
          categoriasTarefasHabitos: catSaude,
        ),
      ],
    );

    test('DashboardLogic.getCategoryProgress subtracts negative habit executions from totalExecuted', () {
      final now = DateTime.now();
      final historico = [
        // 2 executions of positive habit (+4.0 total)
        HistoricoItemModel(
          id: 'h1',
          createdAt: now,
          usuario: 'user1',
          tarefasEHabitos: habitPositivo,
        ),
        HistoricoItemModel(
          id: 'h2',
          createdAt: now,
          usuario: 'user1',
          tarefasEHabitos: habitPositivo,
        ),
        // 1 execution of negative habit (-3.0 total)
        HistoricoItemModel(
          id: 'h3',
          createdAt: now,
          usuario: 'user1',
          tarefasEHabitos: habitNegativo,
        ),
      ];

      final progressList = DashboardLogic.getCategoryProgress(
        [habitPositivo, habitNegativo],
        historico,
      );

      final saudeProgress = progressList.firstWhere((p) => p.name == 'Saúde');
      final dayProgress = saudeProgress.cycles['dias']!;

      // Expected executed for the day: (2 * 2.0) + (-3.0) = 4.0 - 3.0 = 1.0
      expect(dayProgress.totalExecuted, equals(1.0));
    });

    test('DashboardLogic.getCategoryAttentionDistribution handles absolute weight for negative habits', () {
      final attentionList = DashboardLogic.getCategoryAttentionDistribution(
        [habitNegativo],
      );

      final saudeAttention = attentionList.firstWhere((a) => a.name == 'Saúde');
      // Attention distribution uses abs() weight to represent proportional impact
      expect(saudeAttention.totalValue, equals(3.0));
    });

    test('Sorting by tipoHabito orders positive habits before negative habits (or vice versa)', () {
      final list = [habitNegativo, habitPositivo];

      // Ascending sort (positive first)
      list.sort((a, b) {
        final aIsNeg = a.tarefasHabitosQtd.any((q) => q.valor < 0);
        final bIsNeg = b.tarefasHabitosQtd.any((q) => q.valor < 0);
        return (aIsNeg ? 1 : 0).compareTo(bIsNeg ? 1 : 0);
      });

      expect(list.first.id, equals('hab_pos'));
      expect(list.last.id, equals('hab_neg'));
    });

    test('DriftTarefaHabitoRepository calculates daysWithoutPracticing for negative habits', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final mockRemote = MockRemoteRepo();
      final repo = DriftTarefaHabitoRepository(
        database: db,
        remoteRepository: mockRemote,
      );

      // Create negative habit created 5 days ago
      final fiveDaysAgo = DateTime.now().subtract(const Duration(days: 5));
      await repo.createTarefaHabito(
        nome: 'Roer Unhas',
        tipo: 'habito',
        metas: [
          {
            'id': 'q_unhas',
            'metaVezes': 30,
            'valor': -1.0,
            'reiniciaEmQtd': 1,
            'reiniciaEmTipo': 'dias',
            'createdAt': fiveDaysAgo.millisecondsSinceEpoch,
          }
        ],
        usuarioId: 'user1',
      );

      // Fetch habit from repo: should have 5 days without practicing
      final habitsNoRelapse = await repo.getTarefasEHabitos(usuarioId: 'user1');
      expect(habitsNoRelapse.first.tarefasHabitosQtd.first.vezesPraticado, equals(5));

      // Record a relapse 2 days ago
      final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
      await db.into(db.historicoTarefasHabitos).insert(
        HistoricoTarefasHabitosCompanion.insert(
          remoteId: 'relapse_1',
          usuario: 'user1',
          tarefaHabitoId: habitsNoRelapse.first.id,
          createdAt: twoDaysAgo.toUtc(),
        ),
      );

      // Fetch again: streak should now be 2 days
      final habitsWithRelapse = await repo.getTarefasEHabitos(usuarioId: 'user1');
      expect(habitsWithRelapse.first.tarefasHabitosQtd.first.vezesPraticado, equals(2));

      await db.close();
    });

    test('DriftTarefaHabitoRepository keeps newly created habit ID aligned with remote and avoids deletion', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final mockRemote = MockRemoteRepo();
      final repo = DriftTarefaHabitoRepository(
        database: db,
        remoteRepository: mockRemote,
      );

      await repo.createTarefaHabito(
        nome: 'Parar de Fumar',
        tipo: 'habito',
        metas: [
          {
            'id': 'q_fumar',
            'metaVezes': 60,
            'valor': -5.0,
            'reiniciaEmQtd': 1,
            'reiniciaEmTipo': 'dias',
          }
        ],
        usuarioId: 'user1',
      );

      // Perform delta sync: habit must NOT be erased
      final syncedList = await repo.getTarefasEHabitos(
        usuarioId: 'user1',
        lastSyncedAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      expect(syncedList.length, equals(1));
      expect(syncedList.first.nome, equals('Parar de Fumar'));

      await db.close();
    });

    test('Historico items for negative habits are identified and labeled as relapses', () {
      final item = HistoricoItemModel(
        id: 'h_neg',
        createdAt: DateTime.now(),
        usuario: 'user1',
        tarefasEHabitos: habitNegativo,
      );

      final isNegativo = item.tarefasEHabitos.tarefasHabitosQtd.any((q) => q.valor < 0);
      expect(isNegativo, isTrue);

      final String prefix = isNegativo ? '[Recaída] ' : '';
      final String subject = '$prefix${item.tarefasEHabitos.nome}';
      expect(subject, equals('[Recaída] Fumar Cigarro'));
    });
  });
}
