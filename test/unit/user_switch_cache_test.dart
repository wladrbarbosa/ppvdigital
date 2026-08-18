import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppvdigital/app/capacitacao/financas/financas_controller.dart';
import 'package:ppvdigital/app/capacitacao/tarefas_habitos/calendario_controller.dart';
import 'package:ppvdigital/app/capacitacao/tarefas_habitos/categorias_controller.dart';
import 'package:ppvdigital/app/capacitacao/tarefas_habitos/historico_controller.dart';
import 'package:ppvdigital/app/capacitacao/tarefas_habitos/tarefas_habitos_controller.dart';
import 'package:ppvdigital/core.dart';
import 'package:ppvdigital/models/categoria_transacao_model.dart';
import 'package:ppvdigital/models/conta_model.dart';
import 'package:ppvdigital/models/contato_model.dart';
import 'package:ppvdigital/models/local/app_database.dart';
import 'package:ppvdigital/models/tarefas_habitos_model.dart';
import 'package:ppvdigital/models/transacao_model.dart';
import 'package:ppvdigital/repositories/drift_financas_repository.dart';
import 'package:ppvdigital/repositories/drift_tarefa_habito_repository.dart';
import 'package:ppvdigital/repositories/financas_repository.dart';
import 'package:ppvdigital/repositories/tarefa_habito_repository.dart';

class DummyRemoteFinancasRepo implements FinancasRepository {
  List<TransacaoModel> transacoes = [];
  List<ContaModel> contas = [];
  List<ContatoModel> contatos = [];
  List<CategoriaTransacaoModel> categorias = [];

  @override
  Future<List<ContaModel>> getContas({
    required String usuarioId,
    bool forceLocal = false,
    DateTime? lastSyncedAt,
  }) async {
    return contas.where((c) => c.userId == usuarioId).toList();
  }

  @override
  Future<List<ContatoModel>> getContatos({
    required String usuarioId,
    bool forceLocal = false,
    DateTime? lastSyncedAt,
  }) async {
    return contatos.where((c) => c.ownerId == usuarioId).toList();
  }

  @override
  Future<List<CategoriaTransacaoModel>> getCategorias({
    required String usuarioId,
    bool forceLocal = false,
    DateTime? lastSyncedAt,
  }) async {
    return categorias.where((c) => c.userId == usuarioId).toList();
  }

  @override
  Future<List<TransacaoModel>> getTransacoes({
    required String usuarioId,
    required List<String> contaIds,
    DateTime? targetMonth,
    DateTime? beforeDate,
    bool forceLocal = false,
    DateTime? lastSyncedAt,
  }) async {
    return transacoes;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class DummyRemoteTarefasRepo implements TarefaHabitoRepository {
  List<TarefaHabitoModel> tarefas = [];

  @override
  Future<List<TarefaHabitoModel>> getTarefasEHabitos({
    required String usuarioId,
    bool forceLocal = false,
    DateTime? lastSyncedAt,
  }) async {
    return tarefas.where((t) => t.usuario == usuarioId).toList();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (MethodCall methodCall) async => '.',
  );
  late AppDatabase db;
  late DummyRemoteFinancasRepo remoteFinancas;
  late DriftFinancasRepository driftFinancas;
  late FinancasController financasController;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    if (!Core.getIt.isRegistered<AppDatabase>()) {
      Core.getIt.registerSingleton<AppDatabase>(db);
    }
    remoteFinancas = DummyRemoteFinancasRepo();
    driftFinancas = DriftFinancasRepository(
      database: db,
      remoteRepository: remoteFinancas,
    );
    financasController = FinancasController(driftFinancas);
  });

  tearDown(() async {
    await Core.getIt.reset();
    await db.close();
  });

  group('User Switch & Cache Reset Tests', () {
    test('clearAllUserData clears all tables and settings from SQLite', () async {
      // 1. Seed user data into SQLite
      await db.setSetting('last_financas_sync_time', '2026-08-16T20:00:00Z');
      await db.setSetting('cached_user_json', r'{"$id":"user_a"}');
      await db.setSetting('synced_month_2026_8', '2026-08-16T20:00:00Z');

      await db.into(db.contas).insert(
            ContasCompanion.insert(
              remoteId: 'conta_1',
              name: 'Carteira User A',
              userId: 'user_a',
              saldoAtual: 100.0,
            ),
          );

      await db.into(db.tarefaHabitos).insert(
            TarefaHabitosCompanion.insert(
              remoteId: 'task_1',
              nome: 'Tarefa User A',
              tipo: 'tarefa',
              usuario: 'user_a',
              concluida: false,
              metas: [],
            ),
          );

      // Verify records exist
      expect(await db.getSetting('last_financas_sync_time'), isNotNull);
      expect((await db.select(db.contas).get()).length, 1);
      expect((await db.select(db.tarefaHabitos).get()).length, 1);

      // 2. Perform atomic clear
      await db.clearAllUserData();

      // 3. Verify everything is wiped clean
      expect(await db.getSetting('last_financas_sync_time'), isNull);
      expect(await db.getSetting('cached_user_json'), isNull);
      expect(await db.getSetting('synced_month_2026_8'), isNull);
      expect((await db.select(db.contas).get()).isEmpty, isTrue);
      expect((await db.select(db.tarefaHabitos).get()).isEmpty, isTrue);
      expect((await db.select(db.transacaos).get()).isEmpty, isTrue);
      expect((await db.select(db.contatos).get()).isEmpty, isTrue);
      expect((await db.select(db.categoriaTransacoes).get()).isEmpty, isTrue);
      expect((await db.select(db.historicoTarefasHabitos).get()).isEmpty, isTrue);
      expect((await db.select(db.appSettings).get()).isEmpty, isTrue);
    });

    test('FinancasController.reset() completely clears in-memory state and sync throttles', () {
      financasController.reset();

      expect(financasController.contasList.isEmpty, isTrue);
      expect(financasController.categoriasList.isEmpty, isTrue);
      expect(financasController.contatosList.isEmpty, isTrue);
      expect(financasController.transacoesList.isEmpty, isTrue);
      expect(financasController.divisoesList.isEmpty, isTrue);
      expect(financasController.isSyncing, isFalse);
      expect(financasController.cachedFilters, isNull);
      expect(FinancasController.financasFuture, isNull);
      expect(FinancasController.defaultDataCompetencia, isNull);
    });

    test('Tarefas, Historico, Calendario and Categorias controllers reset futures and lists', () {
      final remoteTarefas = DummyRemoteTarefasRepo();
      final driftTarefas = DriftTarefaHabitoRepository(
        database: db,
        remoteRepository: remoteTarefas,
      );
      final tarefasController = TarefasHabitosController(driftTarefas);
      final historicoController = HistoricoController();
      final calendarioController = CalendarioController();
      final categoriasController = CategoriasController();

      TarefasHabitosController.tarefasHabitosFuture = Future.value(<TarefaHabitoModel>[]);
      HistoricoController.historicoFuture = Future.value();
      CalendarioController.historicoFuture = Future.value();
      CategoriasController.categoriasFuture = Future.value();

      tarefasController.reset();
      historicoController.reset();
      calendarioController.reset();
      categoriasController.reset();

      expect(tarefasController.tarefasHabitosList.isEmpty, isTrue);
      expect(TarefasHabitosController.tarefasHabitosFuture, isNull);
      expect(HistoricoController.historicoFuture, isNull);
      expect(CalendarioController.historicoFuture, isNull);
      expect(CategoriasController.categoriasFuture, isNull);
    });
  });
}
