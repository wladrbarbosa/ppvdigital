import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppvdigital/models/local/app_database.dart';
import 'package:ppvdigital/models/tarefas_habitos_model.dart';
import 'package:ppvdigital/models/tarefas_habitos_qtd_model.dart';
import 'package:ppvdigital/repositories/drift_tarefa_habito_repository.dart';
import 'package:ppvdigital/repositories/tarefa_habito_repository.dart';

class MockRemoteTarefaHabitoRepo implements TarefaHabitoRepository {
  List<TarefaHabitoModel> items = [];

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
  group('Arquivado Tarefas e Hábitos Unit Tests', () {
    late AppDatabase database;
    late MockRemoteTarefaHabitoRepo remoteRepo;
    late DriftTarefaHabitoRepository driftRepo;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      remoteRepo = MockRemoteTarefaHabitoRepo();
      driftRepo = DriftTarefaHabitoRepository(
        database: database,
        remoteRepository: remoteRepo,
      );
    });

    tearDown(() async {
      await database.close();
    });

    test('TarefaHabitoModel serializes and deserializes arquivado field correctly', () {
      final model = TarefaHabitoModel(
        id: 't_archived',
        nome: 'Tarefa Arquivada',
        tipo: 'tarefa',
        usuario: 'user1',
        agendamento: null,
        concluida: false,
        arquivado: true,
        tarefasHabitosQtd: [
          TarefaHabitoQtdModel(
            id: 'q1',
            usuario: 'user1',
            metaVezes: 1,
            valor: 1.0,
            reiniciaEmQtd: 1,
            reiniciaEmTipo: 'dias',
            vezesPraticado: 0,
            createdAt: DateTime.now(),
          ),
        ],
      );

      final map = model.toMap();
      expect(map['arquivado'], isTrue);

      final fromMapModel = TarefaHabitoModel.fromMap(map);
      expect(fromMapModel.arquivado, isTrue);
      expect(fromMapModel.id, equals('t_archived'));

      final copied = fromMapModel.copyWith(arquivado: false);
      expect(copied.arquivado, isFalse);
    });

    test('DriftTarefaHabitoRepository persists and retrieves arquivado in SQLite', () async {
      final active = TarefaHabitoModel(
        id: 'item_active',
        nome: 'Item Ativo',
        tipo: 'habito',
        usuario: 'user1',
        agendamento: null,
        concluida: false,
        tarefasHabitosQtd: [],
      );

      final archived = TarefaHabitoModel(
        id: 'item_archived',
        nome: 'Item Arquivado',
        tipo: 'habito',
        usuario: 'user1',
        agendamento: null,
        concluida: false,
        arquivado: true,
        tarefasHabitosQtd: [],
      );

      await database.into(database.tarefaHabitos).insert(driftRepo.toCompanion(active));
      await database.into(database.tarefaHabitos).insert(driftRepo.toCompanion(archived));

      final allRows = await database.select(database.tarefaHabitos).get();
      expect(allRows.length, equals(2));

      final archivedRow = allRows.firstWhere((r) => r.remoteId == 'item_archived');
      expect(archivedRow.arquivado, isTrue);

      final activeRow = allRows.firstWhere((r) => r.remoteId == 'item_active');
      expect(activeRow.arquivado, isFalse);

      final domainList = await driftRepo.getTarefasEHabitos(
        usuarioId: 'user1',
        forceLocal: true,
      );

      expect(domainList.length, equals(2));
      final domainArchived = domainList.firstWhere((t) => t.id == 'item_archived');
      expect(domainArchived.arquivado, isTrue);
    });
  });
}
