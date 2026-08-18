import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppvdigital/models/historico_item_model.dart';
import 'package:ppvdigital/models/local/app_database.dart';
import 'package:ppvdigital/models/tarefas_habitos_model.dart';
import 'package:ppvdigital/models/tarefas_habitos_qtd_model.dart';
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
      lastSyncedAt: DateTime(2026, 7),
    );

    // th_deleted should be reconciled and removed from SQLite
    localRows = await database.select(database.tarefaHabitos).get();
    expect(localRows.length, equals(1));
    expect(localRows.first.remoteId, equals('th_active'));
  });

  test('habit vezesPraticado calculates dynamically per daily cycle and resets on new day', () async {
    final habitMeta = TarefaHabitoQtdModel(
      id: 'meta1',
      metaVezes: 1,
      usuario: 'user1',
      valor: 1,
      reiniciaEmQtd: 1,
      reiniciaEmTipo: 'dias',
      vezesPraticado: 0,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    );

    final habit = TarefaHabitoModel(
      id: 'h1',
      nome: 'Beber Agua',
      tipo: 'habito',
      usuario: 'user1',
      concluida: false,
      agendamento: null,
      tarefasHabitosQtd: [habitMeta],
    );

    await database.into(database.tarefaHabitos).insert(driftRepository.toCompanion(habit));

    // 1. Record practice yesterday
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    await database.into(database.historicoTarefasHabitos).insert(
      HistoricoTarefasHabitosCompanion.insert(
        remoteId: 'hist_yesterday',
        usuario: 'user1',
        tarefaHabitoId: 'h1',
        createdAt: yesterday,
      ),
    );

    // 2. Fetch habits for Today: yesterday practice must NOT count for today's daily cycle
    var habits = await driftRepository.getTarefasEHabitos(
      usuarioId: 'user1',
      forceLocal: true,
    );
    expect(habits.first.tarefasHabitosQtd.first.vezesPraticado, equals(0));

    // 3. Record practice Today
    await database.into(database.historicoTarefasHabitos).insert(
      HistoricoTarefasHabitosCompanion.insert(
        remoteId: 'hist_today',
        usuario: 'user1',
        tarefaHabitoId: 'h1',
        createdAt: DateTime.now(),
      ),
    );

    // 4. Fetch habits for Today: today practice MUST count for today's daily cycle
    habits = await driftRepository.getTarefasEHabitos(
      usuarioId: 'user1',
      forceLocal: true,
    );
    expect(habits.first.tarefasHabitosQtd.first.vezesPraticado, equals(1));
  });

  test('watchHistorico stream emits reactive updates when new history is recorded', () async {
    final stream = driftRepository.watchHistorico(usuarioId: 'user1');

    final emissions = <List<HistoricoItemModel>>[];
    final sub = stream.listen(emissions.add);

    // Give stream time to emit initial empty list
    await pumpEventQueue();
    expect(emissions.length, equals(1));
    expect(emissions.first, isEmpty);

    // Insert a habit
    final habit = TarefaHabitoModel(
      id: 'h1',
      nome: 'Ler Livro',
      tipo: 'habito',
      usuario: 'user1',
      concluida: false,
      agendamento: null,
      tarefasHabitosQtd: [],
    );
    await database.into(database.tarefaHabitos).insert(driftRepository.toCompanion(habit));

    // Insert history item
    await database.into(database.historicoTarefasHabitos).insert(
      HistoricoTarefasHabitosCompanion.insert(
        remoteId: 'hist1',
        usuario: 'user1',
        tarefaHabitoId: 'h1',
        createdAt: DateTime.now(),
      ),
    );

    await pumpEventQueue();
    expect(emissions.length, greaterThanOrEqualTo(2));
    final lastEmission = emissions.last;
    expect(lastEmission.length, equals(1));
    expect(lastEmission.first.id, equals('hist1'));
    expect(lastEmission.first.tarefasEHabitos.nome, equals('Ler Livro'));

    await sub.cancel();
  });

  test('negative habit calculates abstinence streak from creation date and resets on relapse', () async {
    final creationDate = DateTime.now().subtract(const Duration(days: 5));
    final negativeHabitMeta = TarefaHabitoQtdModel(
      id: 'meta_neg',
      metaVezes: 30,
      usuario: 'user1',
      valor: -1,
      reiniciaEmQtd: 1,
      reiniciaEmTipo: 'dias',
      vezesPraticado: 0,
      createdAt: creationDate,
    );

    final negativeHabit = TarefaHabitoModel(
      id: 'h_neg',
      nome: 'Parar de Fumar',
      tipo: 'habito',
      usuario: 'user1',
      concluida: false,
      agendamento: null,
      tarefasHabitosQtd: [negativeHabitMeta],
    );

    await database.into(database.tarefaHabitos).insert(driftRepository.toCompanion(negativeHabit));

    // 1. Initial streak without any relapses (created 5 days ago => 5 days streak)
    var habits = await driftRepository.getTarefasEHabitos(
      usuarioId: 'user1',
      forceLocal: true,
    );
    expect(habits.first.tarefasHabitosQtd.first.valor, equals(-1));
    expect(habits.first.tarefasHabitosQtd.first.vezesPraticado, equals(5));

    // 2. Relapse occurred 2 days ago
    final relapseDate = DateTime.now().subtract(const Duration(days: 2));
    await database.into(database.historicoTarefasHabitos).insert(
      HistoricoTarefasHabitosCompanion.insert(
        remoteId: 'relapse1',
        usuario: 'user1',
        tarefaHabitoId: 'h_neg',
        createdAt: relapseDate,
      ),
    );

    // 3. Fetch habits: streak should now be 2 days (from 2 days ago to today)
    habits = await driftRepository.getTarefasEHabitos(
      usuarioId: 'user1',
      forceLocal: true,
    );
    expect(habits.first.tarefasHabitosQtd.first.vezesPraticado, equals(2));
  });

  test('upsert does not overwrite complete negative habit meta with default positive value', () async {
    final creationDate = DateTime.now().subtract(const Duration(days: 10));
    final localNegativeMeta = TarefaHabitoQtdModel(
      id: 'meta_neg_1',
      metaVezes: 30,
      usuario: 'user1',
      valor: -1,
      reiniciaEmQtd: 1,
      reiniciaEmTipo: 'dias',
      vezesPraticado: 0,
      createdAt: creationDate,
    );

    final localHabit = TarefaHabitoModel(
      id: 'h_neg_sync',
      nome: 'Parar de Roer Unhas',
      tipo: 'habito',
      usuario: 'user1',
      concluida: false,
      agendamento: null,
      tarefasHabitosQtd: [localNegativeMeta],
    );

    await database.into(database.tarefaHabitos).insert(driftRepository.toCompanion(localHabit));

    // Remote sync simulation where remote returns default/partial meta
    final remoteHabit = TarefaHabitoModel(
      id: 'h_neg_sync',
      nome: 'Parar de Roer Unhas',
      tipo: 'habito',
      usuario: 'user1',
      concluida: false,
      agendamento: null,
      tarefasHabitosQtd: [
        TarefaHabitoQtdModel(
          id: 'meta_neg_1',
          metaVezes: 30,
          usuario: 'user1',
          valor: 1.0, // remote sent default 1.0
          reiniciaEmQtd: 1,
          reiniciaEmTipo: 'dias',
          vezesPraticado: 0,
          createdAt: DateTime.now(),
        ),
      ],
    );
    remoteRepository.items = [remoteHabit];

    // Run incremental sync
    await driftRepository.getTarefasEHabitos(
      usuarioId: 'user1',
      lastSyncedAt: DateTime.now().subtract(const Duration(minutes: 5)),
    );

    final habits = await driftRepository.getTarefasEHabitos(
      usuarioId: 'user1',
      forceLocal: true,
    );
    // Preserved negative valor (-1) and original creation date (10 days streak)
    expect(habits.first.tarefasHabitosQtd.first.valor, equals(-1));
    expect(habits.first.tarefasHabitosQtd.first.vezesPraticado, equals(10));
  });
}
