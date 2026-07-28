import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppvdigital/models/local/app_database.dart';
import 'package:ppvdigital/models/tarefas_habitos_model.dart';
import 'package:ppvdigital/repositories/drift_tarefa_habito_repository.dart';
import 'package:ppvdigital/repositories/tarefa_habito_repository.dart';

class MockRemoteTarefaHabitoRepository implements TarefaHabitoRepository {
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
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase database;
  late MockRemoteTarefaHabitoRepository remoteRepository;
  late DriftTarefaHabitoRepository driftRepository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    remoteRepository = MockRemoteTarefaHabitoRepository();
    driftRepository = DriftTarefaHabitoRepository(
      database: database,
      remoteRepository: remoteRepository,
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('handleRealtimeEvent deletes and upserts local Tarefas/Habitos correctly', () async {
    // 1. Create via Realtime
    await driftRepository.handleRealtimeEvent(
      tableId: '671f864f0023d1c27de8',
      action: 'create',
      payload: {
        '\$id': 'th1',
        'nome': 'Estudar Flutter',
        'tipo': 'tarefa',
        'usuario': 'user1',
        'concluida': false,
        'metas': [],
      },
    );

    var rows = await database.select(database.tarefaHabitos).get();
    expect(rows.length, equals(1));
    expect(rows.first.remoteId, equals('th1'));
    expect(rows.first.nome, equals('Estudar Flutter'));

    // 2. Update via Realtime
    await driftRepository.handleRealtimeEvent(
      tableId: '671f864f0023d1c27de8',
      action: 'update',
      payload: {
        '\$id': 'th1',
        'nome': 'Estudar Flutter Advanced',
        'tipo': 'tarefa',
        'usuario': 'user1',
        'concluida': true,
        'metas': [],
      },
    );

    rows = await database.select(database.tarefaHabitos).get();
    expect(rows.length, equals(1));
    expect(rows.first.nome, equals('Estudar Flutter Advanced'));
    expect(rows.first.concluida, isTrue);

    // 3. Delete via Realtime
    await driftRepository.handleRealtimeEvent(
      tableId: '671f864f0023d1c27de8',
      action: 'delete',
      payload: {'\$id': 'th1'},
    );

    rows = await database.select(database.tarefaHabitos).get();
    expect(rows, isEmpty);
  });

  test('getTarefasEHabitos reconciles deleted remote items when lastSyncedAt is provided', () async {
    final item1 = TarefaHabitoModel(
      id: 'th_active',
      nome: 'Active Task',
      tipo: 'tarefa',
      usuario: 'user1',
      concluida: false,
      agendamento: null,
      tarefasHabitosQtd: [],
    );
    final item2 = TarefaHabitoModel(
      id: 'th_deleted',
      nome: 'Deleted Task',
      tipo: 'tarefa',
      usuario: 'user1',
      concluida: false,
      agendamento: null,
      tarefasHabitosQtd: [],
    );

    // Initial state in SQLite: both item1 and item2 exist
    await database.into(database.tarefaHabitos).insert(driftRepository.toCompanion(item1));
    await database.into(database.tarefaHabitos).insert(driftRepository.toCompanion(item2));

    var localRows = await database.select(database.tarefaHabitos).get();
    expect(localRows.length, equals(2));

    // Remote database only has item1 left (item2 was deleted on remote)
    remoteRepository.items = [item1];

    // Incremental sync
    await driftRepository.getTarefasEHabitos(
      usuarioId: 'user1',
      lastSyncedAt: DateTime(2026, 7, 1),
    );

    // th_deleted should be reconciled and removed from SQLite
    localRows = await database.select(database.tarefaHabitos).get();
    expect(localRows.length, equals(1));
    expect(localRows.first.remoteId, equals('th_active'));
  });
}
