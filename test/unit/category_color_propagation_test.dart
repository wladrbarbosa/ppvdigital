import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppvdigital/app/capacitacao/tarefas_habitos/categorias_controller.dart';
import 'package:ppvdigital/app/capacitacao/tarefas_habitos/dashboard_logic.dart';
import 'package:ppvdigital/app/capacitacao/tarefas_habitos/tarefas_habitos_controller.dart';
import 'package:ppvdigital/core.dart';
import 'package:ppvdigital/design_system/design_system.dart';
import 'package:ppvdigital/models/categorias_tarefas_habitos_model.dart';
import 'package:ppvdigital/models/local/app_database.dart';
import 'package:ppvdigital/models/tarefas_habitos_model.dart';
import 'package:ppvdigital/models/tarefas_habitos_qtd_model.dart';
import 'package:ppvdigital/repositories/drift_tarefa_habito_repository.dart';
import 'package:ppvdigital/repositories/tarefa_habito_repository.dart';

class MockRemoteRepo implements TarefaHabitoRepository {
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
  late MockRemoteRepo mockRemote;
  late DriftTarefaHabitoRepository driftRepo;
  late CategoriasController categoriasController;
  late TarefasHabitosController tarefasHabitosController;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    mockRemote = MockRemoteRepo();
    driftRepo = DriftTarefaHabitoRepository(
      database: db,
      remoteRepository: mockRemote,
    );
    categoriasController = CategoriasController();
    tarefasHabitosController = TarefasHabitosController(driftRepo);

    if (Core.getIt.isRegistered<AppDatabase>()) {
      Core.getIt.unregister<AppDatabase>();
    }
    Core.getIt.registerSingleton<AppDatabase>(db);

    if (Core.getIt.isRegistered<TarefaHabitoRepository>()) {
      Core.getIt.unregister<TarefaHabitoRepository>();
    }
    Core.getIt.registerSingleton<TarefaHabitoRepository>(driftRepo);

    if (Core.getIt.isRegistered<CategoriasController>()) {
      Core.getIt.unregister<CategoriasController>();
    }
    Core.getIt.registerSingleton<CategoriasController>(categoriasController);

