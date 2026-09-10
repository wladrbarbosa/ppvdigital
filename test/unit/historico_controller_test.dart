import 'package:appwrite/models.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppvdigital/app/capacitacao/tarefas_habitos/historico_controller.dart';
import 'package:ppvdigital/app/capacitacao/tarefas_habitos/tarefas_habitos_controller.dart';
import 'package:ppvdigital/app/login/login_controller.dart';
import 'package:ppvdigital/core.dart';
import 'package:ppvdigital/models/historico_item_model.dart';
import 'package:ppvdigital/models/tarefas_habitos_model.dart';
import 'package:ppvdigital/repositories/tarefa_habito_repository.dart';

class MockTarefaHabitoRepository implements TarefaHabitoRepository {
  String? lastUpdatedId;
  DateTime? lastUpdatedDate;
  bool shouldSucceed = true;
  List<HistoricoItemModel> items = [];

  @override
  Future<List<HistoricoItemModel>> getHistorico({
    required String usuarioId,
    bool forceLocal = false,
    DateTime? lastSyncedAt,
  }) async {
    return items;
  }

  @override
  Stream<List<HistoricoItemModel>> watchHistorico({required String usuarioId}) {
    return Stream.value(items);
  }

  @override
  Future<bool> updateHistoricoItemDate({
    required String id,
    required DateTime newDate,
  }) async {
    lastUpdatedId = id;
    lastUpdatedDate = newDate;
    if (shouldSucceed) {
      final index = items.indexWhere((h) => h.id == id);
      if (index != -1) {
        items[index] = items[index].copyWith(createdAt: newDate);
      }
    }
    return shouldSucceed;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockTarefasHabitosController implements TarefasHabitosController {
  bool loadDocumentsCalled = false;

  @override
  List<TarefaHabitoModel> get tarefasHabitosList => [];

  @override
  Future<List<TarefaHabitoModel>> loadDocuments({bool forceSync = false}) async {
    loadDocumentsCalled = true;
    return [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockLoginController implements LoginController {
  @override
  User? get currentUser => User.fromMap({
        r'$id': 'user_1',
        'name': 'User 1',
        'email': 'user1@test.com',
        'phone': '',
        'status': true,
        'labels': [],
        'passwordUpdate': '',
        'emailVerification': true,
        'phoneVerification': false,
        'mfa': false,
        'prefs': <String, dynamic>{},
        'targets': [],
        'accessedAt': '',
        r'$createdAt': '',
        r'$updatedAt': '',
      });

  @override
  Future<void> loadUser() async {}

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

  late MockTarefaHabitoRepository mockRepo;
  late MockTarefasHabitosController mockTarefasHabitosController;
  late MockLoginController mockLoginController;
  late HistoricoController controller;

  setUp(() {
    mockRepo = MockTarefaHabitoRepository();
    mockTarefasHabitosController = MockTarefasHabitosController();
    mockLoginController = MockLoginController();

    if (Core.getIt.isRegistered<TarefaHabitoRepository>()) {
      Core.getIt.unregister<TarefaHabitoRepository>();
    }
    Core.getIt.registerSingleton<TarefaHabitoRepository>(mockRepo);

    if (Core.getIt.isRegistered<TarefasHabitosController>()) {
      Core.getIt.unregister<TarefasHabitosController>();
    }
    Core.getIt.registerSingleton<TarefasHabitosController>(
      mockTarefasHabitosController,
    );

    if (Core.getIt.isRegistered<LoginController>()) {
      Core.getIt.unregister<LoginController>();
    }
    Core.getIt.registerSingleton<LoginController>(mockLoginController);

    controller = HistoricoController();
  });

  tearDown(() {
    controller.reset();
  });

  test('updateHistoricoDate calls repository and updates local list on success', () async {
    final originalDate = DateTime(2026, 9, 10, 8);
    final targetDate = DateTime(2026, 9, 12, 14, 30);

    final item = HistoricoItemModel(
      id: 'hist_123',
      usuario: 'user_1',
      tarefasEHabitos: TarefaHabitoModel(
        id: 't_1',
        nome: 'Exercício',
        tipo: 'habito',
        usuario: 'user_1',
        concluida: false,
        agendamento: null,
        tarefasHabitosQtd: [],
      ),
      createdAt: originalDate,
    );

    mockRepo.items = [item];
    await controller.loadDocuments();

    expect(controller.historicoList.length, 1);
    expect(controller.historicoList.first.createdAt, originalDate);

    final success = await controller.updateHistoricoDate('hist_123', targetDate);

    expect(success, isTrue);
    expect(mockRepo.lastUpdatedId, 'hist_123');
    expect(mockRepo.lastUpdatedDate, targetDate);
    expect(mockTarefasHabitosController.loadDocumentsCalled, isTrue);
    expect(controller.historicoList.first.createdAt, targetDate);
  });

  test('updateHistoricoDate returns false when repository fails', () async {
    mockRepo.shouldSucceed = false;
    final targetDate = DateTime(2026, 9, 12, 14, 30);

    final success = await controller.updateHistoricoDate('hist_fail', targetDate);

    expect(success, isFalse);
    expect(mockRepo.lastUpdatedId, 'hist_fail');
  });
}