    if (Core.getIt.isRegistered<TarefasHabitosController>()) {
      Core.getIt.unregister<TarefasHabitosController>();
    }
    Core.getIt.registerSingleton<TarefasHabitosController>(tarefasHabitosController);
  });

  tearDown(() async {
    await db.close();
  });

  test('updateCategoryInLoadedTasks updates color across loaded items in memory', () {
    final catOriginal = CategoriasTarefasHabitosModel(
      id: 'cat_1',
      nome: 'Saúde',
      cor: AppColors.customizablePastelColors[0],
      usuario: 'user1',
    );

    final item = TarefaHabitoModel(
      id: 'task_1',
      nome: 'Beber Água',
      tipo: 'habito',
      usuario: 'user1',
      concluida: false,
      agendamento: null,
      tarefasHabitosQtd: [
        TarefaHabitoQtdModel(
          id: 'qtd_1',
          metaVezes: 1,
          usuario: 'user1',
          categoriasTarefasHabitos: catOriginal,
          valor: 1,
          reiniciaEmQtd: 1,
          reiniciaEmTipo: 'dias',
          vezesPraticado: 0,
          createdAt: DateTime.now(),
        ),
      ],
    );

    tarefasHabitosController.tarefasHabitosList.add(item);
    expect(
      tarefasHabitosController.tarefasHabitosList.first.tarefasHabitosQtd.first.categoriasTarefasHabitos?.cor,
      equals(AppColors.customizablePastelColors[0]),
    );

    final catUpdated = catOriginal.copyWith(
      cor: AppColors.customizablePastelColors[5],
      nome: 'Saúde & Bem-Estar',
    );

    tarefasHabitosController.updateCategoryInLoadedTasks(catUpdated);

    final updatedTask = tarefasHabitosController.tarefasHabitosList.first;
    final updatedMeta = updatedTask.tarefasHabitosQtd.first.categoriasTarefasHabitos;
    expect(updatedMeta?.cor, equals(AppColors.customizablePastelColors[5]));
    expect(updatedMeta?.nome, equals('Saúde & Bem-Estar'));
  });

  test('updateCategoryInMetas updates SQLite metas persisted data', () async {
    final catOriginal = CategoriasTarefasHabitosModel(
      id: 'cat_work',
      nome: 'Trabalho',
      cor: const Color(0xFF112233),
      usuario: 'user1',
    );

    final item = TarefaHabitoModel(
      id: 'th_work_1',
      nome: 'Revisar PRs',
      tipo: 'tarefa',
      usuario: 'user1',
      concluida: false,
      agendamento: null,
      tarefasHabitosQtd: [
        TarefaHabitoQtdModel(
          id: 'qtd_work',
          metaVezes: 1,
          usuario: 'user1',
          categoriasTarefasHabitos: catOriginal,
          valor: 1,
          reiniciaEmQtd: 1,
          reiniciaEmTipo: 'dias',
          vezesPraticado: 0,
          createdAt: DateTime.now(),
        ),
      ],
    );

    // Seed task in SQLite
    await driftRepo.createTarefaHabito(
      id: item.id,
      nome: item.nome,
      tipo: item.tipo,
      metas: item.tarefasHabitosQtd.map((q) => q.toMap()).toList(),
      usuarioId: 'user1',
    );

    // Verify row in SQLite
    var rows = await db.select(db.tarefaHabitos).get();
    expect(rows.first.metas.first.categoriasTarefasHabitos?.cor, equals(const Color(0xFF112233)));

    // Update category
    final catUpdated = catOriginal.copyWith(
      cor: AppColors.customizablePastelColors[10],
      nome: 'Carreira e Trabalho',
    );
    await driftRepo.updateCategoryInMetas(catUpdated);

    // Verify row in SQLite has the new color and name
    rows = await db.select(db.tarefaHabitos).get();
    expect(rows.first.metas.first.categoriasTarefasHabitos?.cor, equals(AppColors.customizablePastelColors[10]));
    expect(rows.first.metas.first.categoriasTarefasHabitos?.nome, equals('Carreira e Trabalho'));
  });

  test('toDomain dynamically resolves live category from CategoriasController', () async {
    final catOriginal = CategoriasTarefasHabitosModel(
      id: 'cat_live',
      nome: 'Estudos',
      cor: const Color(0xFFAAAAAA),
      usuario: 'user1',
    );

    // Task stored in SQLite with old category color
    await driftRepo.createTarefaHabito(
      id: 'th_study',
      nome: 'Estudar Rust',
      tipo: 'habito',
      metas: [
        TarefaHabitoQtdModel(
          id: 'qtd_study',
          metaVezes: 1,
          usuario: 'user1',
          categoriasTarefasHabitos: catOriginal,
          valor: 1,
          reiniciaEmQtd: 1,
          reiniciaEmTipo: 'dias',
          vezesPraticado: 0,
          createdAt: DateTime.now(),
        ).toMap(),
      ],
      usuarioId: 'user1',
    );

    // Live controller has newer color
    final liveCat = catOriginal.copyWith(
      cor: AppColors.customizablePastelColors[7],
      nome: 'Estudos Avançados',
    );
    categoriasController.categoriasList.add(liveCat);

    final rows = await db.select(db.tarefaHabitos).get();
    final domainItem = driftRepo.toDomain(rows.first);

    expect(domainItem.tarefasHabitosQtd.first.categoriasTarefasHabitos?.cor, equals(AppColors.customizablePastelColors[7]));
    expect(domainItem.tarefasHabitosQtd.first.categoriasTarefasHabitos?.nome, equals('Estudos Avançados'));
  });

  test('removeCategoryFromLoadedTasks and removeCategoryFromMetas clear category correctly', () async {
    final cat = CategoriasTarefasHabitosModel(
      id: 'cat_del',
      nome: 'Temporário',
      cor: AppColors.customizablePastelColors[2],
      usuario: 'user1',
    );

    final item = TarefaHabitoModel(
      id: 'th_del',
      nome: 'Tarefa Temp',
      tipo: 'tarefa',
      usuario: 'user1',
      concluida: false,
      agendamento: null,
      tarefasHabitosQtd: [
        TarefaHabitoQtdModel(
          id: 'qtd_del',
          metaVezes: 1,
          usuario: 'user1',
          categoriasTarefasHabitos: cat,
          valor: 1,
          reiniciaEmQtd: 1,
          reiniciaEmTipo: 'dias',
          vezesPraticado: 0,
          createdAt: DateTime.now(),
        ),
      ],
    );

    tarefasHabitosController.tarefasHabitosList.add(item);
    await driftRepo.createTarefaHabito(
      id: item.id,
      nome: item.nome,
      tipo: item.tipo,
      metas: item.tarefasHabitosQtd.map((q) => q.toMap()).toList(),
      usuarioId: 'user1',
    );

    // Remove category
    tarefasHabitosController.removeCategoryFromLoadedTasks('cat_del');
    await driftRepo.removeCategoryFromMetas('cat_del');

    // Verify in-memory
    expect(
      tarefasHabitosController.tarefasHabitosList.first.tarefasHabitosQtd.first.categoriasTarefasHabitos,
      isNull,
    );

    // Verify in SQLite
    final rows = await db.select(db.tarefaHabitos).get();
    expect(rows.first.metas.first.categoriasTarefasHabitos, isNull);
  });

  test('DashboardLogic reflects updated category colors dynamically', () {
    final catOriginal = CategoriasTarefasHabitosModel(
      id: 'cat_dash',
      nome: 'Finanças',
      cor: const Color(0xFF123456),
      usuario: 'user1',
    );

    final item = TarefaHabitoModel(
      id: 'th_dash',
      nome: 'Organizar Finanças',
      tipo: 'habito',
      usuario: 'user1',
      concluida: false,
      agendamento: null,
      tarefasHabitosQtd: [
        TarefaHabitoQtdModel(
          id: 'qtd_dash',
          metaVezes: 1,
          usuario: 'user1',
          categoriasTarefasHabitos: catOriginal,
          valor: 1,
          reiniciaEmQtd: 1,
          reiniciaEmTipo: 'dias',
          vezesPraticado: 0,
          createdAt: DateTime.now(),
        ),
      ],
    );

    // Live category in controller has pastel color
    final liveCat = catOriginal.copyWith(cor: AppColors.customizablePastelColors[3]);
    categoriasController.categoriasList.add(liveCat);

    final attention = DashboardLogic.getCategoryAttentionDistribution([item]);
    expect(attention.length, equals(1));
    expect(attention.first.color, equals(AppColors.customizablePastelColors[3]));

    final progress = DashboardLogic.getCategoryProgress([item]);
    expect(progress.length, equals(1));
    expect(progress.first.color, equals(AppColors.customizablePastelColors[3]));
  });
}
